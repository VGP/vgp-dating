#!/bin/bash

# Benchmark treePL optimization settings without touching production outputs.
#
# Usage:
#   ./treepl_parameter_benchmark.sh CONFIG TREE full [fast|thorough] [fixed|random]
#   ./treepl_parameter_benchmark.sh CONFIG TREE SMOOTHING [pl|cv|all] [fast|thorough] [fixed|random]
#
# Example:
#   ./treepl_parameter_benchmark.sh \
#     roadies_v1.1.16b/roadies_v1.1.16b_wrapper.config \
#     ../trees/roadies_v1.1.16b.nwk \
#     full \
#     fast \
#     fixed
#
# Results are written directly to:
#   <configuration directory>/generated/treepl_parameter_benchmark/
#
# Edit the search controls below if a smaller or larger experiment is desired.

if [ "$#" -lt 3 ] || [ "$#" -gt 6 ]
then
	echo "Usage:"
	echo "  $0 CONFIG TREE full [fast|thorough] [fixed|random]"
	echo "  $0 CONFIG TREE SMOOTHING [pl|cv|all] [fast|thorough] [fixed|random]"
	exit 1
fi

configuration_input=$1
tree_input=$2
analysis_argument=$3
seed_mode="fixed"
workflow_profile="fast"
benchmark_mode="all"

if [ "$analysis_argument" = "full" ]
then
	benchmark_mode="full"
	# Used only for the initial optimizer-convergence stage. Full mode later
	# optimizes smoothing by CV and repeats PL convergence at that value.
	fixed_smoothing=1
else
	fixed_smoothing=$analysis_argument
fi

shift 3
for option in "$@"
do
	case "$option" in
		pl|cv|all)
			if [ "$analysis_argument" = "full" ]
			then
				echo "Error: pl, cv, and all cannot be combined with full"
				exit 1
			fi
			benchmark_mode=$option
			;;
		fast|thorough)
			workflow_profile=$option
			;;
		fixed|random)
			seed_mode=$option
			;;
		*)
			echo "Error: unrecognized option: $option"
			exit 1
			;;
	esac
done

if [ ! -f "$configuration_input" ] || [ ! -f "$tree_input" ]
then
	echo "Error: configuration or tree file not found"
	exit 2
fi

case "$benchmark_mode" in
	pl|cv|all|full)
		;;
	*)
		echo "Error: mode must be pl, cv, all, or full"
		exit 3
		;;
esac

configuration_file="$(cd "$(dirname "$configuration_input")" && pwd)/$(basename "$configuration_input")"
tree_file="$(cd "$(dirname "$tree_input")" && pwd)/$(basename "$tree_input")"
configuration_directory="$(dirname "$configuration_file")"

benchmark_root="$configuration_directory/generated/treepl_parameter_benchmark"
run_directory="$benchmark_root"
work_directory="$run_directory/.work"

# Use reproducible fixed seeds by default. Random mode generates and records
# three fresh independent seeds when the script starts.
case "$seed_mode" in
	fixed)
		seeds=(1729 2718 3141)
		;;
	random)
		seeds=()
		while [ "${#seeds[@]}" -lt 3 ]
		do
			candidate_seed=$(od -An -N4 -tu4 /dev/urandom | tr -d '[:space:]')
			candidate_seed=$((candidate_seed % 2147483646 + 1))
			seed_already_used=0
			for existing_seed in "${seeds[@]}"
			do
				if [ "$candidate_seed" -eq "$existing_seed" ]
				then
					seed_already_used=1
				fi
			done
			if [ "$seed_already_used" -eq 0 ]
			then
				seeds+=("$candidate_seed")
			fi
		done
		;;
	*)
		echo "Error: seed mode must be fixed or random"
		exit 4
		;;
esac

# Adaptive penalized-likelihood convergence search.
# Earlier testing showed that plsimaniter values of 5000, 15000, and 30000
# produced identical objectives and trees. Hold it at 5000 and increase
# pliter until the worst seed changes by no more than 0.1% for two consecutive
# steps. The recommendation adds a 20% buffer and rounds up to the next 10.
pl_simaniter=5000
pl_siman_candidates=(5000 15000 30000)
pl_siman_equivalence_percent=0.01
pl_start=2
pl_step=10
pl_max=500
pl_scout_threshold_percent=1
pl_scout_min_pliter=16
pl_scout_consecutive_steps=2
pl_convergence_percent=0.1
pl_consecutive_steps=2
pl_buffer_percent=20
pl_rounding=10

# Cross-validation candidates used only by thorough mode. Fast mode uses one
# broad pilot, the empirically supported minimum settings, and one refined CV.
# A second seed is added only when the refined winner is within 5% of the
# runner-up; a third is added only when the first two seeds disagree.
cv_iterations=(3 5 10)
cv_siman_iterations=(5000 7500 15000)
fast_cviter=3
fast_cvsimaniter=5000
fine_refinement_threshold_percent=5
random_cv_pliter_default=20
random_cv_pliter_min=10
random_cv_pliter_max=50
cv_start=10000
cv_stop=0.00001

# Optimizers selected by the production prime workflow.
opt=5
optad=5
optcvad=3

# Prime trials are independent, but treePL also contains internal OpenMP work.
# Override at launch with PRIME_JOBS=N after checking available CPU capacity.
prime_jobs=${PRIME_JOBS:-2}
prime_min_trials=40
prime_max_trials=200
prime_checkpoint_interval=10
prime_min_mode_percent=25
prime_min_margin_percent=10
prime_stable_checkpoints=3

case "$prime_jobs" in
	''|*[!0-9]*)
		echo "Error: PRIME_JOBS must be a positive integer"
		exit 4
		;;
	0)
		echo "Error: PRIME_JOBS must be at least 1"
		exit 4
		;;
esac

mkdir -p "$run_directory"
if [ -e "$work_directory" ]
then
	echo "Error: $work_directory already exists; another benchmark may be active or a previous run may not have cleaned up"
	exit 5
fi
mkdir "$work_directory"

# Direct output filenames are reused deliberately. Remove only files owned by
# this script so an interrupted rerun cannot leave stale later-stage results.
owned_output_files=(
	benchmark_seeds.txt
	prime_recommendation.txt
	plsiman_summary.tsv
	plsiman_recommendation.txt
	pl_summary.tsv
	pl_convergence.tsv
	pl_recommendation.txt
	initial_pl_summary.tsv
	initial_pl_convergence.tsv
	initial_pl_recommendation.txt
	cv_summary.tsv
	cv_recommendation.txt
	full_cv_summary.tsv
	full_cv_scores.tsv
	fine_cv_summary.tsv
	final_recommendation.txt
	final_pl_summary.tsv
	final_pl_convergence.tsv
	final_pl_recommendation.txt
)
for owned_output_file in "${owned_output_files[@]}"
do
	rm -f -- "$run_directory/$owned_output_file"
done

active_pid=""
prime_pids=()

status_update() {
	printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

stop_active_process() {
	if [ -n "$active_pid" ]
	then
		status_update "Stopping active treePL process (PID $active_pid)."
		kill "$active_pid" 2>/dev/null
	fi

	for prime_pid in "${prime_pids[@]}"
	do
		if [ -n "$prime_pid" ]
		then
			status_update "Stopping active prime treePL process (PID $prime_pid)."
			kill "$prime_pid" 2>/dev/null
		fi
	done
}

cleanup_work_directory() {
	if [ -n "$work_directory" ] && [ -d "$work_directory" ]
	then
		rm -rf -- "$work_directory"
	fi
}

stop_and_cleanup() {
	stop_active_process
	cleanup_work_directory
}

stop_active_process_and_exit() {
	stop_and_cleanup
	exit 130
}

trap stop_active_process_and_exit INT TERM
trap stop_and_cleanup EXIT

write_base_configuration() {
	destination=$1

	awk '
		/^[[:space:]]*#/ {print; next}
		/^[[:space:]]*(treefile|seed|outfile|smooth|opt|optad|optcvad|pliter|plsimaniter|cviter|cvsimaniter|cvstart|cvstop|cvmultstep|cvoutfile|randomcviter|randomcvsamp)[[:space:]]*=/ {next}
		/^[[:space:]]*(thorough|prime|cv|randomcv)[[:space:]]*$/ {next}
		{print}
	' "$configuration_file" > "$destination"
}

write_common_configuration() {
	destination=$1

	write_base_configuration "$destination"
	{
		echo "treefile = $tree_file"
		echo "thorough"
		echo "opt = $opt"
		echo "optad = $optad"
		echo "optcvad = $optcvad"
	} >> "$destination"
}

cv_value_is_present() {
	result_file=$1
	target=$2

	awk -v target="$target" '
		$1 == "chisq:" {
			value = $2
			gsub(/[()]/, "", value)
			if ((value + 0) == (target + 0)) {
				found = 1
			}
		}
		END { exit(found ? 0 : 1) }
	' "$result_file"
}

extract_best_cv_result() {
	result_file=$1

	awk '
		$1 == "chisq:" {
			smoothing = $2
			gsub(/[()]/, "", smoothing)
			score = $3 + 0
			if (!found || score < best_score) {
				best_score = score
				best_smoothing = smoothing
				found = 1
			}
		}
		END {
			if (found) {
				printf "%s\t%.17g\n", best_smoothing, best_score
			}
		}
	' "$result_file"
}

extract_cv_score_for_value() {
	result_file=$1
	target_value=$2

	awk -v target="$target_value" '
		$1 == "chisq:" {
			value = $2
			gsub(/[()]/, "", value)
			difference = value - target
			if (difference < 0) difference = -difference
			tolerance = target
			if (tolerance < 0) tolerance = -tolerance
			tolerance = tolerance * 0.00001 + 1e-12
			if (difference <= tolerance) score = $3
		}
		END {if(score != "") print score}
	' "$result_file"
}

run_targeted_cv_case() {
	target_stage=$1
	target_seed=$2
	target_start=$3
	target_stop=$4
	target_step=$5
	target_score_count=$6

	target_case_name="${target_stage}_seed-${target_seed}"
	target_case_directory="$work_directory/fine_cv/$target_case_name"
	mkdir -p "$target_case_directory"
	target_config_name="$target_case_name.config"
	target_log_name="$target_case_name.log"
	target_results_name="$target_case_name.results.tsv"
	target_config_path="$target_case_directory/$target_config_name"
	target_log_path="$target_case_directory/$target_log_name"
	target_results_path="$target_case_directory/$target_results_name"

	write_common_configuration "$target_config_path"
	{
		echo "seed = $target_seed"
		if [ -n "$recommended_pliter" ] && [ "$recommended_pliter" != "not_determined" ]
		then
			echo "pliter = $recommended_pliter"
		fi
		if [ -n "$recommended_plsimaniter" ]
		then
			echo "plsimaniter = $recommended_plsimaniter"
		fi
		echo "cv"
		echo "cvoutfile = $target_results_name"
		echo "cvstart = $target_start"
		echo "cvstop = $target_stop"
		echo "cvmultstep = $target_step"
		echo "cviter = $recommended_cviter"
		echo "cvsimaniter = $recommended_cvsimaniter"
	} >> "$target_config_path"

	: > "$target_results_path"
	status_update "Adaptive CV $target_stage starting: seed=$target_seed, range=$target_start to $target_stop, expected scores=$target_score_count."
	target_start_time=$(date +%s)
	(
		cd "$target_case_directory" || exit 1
		exec treePL "$target_config_name"
	) > "$target_log_path" 2>&1 &
	active_pid=$!

	while true
	do
		target_completed_count=$(awk '$1 == "chisq:" {count++} END {print count + 0}' "$target_results_path")
		if [ "$target_completed_count" -ge "$target_score_count" ]
		then
			kill "$active_pid" 2>/dev/null
			wait "$active_pid" 2>/dev/null
			break
		fi
		if ! kill -0 "$active_pid" 2>/dev/null
		then
			wait "$active_pid" 2>/dev/null
			break
		fi
		sleep 1
	done

	active_pid=""
	target_end_time=$(date +%s)
	target_runtime_seconds=$((target_end_time - target_start_time))
	target_completed_count=$(awk '$1 == "chisq:" {count++} END {print count + 0}' "$target_results_path")
	if [ "$target_completed_count" -ge "$target_score_count" ]
	then
		target_status="complete"
	else
		target_status="incomplete"
	fi
	status_update "Adaptive CV $target_stage $target_status: seed=$target_seed, runtime=${target_runtime_seconds}s, scores=$target_completed_count/$target_score_count."
}

run_prime_selection() {
	prime_directory="$work_directory/prime"
	prime_config="$prime_directory/prime.config"
	prime_results="$prime_directory/prime_results.tsv"
	prime_summary="$run_directory/prime_recommendation.txt"
	mkdir -p "$prime_directory"
	: > "$prime_results"

	write_base_configuration "$prime_config"
	{
		echo "treefile = $tree_file"
		echo "thorough"
		echo "prime"
	} >> "$prime_config"

	status_update "Starting adaptive prime selection with up to $prime_jobs concurrent processes; minimum=$prime_min_trials, maximum=$prime_max_trials."
	prime_number=1
	completed_prime_count=0
	prime_mode_streak=0
	previous_prime_mode=""
	prime_stopped_early="no"

	while [ "$prime_number" -le "$prime_max_trials" ]
	do
		prime_pids=()
		prime_logs=()
		prime_numbers=()
		prime_slot=0

		while [ "$prime_slot" -lt "$prime_jobs" ] && [ "$prime_number" -le "$prime_max_trials" ]
		do
			prime_log="$prime_directory/prime_${prime_number}.log"
			(
				cd "$prime_directory" || exit 1
				exec treePL "$(basename "$prime_config")"
			) > "$prime_log" 2>&1 &

			prime_pids[$prime_slot]=$!
			prime_logs[$prime_slot]=$prime_log
			prime_numbers[$prime_slot]=$prime_number
			status_update "Prime trial $prime_number/$prime_max_trials started (PID ${prime_pids[$prime_slot]})."

			prime_slot=$((prime_slot + 1))
			prime_number=$((prime_number + 1))
		done

		prime_slot=0
		while [ "$prime_slot" -lt "${#prime_pids[@]}" ]
		do
			prime_pid=${prime_pids[$prime_slot]}
			prime_log=${prime_logs[$prime_slot]}
			completed_prime_number=${prime_numbers[$prime_slot]}

			if wait "$prime_pid"
			then
				sed -n '/^opt/,$p' "$prime_log" |\
				sed 's/.*\(.\)/\1/' |\
				tr '\n' ' ' >> "$prime_results"
				echo >> "$prime_results"
				completed_prime_count=$((completed_prime_count + 1))
			else
				status_update "ERROR: prime trial $completed_prime_number failed; see $prime_log."
			fi

			prime_slot=$((prime_slot + 1))
		done

		prime_pids=()
		status_update "Prime progress: $completed_prime_count successful trials; $((prime_number - 1))/$prime_max_trials launched."

		if [ "$completed_prime_count" -ge "$prime_min_trials" ] && \
		   [ $((completed_prime_count % prime_checkpoint_interval)) -eq 0 ]
		then
			prime_ranking=$(sort "$prime_results" | uniq -c | sort -nr | sed -n '1,2p')
			leading_count=$(printf "%s\n" "$prime_ranking" | sed -n '1p' | awk '{print $1}')
			leading_mode=$(printf "%s\n" "$prime_ranking" | sed -n '1p' | sed 's/^[[:space:]]*[0-9][0-9]*[[:space:]]*//')
			runner_up_count=$(printf "%s\n" "$prime_ranking" | sed -n '2p' | awk '{print $1}')
			runner_up_count=${runner_up_count:-0}
			leading_percent=$(awk -v count="$leading_count" -v total="$completed_prime_count" 'BEGIN {printf "%.2f", 100 * count / total}')
			margin_percent=$(awk -v lead="$leading_count" -v runner="$runner_up_count" -v total="$completed_prime_count" 'BEGIN {printf "%.2f", 100 * (lead - runner) / total}')

			if [ "$leading_mode" = "$previous_prime_mode" ]
			then
				prime_mode_streak=$((prime_mode_streak + 1))
			else
				prime_mode_streak=1
				previous_prime_mode=$leading_mode
			fi

			status_update "Prime checkpoint: leader='$leading_mode', share=${leading_percent}%, margin=${margin_percent}%, stable checkpoints=$prime_mode_streak/$prime_stable_checkpoints."

			prime_dominates=$(awk \
				-v share="$leading_percent" \
				-v margin="$margin_percent" \
				-v minimum_share="$prime_min_mode_percent" \
				-v minimum_margin="$prime_min_margin_percent" \
				'BEGIN {print(share >= minimum_share && margin >= minimum_margin ? 1 : 0)}')

			if [ "$prime_dominates" -eq 1 ] && [ "$prime_mode_streak" -ge "$prime_stable_checkpoints" ]
			then
				prime_stopped_early="yes"
				status_update "Prime plurality criterion satisfied after $completed_prime_count trials; stopping early."
				break
			fi
		fi
	done

	if [ "$completed_prime_count" -lt "$prime_min_trials" ]
	then
		status_update "ERROR: only $completed_prime_count prime trials completed successfully; at least $prime_min_trials are required."
		return 1
	fi

	modal_prime=$(sort "$prime_results" | uniq -c | sort -nr | sed -n '1p' | sed 's/^[[:space:]]*[0-9][0-9]*[[:space:]]*//')
	opt=$(printf "%s\n" "$modal_prime" | awk '{print $1}')
	optad=$(printf "%s\n" "$modal_prime" | awk '{print $2}')
	optcvad=$(printf "%s\n" "$modal_prime" | awk '{print $3}')

	if [ -z "$opt" ] || [ -z "$optad" ] || [ -z "$optcvad" ]
	then
		status_update "ERROR: prime trials did not yield a usable optimizer recommendation."
		return 1
	fi

	{
		echo "trials=$completed_prime_count"
		echo "stopped_early=$prime_stopped_early"
		echo "minimum_mode_percent=$prime_min_mode_percent"
		echo "minimum_margin_percent=$prime_min_margin_percent"
		echo "stable_checkpoints_required=$prime_stable_checkpoints"
		echo "opt=$opt"
		echo "optad=$optad"
		echo "optcvad=$optcvad"
		echo "modal_result=$modal_prime"
	} > "$prime_summary"

	status_update "Prime selection complete: opt=$opt, optad=$optad, optcvad=$optcvad."
	status_update "Prime recommendation: $prime_summary"
}

run_plsiman_screen() {
	screen_directory="$work_directory/plsiman_screen"
	screen_summary="$run_directory/plsiman_summary.tsv"
	screen_recommendation="$run_directory/plsiman_recommendation.txt"
	screen_seed=${seeds[0]}
	screen_pliter=5
	mkdir -p "$screen_directory"
	printf "seed\tpliter\tplsimaniter\tsmoothing\truntime_seconds\tfinal_objective\tstatus\n" > "$screen_summary"

	status_update "Starting quick plsimaniter equivalence screen with seed=$screen_seed and pliter=$screen_pliter."
	for candidate_plsimaniter in "${pl_siman_candidates[@]}"
	do
		case_name="plsiman_seed-${screen_seed}_pliter-${screen_pliter}_plsimaniter-${candidate_plsimaniter}"
		case_directory="$screen_directory/$case_name"
		mkdir -p "$case_directory"
		config_name="$case_name.config"
		log_name="$case_name.log"
		tree_name="$case_name.tre"
		config_path="$case_directory/$config_name"
		log_path="$case_directory/$log_name"
		tree_path="$case_directory/$tree_name"

		write_common_configuration "$config_path"
		{
			echo "seed = $screen_seed"
			echo "smooth = $fixed_smoothing"
			echo "pliter = $screen_pliter"
			echo "plsimaniter = $candidate_plsimaniter"
			echo "outfile = $tree_name"
		} >> "$config_path"

		status_update "plsimaniter screen starting: $candidate_plsimaniter."
		start_time=$(date +%s)
		(
			cd "$case_directory" || exit 1
			exec treePL "$config_name"
		) > "$log_path" 2>&1
		exit_status=$?
		end_time=$(date +%s)
		runtime_seconds=$((end_time - start_time))
		final_objective=$(awk '/after opt calc:/ {value=$NF} END {print value}' "$log_path")

		if [ "$exit_status" -eq 0 ] && [ -s "$tree_path" ] && [ -n "$final_objective" ]
		then
			status="complete"
		else
			status="failed"
		fi

		printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
			"$screen_seed" "$screen_pliter" "$candidate_plsimaniter" \
			"$fixed_smoothing" "$runtime_seconds" "$final_objective" \
			"$status" >> "$screen_summary"
		status_update "plsimaniter screen $status: value=$candidate_plsimaniter, objective=${final_objective:-unavailable}, runtime=${runtime_seconds}s."
	done

	pl_simaniter=$(awk -F '\t' -v tolerance="$pl_siman_equivalence_percent" '
		NR > 1 && $7 == "complete" {
			objective[$3] = $6 + 0
			if (!found || objective[$3] < best) {
				best = objective[$3]
				found = 1
			}
		}
		END {
			selected = 0
			for (value in objective) {
				change = 100 * (objective[value] - best) / best
				if (change < 0) {
					change = -change
				}
				if (change <= tolerance && (selected == 0 || value + 0 < selected + 0)) {
					selected = value
				}
			}
			if (selected != 0) {
				print selected
			}
		}
	' "$screen_summary")

	if [ -z "$pl_simaniter" ]
	then
		status_update "ERROR: plsimaniter screen did not produce a recommendation."
		return 1
	fi

	{
		echo "seed=$screen_seed"
		echo "pliter=$screen_pliter"
		echo "equivalence_threshold_percent=$pl_siman_equivalence_percent"
		echo "recommended_plsimaniter=$pl_simaniter"
	} > "$screen_recommendation"
	status_update "plsimaniter recommendation: $pl_simaniter (smallest candidate within ${pl_siman_equivalence_percent}% of the best objective)."
}

run_pl_benchmarks() {
	pl_stage=${1:-pl}
	pl_stage_directory="$work_directory/$pl_stage"
	mkdir -p "$pl_stage_directory"
	pl_summary="$run_directory/${pl_stage}_summary.tsv"
	pl_convergence_summary="$run_directory/${pl_stage}_convergence.tsv"
	pl_recommendation="$run_directory/${pl_stage}_recommendation.txt"
	printf "case\tseed\tpliter\tplsimaniter\tsmoothing\truntime_seconds\tfinal_objective\tstatus\n" > "$pl_summary"
	printf "phase\tpliter\tprevious_pliter\traw_objective_change_percent\tchange_percent_per_10_iterations\tconsecutive_converged_steps\n" > "$pl_convergence_summary"

	previous_pliter=""
	converged_steps=0
	converged_pliter=""
	pl_scout_transition_pliter=""
	pliter=$pl_start
	pl_phase="scout"
	pl_scout_streak=0
	pl_next_growth_percent=50
	pl_search_failed=0

	while [ "$pliter" -le "$pl_max" ]
	do
		if [ "$pl_phase" = "scout" ] || \
		   { [ "$workflow_profile" = "fast" ] && [ "$pl_stage" = "initial_pl" ]; }
		then
			round_seeds=("${seeds[0]}")
		else
			round_seeds=("${seeds[@]}")
		fi

		status_update "Starting $pl_stage PL $pl_phase level $pliter with plsimaniter=$pl_simaniter across ${#round_seeds[@]} seed(s) at smoothing=$fixed_smoothing."

		for seed in "${round_seeds[@]}"
		do
			if [ "$pl_phase" = "confirmation" ] && \
			   [ -z "$previous_pliter" ] && \
			   [ "$seed" -eq "${seeds[0]}" ]
			then
				reusable_scout=$(awk -F '\t' -v reuse_seed="$seed" -v reuse_pliter="$pliter" '
					NR > 1 && $2 == reuse_seed && $3 == reuse_pliter && $8 == "complete" {found=1}
					END {print found+0}
				' "$pl_summary")
				if [ "$reusable_scout" -eq 1 ]
				then
					status_update "Reusing successful scout result for confirmation baseline: seed=$seed, pliter=$pliter."
					continue
				fi
			fi

			case_name="pl_seed-${seed}_pliter-${pliter}_plsimaniter-${pl_simaniter}"
			case_directory="$pl_stage_directory/$case_name"
			mkdir -p "$case_directory"

			config_name="$case_name.config"
			log_name="$case_name.log"
			tree_name="$case_name.tre"
			config_path="$case_directory/$config_name"
			log_path="$case_directory/$log_name"
			tree_path="$case_directory/$tree_name"

			write_common_configuration "$config_path"
			{
				echo "seed = $seed"
				echo "smooth = $fixed_smoothing"
				echo "pliter = $pliter"
				echo "plsimaniter = $pl_simaniter"
				echo "outfile = $tree_name"
			} >> "$config_path"

			status_update "PL run starting: seed=$seed, pliter=$pliter, plsimaniter=$pl_simaniter, smoothing=$fixed_smoothing."
			start_time=$(date +%s)
			(
				cd "$case_directory" || exit 1
				exec treePL "$config_name"
			) > "$log_path" 2>&1
			exit_status=$?
			end_time=$(date +%s)
			runtime_seconds=$((end_time - start_time))

			final_objective=$(awk '/after opt calc:/ {value=$NF} END {print value}' "$log_path")

			if [ "$exit_status" -eq 0 ] && [ -s "$tree_path" ] && [ -n "$final_objective" ]
			then
				status="complete"
			else
				status="failed"
			fi

			status_update "PL run $status: seed=$seed, pliter=$pliter, runtime=${runtime_seconds}s, objective=${final_objective:-unavailable}."

			printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
				"$case_name" "$seed" "$pliter" "$pl_simaniter" \
				"$fixed_smoothing" "$runtime_seconds" "$final_objective" \
				"$status" >> "$pl_summary"
		done

		failed_runs=$(awk -F '\t' -v current="$pliter" '
			NR > 1 && $3 == current && $8 != "complete" { count++ }
			END { print count + 0 }
		' "$pl_summary")

		if [ "$failed_runs" -gt 0 ]
		then
			status_update "ERROR: $failed_runs PL run(s) failed at pliter=$pliter. Adaptive search stopped."
			printf "%s\t%s\t%s\t\t\t%s\n" "$pl_phase" "$pliter" "$previous_pliter" "$converged_steps" >> "$pl_convergence_summary"
			pl_search_failed=1
			break
		fi

		if [ "$pl_phase" = "scout" ]
		then
			if [ -n "$previous_pliter" ]
			then
				scout_metrics=$(awk -F '\t' -v previous="$previous_pliter" -v current="$pliter" -v scout_seed="${seeds[0]}" '
					NR > 1 && $2 == scout_seed && $3 == previous && $8 == "complete" {
						previous_objective = $7 + 0
					}
					NR > 1 && $2 == scout_seed && $3 == current && $8 == "complete" {
						current_objective = $7 + 0
					}
					END {
						if (previous_objective != 0) {
							change = 100 * (previous_objective - current_objective) / previous_objective
							if (change < 0) {
								change = -change
							}
							normalized_change = change * 10 / (current - previous)
							printf "%.10g\t%.10g\n", change, normalized_change
						}
					}
				' "$pl_summary")
				scout_raw_change=$(printf "%s\n" "$scout_metrics" | awk '{print $1}')
				scout_normalized_change=$(printf "%s\n" "$scout_metrics" | awk '{print $2}')

				printf "scout\t%s\t%s\t%s\t%s\t0\n" \
					"$pliter" "$previous_pliter" "$scout_raw_change" "$scout_normalized_change" \
					>> "$pl_convergence_summary"
				status_update "PL scout check: $previous_pliter -> $pliter changed by ${scout_raw_change}% raw, equivalent to ${scout_normalized_change}% per 10 iterations for seed ${seeds[0]}; refinement threshold=${pl_scout_threshold_percent}% per 10."

				enter_confirmation=$(awk -v change="$scout_normalized_change" -v threshold="$pl_scout_threshold_percent" \
					'BEGIN {print(change <= threshold ? 1 : 0)}')

				if [ "$enter_confirmation" -eq 1 ]
				then
					pl_scout_streak=$((pl_scout_streak + 1))
				else
					pl_scout_streak=0
				fi

				status_update "PL scout refinement streak=$pl_scout_streak/$pl_scout_consecutive_steps; minimum confirmation pliter=$pl_scout_min_pliter."

				if [ "$pliter" -ge "$pl_scout_min_pliter" ] && \
				   [ "$pl_scout_streak" -ge "$pl_scout_consecutive_steps" ]
				then
					pl_phase="confirmation"
					pl_scout_transition_pliter=$pliter
					previous_pliter=""
					status_update "PL scout reached the refinement region; confirming pliter=$pliter across all seeds."
					continue
				fi
			else
				printf "scout\t%s\t\t\t\t0\n" "$pliter" >> "$pl_convergence_summary"
				status_update "PL scout baseline recorded at pliter=$pliter."
			fi

			previous_pliter=$pliter
			pliter=$((pliter * 2))
			status_update "PL scout improvement remains large; doubling pliter to $pliter."
			continue
		fi

		if [ -n "$previous_pliter" ]
		then
			change_metrics=$(awk -F '\t' -v previous="$previous_pliter" -v current="$pliter" '
				NR > 1 && $3 == previous && $8 == "complete" {
					previous_objective[$2] = $7 + 0
				}
				NR > 1 && $3 == current && $8 == "complete" {
					current_objective[$2] = $7 + 0
				}
				END {
					worst_raw = 0
					worst_normalized = 0
					for (seed in previous_objective) {
						if (seed in current_objective && previous_objective[seed] != 0) {
							change = 100 * (previous_objective[seed] - current_objective[seed]) / previous_objective[seed]
							if (change < 0) {
								change = -change
							}
							normalized_change = change * 10 / (current - previous)
							if (change > worst_raw) {
								worst_raw = change
							}
							if (normalized_change > worst_normalized) {
								worst_normalized = normalized_change
							}
						}
					}
					printf "%.10g\t%.10g\n", worst_raw, worst_normalized
				}
			' "$pl_summary")
			worst_raw_change=$(printf "%s\n" "$change_metrics" | awk '{print $1}')
			worst_normalized_change=$(printf "%s\n" "$change_metrics" | awk '{print $2}')

			is_converged=$(awk -v change="$worst_normalized_change" -v threshold="$pl_convergence_percent" \
				'BEGIN { print(change <= threshold ? 1 : 0) }')

			if [ "$is_converged" -eq 1 ]
			then
				converged_steps=$((converged_steps + 1))
			else
				converged_steps=0
			fi

			printf "confirmation\t%s\t%s\t%s\t%s\t%s\n" \
				"$pliter" "$previous_pliter" "$worst_raw_change" "$worst_normalized_change" "$converged_steps" \
				>> "$pl_convergence_summary"

			status_update "PL convergence check: $previous_pliter -> $pliter changed by at most ${worst_raw_change}% raw and ${worst_normalized_change}% per 10 iterations across seeds; threshold=${pl_convergence_percent}% per 10; streak=$converged_steps/$pl_consecutive_steps."

			pl_next_growth_percent=$(awk -v change="$worst_normalized_change" 'BEGIN {
				if (change > 1.0) {
					print 50
				} else if (change > 0.5) {
					print 40
				} else if (change > 0.2) {
					print 30
				} else {
					print 20
				}
			}')
			status_update "PL next-step heuristic selected ${pl_next_growth_percent}% growth based on the remaining objective change."

			if [ "$converged_steps" -ge "$pl_consecutive_steps" ]
			then
				converged_pliter=$pliter
				status_update "PL convergence criterion satisfied at pliter=$converged_pliter."
				break
			fi
		else
			printf "confirmation\t%s\t\t\t\t0\n" "$pliter" >> "$pl_convergence_summary"
			status_update "PL baseline recorded at pliter=$pliter; another iteration level is required to measure change."
			pl_next_growth_percent=50
		fi

		previous_pliter=$pliter
		pl_growth=$(((pliter * pl_next_growth_percent + 99) / 100))
		pl_growth=$((((pl_growth + pl_step - 1) / pl_step) * pl_step))
		if [ "$pl_growth" -lt "$pl_step" ]
		then
			pl_growth=$pl_step
		fi
		pliter=$((pliter + pl_growth))
		status_update "Advancing PL search to pliter=$pliter."
	done

	if [ -n "$converged_pliter" ]
	then
		buffered_numerator=$((converged_pliter * (100 + pl_buffer_percent)))
		buffered_pliter=$(((buffered_numerator + 99) / 100))
		recommended_pliter=$((((buffered_pliter + pl_rounding - 1) / pl_rounding) * pl_rounding))

		{
			echo "status=converged"
			echo "workflow_profile=$workflow_profile"
			echo "pl_stage=$pl_stage"
			echo "seeds_used=$(awk -F '\t' 'NR>1 && $8=="complete" {seen[$2]=1} END {for(seed in seen) printf "%s%s", separator, seed; separator=" "}' "$pl_summary")"
			echo "converged_pliter=$converged_pliter"
			echo "convergence_threshold_percent=$pl_convergence_percent"
			echo "required_consecutive_steps=$pl_consecutive_steps"
			echo "scout_transition_pliter=${pl_scout_transition_pliter:-not_determined}"
			echo "buffer_percent=$pl_buffer_percent"
			echo "rounding=$pl_rounding"
			echo "recommended_pliter=$recommended_pliter"
			echo "recommended_plsimaniter=$pl_simaniter"
		} > "$pl_recommendation"

		status_update "PL convergence reached at pliter=$converged_pliter."
		status_update "Buffered recommendation: pliter=$recommended_pliter, plsimaniter=$pl_simaniter."
		status_update "PL summaries: $pl_summary, $pl_convergence_summary, and $pl_recommendation."
	else
		{
			echo "status=not_converged"
			echo "failure_detected=$pl_search_failed"
			echo "maximum_tested_pliter=$pl_max"
			echo "scout_transition_pliter=${pl_scout_transition_pliter:-not_determined}"
			echo "recommended_pliter=not_determined"
			echo "recommended_plsimaniter=$pl_simaniter"
		} > "$pl_recommendation"

		if [ "$pl_search_failed" -eq 1 ]
		then
			status_update "PL convergence search ended because a treePL run failed."
			status_update "Review $pl_summary; later workflow stages will not run."
		else
			status_update "PL convergence was not reached by pliter=$pl_max."
			status_update "Review $pl_convergence_summary and raise pl_max if continued improvement is acceptable."
		fi
	fi

	if [ "$pl_search_failed" -eq 1 ] || [ -z "$converged_pliter" ]
	then
		return 1
	fi
}

run_random_cv_case() {
	stage=$1
	seed=$2
	cviter=$3
	cvsimaniter=$4
	case_cv_start=$5
	case_cv_stop=$6
	case_cv_step=$7

	case_name="${stage}_seed-${seed}_cviter-${cviter}_cvsimaniter-${cvsimaniter}"
	case_directory="$work_directory/random_cv/$case_name"
	mkdir -p "$case_directory"
	config_name="$case_name.config"
	log_name="$case_name.log"
	results_name="$case_name.results.tsv"
	config_path="$case_directory/$config_name"
	log_path="$case_directory/$log_name"
	results_path="$case_directory/$results_name"

	write_common_configuration "$config_path"
	{
		echo "seed = $seed"
		echo "randomcv"
		echo "cvoutfile = $results_name"
		echo "cvstart = $case_cv_start"
		echo "cvstop = $case_cv_stop"
		echo "cvmultstep = $case_cv_step"
		echo "pliter = $random_cv_pliter"
		echo "plsimaniter = $pl_simaniter"
		echo "cviter = $cviter"
		echo "cvsimaniter = $cvsimaniter"
	} >> "$config_path"

	: > "$results_path"
	status_update "Random CV $stage starting: seed=$seed, cviter=$cviter, cvsimaniter=$cvsimaniter, range=$case_cv_start to $case_cv_stop."
	start_time=$(date +%s)
	(
		cd "$case_directory" || exit 1
		exec treePL "$config_name"
	) > "$log_path" 2>&1 &
	active_pid=$!

	while true
	do
		if cv_value_is_present "$results_path" "$case_cv_stop"
		then
			kill "$active_pid" 2>/dev/null
			wait "$active_pid" 2>/dev/null
			break
		fi
		if ! kill -0 "$active_pid" 2>/dev/null
		then
			wait "$active_pid" 2>/dev/null
			break
		fi
		sleep 1
	done

	active_pid=""
	end_time=$(date +%s)
	runtime_seconds=$((end_time - start_time))

	if cv_value_is_present "$results_path" "$case_cv_stop"
	then
		best_result=$(extract_best_cv_result "$results_path")
		case_best_smoothing=$(printf "%s\n" "$best_result" | awk '{print $1}')
		case_best_score=$(printf "%s\n" "$best_result" | awk '{print $2}')
		case_status="complete"
	else
		case_best_smoothing=""
		case_best_score=""
		case_status="incomplete"
	fi

	printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
		"$stage" "$case_name" "$seed" "$cviter" "$cvsimaniter" \
		"$case_cv_start" "$case_cv_stop" "$runtime_seconds" \
		"$case_best_smoothing" "$case_best_score" "$case_status" >> "$cv_summary"
	status_update "Random CV $stage $case_status: seed=$seed, runtime=${runtime_seconds}s, best=${case_best_smoothing:-unavailable}, score=${case_best_score:-unavailable}."
}

run_cv_benchmarks() {
	cv_summary="$run_directory/cv_summary.tsv"
	cv_recommendation="$run_directory/cv_recommendation.txt"
	printf "stage\tcase\tseed\tcviter\tcvsimaniter\tcvstart\tcvstop\truntime_seconds\tbest_smoothing\tbest_score\tstatus\n" > "$cv_summary"

	if [ -z "$pl_scout_transition_pliter" ]
	then
		pl_scout_transition_pliter=$(awk -F '=' '$1 == "scout_transition_pliter" {print $2}' "$run_directory/initial_pl_recommendation.txt" 2>/dev/null)
	fi
	random_cv_pliter=${pl_scout_transition_pliter:-$random_cv_pliter_default}
	if [ "$random_cv_pliter" = "not_determined" ]; then random_cv_pliter=$random_cv_pliter_default; fi
	if [ "$random_cv_pliter" -lt "$random_cv_pliter_min" ]; then random_cv_pliter=$random_cv_pliter_min; fi
	if [ "$random_cv_pliter" -gt "$random_cv_pliter_max" ]; then random_cv_pliter=$random_cv_pliter_max; fi
	status_update "Random-CV screening uses pliter=$random_cv_pliter and plsimaniter=$pl_simaniter."

	# Fast mode uses one broad pilot. Thorough mode replicates the pilot and
	# adds the third seed if the first two differ by more than one decade.
	run_random_cv_case "pilot" "${seeds[0]}" 3 5000 "$cv_start" "$cv_stop" 0.1
	minimum_completed_pilots=1
	if [ "$workflow_profile" = "thorough" ]
	then
		minimum_completed_pilots=2
		run_random_cv_case "pilot" "${seeds[1]}" 3 5000 "$cv_start" "$cv_stop" 0.1
		pilot_ratio=$(awk -F '\t' '$1=="pilot" && $11=="complete" {v[++n]=$9+0} END {
			if(n<2 || v[1]==0 || v[2]==0) print 999999;
			else {r=v[1]/v[2]; if(r<1) r=1/r; print r}
		}' "$cv_summary")
		pilot_disagreement=$(awk -v ratio="$pilot_ratio" 'BEGIN {print(ratio>10.000001 ? 1 : 0)}')
		if [ "$pilot_disagreement" -eq 1 ]
		then
			status_update "Pilot seeds disagree by more than one decade; adding the third seed."
			run_random_cv_case "pilot" "${seeds[2]}" 3 5000 "$cv_start" "$cv_stop" 0.1
		fi
	fi

	completed_pilots=$(awk -F '\t' '$1=="pilot" && $11=="complete" {n++} END {print n+0}' "$cv_summary")
	if [ "$completed_pilots" -lt "$minimum_completed_pilots" ]
	then
		status_update "ERROR: only $completed_pilots/$minimum_completed_pilots required broad random-CV pilots completed; local tuning cannot continue."
		return 1
	fi
	pilot_bounds=$(awk -F '\t' '$1=="pilot" && $11=="complete" {
		v=$9+0; if(!n || v<minimum) minimum=v; if(!n || v>maximum) maximum=v; n++
	} END {if(n) printf "%.10g\t%.10g\n", maximum*10, minimum/10}' "$cv_summary")
	local_cv_start=$(printf "%s\n" "$pilot_bounds" | awk '{print $1}')
	local_cv_stop=$(printf "%s\n" "$pilot_bounds" | awk '{print $2}')
	local_cv_start=$(awk -v local="$local_cv_start" -v full="$cv_start" \
		'BEGIN {print(local>full ? full : local)}')
	local_cv_stop=$(awk -v local="$local_cv_stop" -v full="$cv_stop" \
		'BEGIN {print(local<full ? full : local)}')
	status_update "Pilot neighborhood selected: $local_cv_start to $local_cv_stop."

	if [ "$workflow_profile" = "fast" ]
	then
		recommended_cviter=$fast_cviter
		recommended_cvsimaniter=$fast_cvsimaniter
		screening_smoothing=$(awk -F '\t' '$1=="pilot" && $11=="complete" {
			value=$9+0
			if(!n || value<minimum) minimum=value
			if(!n || value>maximum) maximum=value
			n++
		} END {if(n) printf "%.10g", exp((log(minimum)+log(maximum))/2)}' "$cv_summary")
		if [ -z "$screening_smoothing" ]
		then
			status_update "ERROR: fast random CV did not identify a screening center."
			return 1
		fi
		{
			echo "status=complete"
			echo "workflow_profile=$workflow_profile"
			echo "randomcviter=10"
			echo "randomcvsamp=0.1"
			echo "randomcv_pliter=$random_cv_pliter"
			echo "randomcv_plsimaniter=$pl_simaniter"
			echo "recommended_cviter=$recommended_cviter"
			echo "recommended_cvsimaniter=$recommended_cvsimaniter"
			echo "screening_smoothing=$screening_smoothing"
			echo "pilot_local_start=$local_cv_start"
			echo "pilot_local_stop=$local_cv_stop"
			echo "requires_full_cv_validation=yes"
		} > "$cv_recommendation"
		status_update "Fast random-CV screening complete: cviter=$recommended_cviter, cvsimaniter=$recommended_cvsimaniter, geometric pilot center=$screening_smoothing."
		return 0
	fi

	# Test simulated-annealing effort locally first.
	for candidate_cvsimaniter in "${cv_siman_iterations[@]}"
	do
		run_random_cv_case "cvsiman" "${seeds[0]}" 3 "$candidate_cvsimaniter" "$local_cv_start" "$local_cv_stop" 0.1
	done
	highest_siman_best=$(awk -F '\t' -v highest="${cv_siman_iterations[${#cv_siman_iterations[@]}-1]}" \
		'$1=="cvsiman" && $5==highest && $11=="complete" {print $9}' "$cv_summary")
	if [ -z "$highest_siman_best" ]
	then
		status_update "ERROR: the highest cvsimaniter reference run did not complete; cvsimaniter cannot be selected safely."
		return 1
	fi
	recommended_cvsimaniter=$(awk -F '\t' -v target="$highest_siman_best" '
		$1=="cvsiman" && $11=="complete" && $9==target {
			if(!found || $5+0<best+0){best=$5; found=1}
		} END {if(found) print best}' "$cv_summary")
	recommended_cvsimaniter=${recommended_cvsimaniter:-${cv_siman_iterations[${#cv_siman_iterations[@]}-1]}}

	# With cvsimaniter fixed, find the smallest cviter matching the highest tested setting.
	for candidate_cviter in "${cv_iterations[@]}"
	do
		run_random_cv_case "cviter" "${seeds[0]}" "$candidate_cviter" "$recommended_cvsimaniter" "$local_cv_start" "$local_cv_stop" 0.1
	done
	highest_cviter_best=$(awk -F '\t' -v highest="${cv_iterations[${#cv_iterations[@]}-1]}" \
		'$1=="cviter" && $4==highest && $11=="complete" {print $9}' "$cv_summary")
	if [ -z "$highest_cviter_best" ]
	then
		status_update "ERROR: the highest cviter reference run did not complete; cviter cannot be selected safely."
		return 1
	fi
	recommended_cviter=$(awk -F '\t' -v target="$highest_cviter_best" '
		$1=="cviter" && $11=="complete" && $9==target {
			if(!found || $4+0<best+0){best=$4; found=1}
		} END {if(found) print best}' "$cv_summary")
	recommended_cviter=${recommended_cviter:-${cv_iterations[${#cv_iterations[@]}-1]}}

	# Confirm only the selected pair with the remaining seeds.
	run_random_cv_case "confirm" "${seeds[1]}" "$recommended_cviter" "$recommended_cvsimaniter" "$local_cv_start" "$local_cv_stop" 0.1
	run_random_cv_case "confirm" "${seeds[2]}" "$recommended_cviter" "$recommended_cvsimaniter" "$local_cv_start" "$local_cv_stop" 0.1
	selected_pair_completed=$(awk -F '\t' \
		-v selected_iter="$recommended_cviter" -v selected_siman="$recommended_cvsimaniter" '
		$11=="complete" && $4==selected_iter && $5==selected_siman &&
		($1=="cviter" || $1=="confirm") {count++}
		END {print count+0}' "$cv_summary")
	if [ "$selected_pair_completed" -lt 3 ]
	then
		status_update "ERROR: selected random-CV settings were not completed successfully across all three seeds."
		return 1
	fi

	screening_smoothing=$(awk -F '\t' \
		-v selected_iter="$recommended_cviter" -v selected_siman="$recommended_cvsimaniter" '
		$11=="complete" && $4==selected_iter && $5==selected_siman &&
		($1=="cviter" || $1=="confirm") {
			count[$9]++
			score_sum[$9]+=$10
		}
		END {
			for(v in count) {
				if(count[v]>best_count ||
				   (count[v]==best_count && score_sum[v]<best_score)) {
					best_count=count[v]
					best_score=score_sum[v]
					selected=v
				}
			}
			if(selected!="") print selected
		}' "$cv_summary")
	screening_smoothing=${screening_smoothing:-$highest_cviter_best}
	if [ -z "$screening_smoothing" ]
	then
		status_update "ERROR: random CV did not produce a screening smoothing value."
		return 1
	fi

	{
		echo "status=complete"
		echo "randomcviter=10"
		echo "randomcvsamp=0.1"
		echo "randomcv_pliter=$random_cv_pliter"
		echo "randomcv_plsimaniter=$pl_simaniter"
		echo "recommended_cviter=$recommended_cviter"
		echo "recommended_cvsimaniter=$recommended_cvsimaniter"
		echo "screening_smoothing=$screening_smoothing"
		echo "pilot_local_start=$local_cv_start"
		echo "pilot_local_stop=$local_cv_stop"
		echo "requires_full_cv_validation=yes"
	} > "$cv_recommendation"
	status_update "Random-CV tuning complete: cviter=$recommended_cviter, cvsimaniter=$recommended_cvsimaniter, screening smoothing=$screening_smoothing."
}

run_full_cv_validation() {
	cv_recommendation="$run_directory/cv_recommendation.txt"
	full_cv_summary="$run_directory/full_cv_summary.tsv"
	final_recommendation="$run_directory/final_recommendation.txt"

	screening_smoothing=$(awk -F '=' '$1 == "screening_smoothing" {print $2}' "$cv_recommendation")
	recommended_cviter=$(awk -F '=' '$1 == "recommended_cviter" {print $2}' "$cv_recommendation")
	recommended_cvsimaniter=$(awk -F '=' '$1 == "recommended_cvsimaniter" {print $2}' "$cv_recommendation")

	if [ -z "$screening_smoothing" ] || [ "$screening_smoothing" = "not_determined" ]
	then
		status_update "ERROR: random CV did not identify a stable smoothing region; full CV validation cannot be centered automatically."
		return 1
	fi

	refined_cv_start=$(awk -v value="$screening_smoothing" 'BEGIN {printf "%.10g", value * 10}')
	refined_cv_stop=$(awk -v value="$screening_smoothing" 'BEGIN {printf "%.10g", value / 10}')
	refined_cv_step=0.31622776601683794
	refined_cv_score_count=5

	recommended_pliter=$(awk -F '=' '$1 == "recommended_pliter" {print $2}' "$run_directory/initial_pl_recommendation.txt" 2>/dev/null)
	recommended_plsimaniter=$(awk -F '=' '$1 == "recommended_plsimaniter" {print $2}' "$run_directory/initial_pl_recommendation.txt" 2>/dev/null)

	printf "case\tseed\tcviter\tcvsimaniter\tcvstart\tcvstop\tcvmultstep\truntime_seconds\tbest_smoothing\tbest_score\tstatus\n" > "$full_cv_summary"
	full_cv_scores="$run_directory/full_cv_scores.tsv"
	printf "seed\tsmoothing\tscore\n" > "$full_cv_scores"
	if [ "$workflow_profile" = "fast" ]
	then
		full_cv_seeds=("${seeds[0]}")
	else
		full_cv_seeds=("${seeds[@]}")
	fi
	status_update "Starting refined full leave-one-out CV: center=$screening_smoothing, range=$refined_cv_start to $refined_cv_stop, multiplier=$refined_cv_step."

	for seed in "${full_cv_seeds[@]}"
	do
		case_name="fullcv_seed-${seed}_cviter-${recommended_cviter}_cvsimaniter-${recommended_cvsimaniter}"
		case_directory="$work_directory/full_cv/$case_name"
		mkdir -p "$case_directory"

		config_name="$case_name.config"
		log_name="$case_name.log"
		results_name="$case_name.results.tsv"
		config_path="$case_directory/$config_name"
		log_path="$case_directory/$log_name"
		results_path="$case_directory/$results_name"

		write_common_configuration "$config_path"
		{
			echo "seed = $seed"
			if [ -n "$recommended_pliter" ] && [ "$recommended_pliter" != "not_determined" ]
			then
				echo "pliter = $recommended_pliter"
			fi
			if [ -n "$recommended_plsimaniter" ]
			then
				echo "plsimaniter = $recommended_plsimaniter"
			fi
			echo "cv"
			echo "cvoutfile = $results_name"
			echo "cvstart = $refined_cv_start"
			echo "cvstop = $refined_cv_stop"
			echo "cvmultstep = $refined_cv_step"
			echo "cviter = $recommended_cviter"
			echo "cvsimaniter = $recommended_cvsimaniter"
		} >> "$config_path"

		: > "$results_path"
		status_update "Full CV run starting: seed=$seed, cviter=$recommended_cviter, cvsimaniter=$recommended_cvsimaniter."
		start_time=$(date +%s)

		(
			cd "$case_directory" || exit 1
			exec treePL "$config_name"
		) > "$log_path" 2>&1 &
		active_pid=$!

		while true
		do
			completed_score_count=$(awk '$1 == "chisq:" {count++} END {print count + 0}' "$results_path")
			if [ "$completed_score_count" -ge "$refined_cv_score_count" ]
			then
				status_update "Full CV seed=$seed wrote all $completed_score_count refined scores; stopping the redundant post-CV optimization."
				kill "$active_pid" 2>/dev/null
				wait "$active_pid" 2>/dev/null
				break
			fi

			if ! kill -0 "$active_pid" 2>/dev/null
			then
				wait "$active_pid" 2>/dev/null
				break
			fi

			sleep 1
		done

		active_pid=""
		end_time=$(date +%s)
		runtime_seconds=$((end_time - start_time))
		completed_score_count=$(awk '$1 == "chisq:" {count++} END {print count + 0}' "$results_path")

		if [ "$completed_score_count" -ge "$refined_cv_score_count" ]
		then
			best_result=$(extract_best_cv_result "$results_path")
			best_smoothing=$(printf "%s\n" "$best_result" | awk '{print $1}')
			best_score=$(printf "%s\n" "$best_result" | awk '{print $2}')
			status="complete"
		else
			best_smoothing=""
			best_score=""
			status="incomplete"
		fi

		status_update "Full CV run $status: seed=$seed, runtime=${runtime_seconds}s, best_smoothing=${best_smoothing:-unavailable}, best_score=${best_score:-unavailable}."
		printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
			"$case_name" "$seed" "$recommended_cviter" "$recommended_cvsimaniter" \
			"$refined_cv_start" "$refined_cv_stop" "$refined_cv_step" \
			"$runtime_seconds" "$best_smoothing" "$best_score" "$status" >> "$full_cv_summary"
		if [ "$status" = "complete" ]
		then
			awk -v score_seed="$seed" '$1 == "chisq:" {
				smoothing=$2; gsub(/[()]/, "", smoothing)
				printf "%s\t%.8g\t%s\n", score_seed, smoothing+0, $3
			}' "$results_path" >> "$full_cv_scores"
		fi
	done

	if [ "$workflow_profile" = "fast" ]
	then
		fast_coarse_winner=$(awk -F '\t' 'NR>1 {if(!found || $3+0<best){best=$3+0; selected=$2; found=1}} END {if(found) print selected}' "$full_cv_scores")
		if [ -z "$fast_coarse_winner" ]
		then
			status_update "ERROR: fast full CV did not produce a coarse winner."
			return 1
		fi
		fast_winner_is_interior=$(awk -v winner="$fast_coarse_winner" -v upper="$refined_cv_start" -v lower="$refined_cv_stop" 'BEGIN {
			tolerance=winner*0.00001+1e-12
			du=winner-upper; if(du<0) du=-du
			dl=winner-lower; if(dl<0) dl=-dl
			print(du>tolerance && dl>tolerance ? 1 : 0)
		}')
		if [ "$fast_winner_is_interior" -ne 1 ]
		then
			status_update "ERROR: fast full-CV winner $fast_coarse_winner is on the tested boundary; the optimum is not bracketed."
			return 1
		fi
		fast_confirm_start=$(awk -v winner="$fast_coarse_winner" -v step="$refined_cv_step" 'BEGIN {printf "%.10g", winner/step}')
		fast_confirm_stop=$(awk -v winner="$fast_coarse_winner" -v step="$refined_cv_step" 'BEGIN {printf "%.10g", winner*step}')
		fast_coarse_gap_percent=$(awk -F '\t' 'NR>1 {
			score=$3+0
			if(!found || score<best) {second=best; best=score; found=1}
			else if(second==0 || score<second) second=score
		} END {if(found && second>0) printf "%.10g", 100*(second-best)/best}' "$full_cv_scores")
		required_full_cv_runs=1
		if awk -v gap="${fast_coarse_gap_percent:-999}" -v threshold="$fine_refinement_threshold_percent" 'BEGIN {exit(gap<=threshold ? 0 : 1)}'
		then
			status_update "Fast full-CV winner is close to the runner-up (gap=${fast_coarse_gap_percent}%); adding one confirmation seed."
			confirm_seed=${seeds[1]}
			run_targeted_cv_case "coarse_confirm" "$confirm_seed" "$fast_confirm_start" "$fast_confirm_stop" "$refined_cv_step" 3
			if [ "$target_status" = "complete" ]
			then
				confirm_best=$(extract_best_cv_result "$target_results_path")
				confirm_best_smoothing=$(printf "%s\n" "$confirm_best" | awk '{print $1}')
				confirm_best_score=$(printf "%s\n" "$confirm_best" | awk '{print $2}')
				awk -v score_seed="$confirm_seed" '$1 == "chisq:" {
					smoothing=$2; gsub(/[()]/, "", smoothing)
					printf "%s\t%.8g\t%s\n", score_seed, smoothing+0, $3
				}' "$target_results_path" >> "$full_cv_scores"
				required_full_cv_runs=2
			fi
			printf "fast_confirm_seed-%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
				"$confirm_seed" "$confirm_seed" "$recommended_cviter" "$recommended_cvsimaniter" \
				"$fast_confirm_start" "$fast_confirm_stop" "$refined_cv_step" "$target_runtime_seconds" \
				"${confirm_best_smoothing:-}" "${confirm_best_score:-}" "$target_status" >> "$full_cv_summary"
			if [ "$target_status" != "complete" ]
			then
				status_update "ERROR: the required fast confirmation seed did not complete."
				return 1
			fi
			values_agree=$(awk -v first="$fast_coarse_winner" -v second="$confirm_best_smoothing" 'BEGIN {
				difference=first-second; if(difference<0) difference=-difference
				tolerance=first*0.00001+1e-12
				print(difference<=tolerance ? 1 : 0)
			}')
			confirm_best_smoothing=""
			confirm_best_score=""
			if [ "$values_agree" -ne 1 ]
			then
				status_update "The first two refined-CV seeds disagree; adding the third and final seed."
				confirm_seed=${seeds[2]}
				run_targeted_cv_case "coarse_confirm" "$confirm_seed" "$fast_confirm_start" "$fast_confirm_stop" "$refined_cv_step" 3
				if [ "$target_status" = "complete" ]
				then
					confirm_best=$(extract_best_cv_result "$target_results_path")
					confirm_best_smoothing=$(printf "%s\n" "$confirm_best" | awk '{print $1}')
					confirm_best_score=$(printf "%s\n" "$confirm_best" | awk '{print $2}')
					awk -v score_seed="$confirm_seed" '$1 == "chisq:" {
						smoothing=$2; gsub(/[()]/, "", smoothing)
						printf "%s\t%.8g\t%s\n", score_seed, smoothing+0, $3
					}' "$target_results_path" >> "$full_cv_scores"
					required_full_cv_runs=3
				fi
				printf "fast_confirm_seed-%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
					"$confirm_seed" "$confirm_seed" "$recommended_cviter" "$recommended_cvsimaniter" \
					"$fast_confirm_start" "$fast_confirm_stop" "$refined_cv_step" "$target_runtime_seconds" \
					"${confirm_best_smoothing:-}" "${confirm_best_score:-}" "$target_status" >> "$full_cv_summary"
				if [ "$target_status" != "complete" ]
				then
					status_update "ERROR: the tie-breaking fast confirmation seed did not complete."
					return 1
				fi
			fi
		else
			status_update "Fast full-CV winner is well separated (runner-up gap=${fast_coarse_gap_percent}%); seed confirmation skipped."
		fi
	else
		required_full_cv_runs=${#seeds[@]}
	fi

	completed_full_cv_runs=$(awk -F '\t' 'NR>1 && $11=="complete" {count++} END {print count+0}' "$full_cv_summary")
	if [ "$completed_full_cv_runs" -ne "$required_full_cv_runs" ]
	then
		{
			echo "status=incomplete"
			echo "reason=full_cv_seed_failure"
			echo "completed_full_cv_runs=$completed_full_cv_runs"
			echo "required_full_cv_runs=$required_full_cv_runs"
		} > "$final_recommendation"
		status_update "ERROR: full CV completed for $completed_full_cv_runs/$required_full_cv_runs required seeds; no final smoothing will be selected."
		return 1
	fi

	seed_count=$required_full_cv_runs
	final_smoothing=$(awk -F '\t' -v required="$seed_count" '
		NR > 1 {sum[$2]+=$3; count[$2]++}
		END {
			for(value in sum) {
				if(count[value] == required) {
					mean=sum[value]/count[value]
					if(!found || mean<best_mean) {
						best_mean=mean
						best_value=value
						found=1
					}
				}
			}
			if(found) print best_value
		}
	' "$full_cv_scores")
	coarse_final_smoothing=$final_smoothing
	adaptive_refinement_status="not_attempted"
	fine_cv_summary="$run_directory/fine_cv_summary.tsv"
	printf "stage\tseed\toriginal_smoothing\toriginal_score\tcandidate_smoothing\tcandidate_score\tpreferred\truntime_seconds\tstatus\n" > "$fine_cv_summary"

	if [ -n "$final_smoothing" ]
	then
		consensus_bracket_start=$refined_cv_start
		consensus_bracket_stop=$refined_cv_stop
		if [ "$workflow_profile" = "fast" ]
		then
			consensus_bracket_start=$fast_confirm_start
			consensus_bracket_stop=$fast_confirm_stop
		fi
		winner_is_interior=$(awk -v winner="$final_smoothing" -v upper="$consensus_bracket_start" -v lower="$consensus_bracket_stop" 'BEGIN {
			tolerance = winner * 0.00001 + 1e-12
			upper_difference = winner - upper; if(upper_difference < 0) upper_difference = -upper_difference
			lower_difference = winner - lower; if(lower_difference < 0) lower_difference = -lower_difference
			print(upper_difference > tolerance && lower_difference > tolerance ? 1 : 0)
		}')
		fine_gap_percent=$(awk -F '\t' -v required="$seed_count" '
			NR>1 {sum[$2]+=$3; count[$2]++}
			END {
				for(value in sum) if(count[value]==required) {
					mean=sum[value]/count[value]
					if(!found || mean<best) {second=best; best=mean; found=1}
					else if(second==0 || mean<second) second=mean
				}
				if(found && second>0) printf "%.10g", 100*(second-best)/best
			}' "$full_cv_scores")
		fine_refinement_needed=$(awk -v gap="${fine_gap_percent:-999}" -v threshold="$fine_refinement_threshold_percent" \
			'BEGIN {print(gap<=threshold ? 1 : 0)}')

		if [ "$workflow_profile" = "thorough" ] && [ "$winner_is_interior" -eq 1 ] && [ "$fine_refinement_needed" -eq 1 ]
		then
			fine_factor=1.7782794100389228
			fine_step=0.5623413251903491
			fine_start=$(awk -v value="$final_smoothing" -v factor="$fine_factor" 'BEGIN {printf "%.10g", value * factor}')
			fine_stop=$(awk -v value="$final_smoothing" -v factor="$fine_factor" 'BEGIN {printf "%.10g", value / factor}')
			pilot_seed=${seeds[0]}
			adaptive_refinement_status="pilot_incomplete"
			status_update "Coarse full-CV winner $final_smoothing is interior; testing quarter-decade neighbors $fine_start and $fine_stop with seed=$pilot_seed."
			run_targeted_cv_case "fine_pilot" "$pilot_seed" "$fine_start" "$fine_stop" "$fine_step" 3

			if [ "$target_status" = "complete" ]
			then
				fine_best_result=$(extract_best_cv_result "$target_results_path")
				fine_candidate=$(printf "%s\n" "$fine_best_result" | awk '{print $1}')
				pilot_original_score=$(extract_cv_score_for_value "$target_results_path" "$final_smoothing")
				pilot_candidate_score=$(extract_cv_score_for_value "$target_results_path" "$fine_candidate")
				if [ -n "$fine_candidate" ] && [ -n "$pilot_original_score" ] && [ -n "$pilot_candidate_score" ]
				then
					candidate_differs=$(awk -v candidate="$fine_candidate" -v original="$final_smoothing" 'BEGIN {
						difference=candidate-original; if(difference<0) difference=-difference
						tolerance=original*0.00001+1e-12
						print(difference>tolerance ? 1 : 0)
					}')
					if [ "$candidate_differs" -eq 0 ]
					then
						printf "pilot\t%s\t%s\t%s\t%s\t%s\toriginal\t%s\tcomplete\n" \
							"$pilot_seed" "$final_smoothing" "$pilot_original_score" "$fine_candidate" "$pilot_candidate_score" "$target_runtime_seconds" >> "$fine_cv_summary"
						adaptive_refinement_status="original_retained_by_pilot"
						status_update "Fine CV pilot retained the coarse winner $final_smoothing; no confirmation runs are needed."
					else
						candidate_votes=0
						original_votes=0
						if awk -v candidate="$pilot_candidate_score" -v original="$pilot_original_score" 'BEGIN {exit(candidate<original ? 0 : 1)}'
						then
							pilot_preferred="candidate"
							candidate_votes=$((candidate_votes + 1))
						else
							pilot_preferred="original"
							original_votes=$((original_votes + 1))
						fi
						printf "pilot\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tcomplete\n" \
							"$pilot_seed" "$final_smoothing" "$pilot_original_score" "$fine_candidate" "$pilot_candidate_score" "$pilot_preferred" "$target_runtime_seconds" >> "$fine_cv_summary"

						for confirm_seed in "${seeds[@]:1}"
						do
							pair_values=$(awk -v candidate="$fine_candidate" -v original="$final_smoothing" 'BEGIN {
								if(candidate>original) {upper=candidate; lower=original} else {upper=original; lower=candidate}
								printf "%.10g\t%.10g\t%.17g", upper, lower, lower/upper
							}')
							pair_start=$(printf "%s\n" "$pair_values" | awk '{print $1}')
							pair_stop=$(printf "%s\n" "$pair_values" | awk '{print $2}')
							pair_step=$(printf "%s\n" "$pair_values" | awk '{print $3}')
							run_targeted_cv_case "fine_confirm" "$confirm_seed" "$pair_start" "$pair_stop" "$pair_step" 2
							confirm_original_score=$(extract_cv_score_for_value "$target_results_path" "$final_smoothing")
							confirm_candidate_score=$(extract_cv_score_for_value "$target_results_path" "$fine_candidate")
							if [ "$target_status" = "complete" ] && [ -n "$confirm_original_score" ] && [ -n "$confirm_candidate_score" ]
							then
								if awk -v candidate="$confirm_candidate_score" -v original="$confirm_original_score" 'BEGIN {exit(candidate<original ? 0 : 1)}'
								then
									confirm_preferred="candidate"
									candidate_votes=$((candidate_votes + 1))
								else
									confirm_preferred="original"
									original_votes=$((original_votes + 1))
								fi
								printf "confirm\t%s\t%s\t%s\t%s\t%s\t%s\t%s\tcomplete\n" \
									"$confirm_seed" "$final_smoothing" "$confirm_original_score" "$fine_candidate" "$confirm_candidate_score" "$confirm_preferred" "$target_runtime_seconds" >> "$fine_cv_summary"
							else
								printf "confirm\t%s\t%s\t%s\t%s\t%s\tunavailable\t%s\tincomplete\n" \
									"$confirm_seed" "$final_smoothing" "$confirm_original_score" "$fine_candidate" "$confirm_candidate_score" "$target_runtime_seconds" >> "$fine_cv_summary"
							fi
						done

						if [ "$candidate_votes" -ge 2 ]
						then
							final_smoothing=$fine_candidate
							adaptive_refinement_status="candidate_selected"
							status_update "Adaptive fine CV selected $fine_candidate by $candidate_votes candidate vote(s) to $original_votes original vote(s)."
						else
							adaptive_refinement_status="original_retained_after_confirmation"
							status_update "Adaptive fine CV retained $final_smoothing by $original_votes original vote(s) to $candidate_votes candidate vote(s)."
						fi
					fi
				else
					adaptive_refinement_status="pilot_unusable"
					status_update "Fine CV pilot did not yield comparable original and candidate scores; retaining $final_smoothing."
				fi
			fi
		elif [ "$workflow_profile" = "fast" ] && [ "$winner_is_interior" -eq 1 ]
		then
			adaptive_refinement_status="skipped_in_fast_profile"
			status_update "Fine quarter-decade CV refinement skipped in fast mode."
		elif [ "$winner_is_interior" -eq 1 ]
		then
			adaptive_refinement_status="skipped_well_separated_curve"
			status_update "Fine CV refinement skipped: the next-best cross-seed mean score is ${fine_gap_percent}% above the winner, exceeding the ${fine_refinement_threshold_percent}% threshold."
		else
			adaptive_refinement_status="coarse_winner_unbracketed"
			{
				echo "status=incomplete"
				echo "reason=coarse_cv_winner_on_boundary"
				echo "seed_mode=$seed_mode"
				echo "seeds=${seeds[*]}"
				echo "coarse_smooth=$coarse_final_smoothing"
				echo "tested_cv_start=$consensus_bracket_start"
				echo "tested_cv_stop=$consensus_bracket_stop"
			} > "$final_recommendation"
			status_update "ERROR: coarse full-CV winner $final_smoothing lies on the tested boundary, so the optimum is not bracketed."
			return 1
		fi
	fi

	if [ -n "$final_smoothing" ]
	then
		{
			echo "status=complete"
			echo "workflow_profile=$workflow_profile"
			echo "seed_mode=$seed_mode"
			echo "seeds=${seeds[*]}"
			echo "opt=$opt"
			echo "optad=$optad"
			echo "optcvad=$optcvad"
			echo "pliter=${recommended_pliter:-not_determined}"
			echo "plsimaniter=${recommended_plsimaniter:-not_determined}"
			echo "cviter=$recommended_cviter"
			echo "cvsimaniter=$recommended_cvsimaniter"
			echo "randomcviter=10"
			echo "randomcvsamp=0.1"
			echo "randomcv_pliter=$random_cv_pliter"
			echo "randomcv_plsimaniter=$pl_simaniter"
			echo "coarse_smooth=$coarse_final_smoothing"
			echo "adaptive_refinement_status=$adaptive_refinement_status"
			echo "smooth=$final_smoothing"
		} > "$final_recommendation"
		status_update "Full CV validation finished. Final cross-seed consensus smoothing=$final_smoothing."
	else
		echo "status=incomplete" > "$final_recommendation"
		status_update "ERROR: full CV validation did not produce a final smoothing recommendation."
		return 1
	fi

	status_update "Full workflow recommendation: $final_recommendation"
	return 0
}

update_final_pl_recommendation() {
	final_recommendation="$run_directory/final_recommendation.txt"
	final_pl_recommendation="$run_directory/final_pl_recommendation.txt"

	if [ ! -f "$final_recommendation" ] || [ ! -f "$final_pl_recommendation" ]
	then
		status_update "ERROR: final PL recommendation could not be merged into the workflow recommendation."
		return 1
	fi

	final_pliter=$(awk -F '=' '$1 == "recommended_pliter" {print $2}' "$final_pl_recommendation")
	final_plsimaniter=$(awk -F '=' '$1 == "recommended_plsimaniter" {print $2}' "$final_pl_recommendation")
	temporary_recommendation="$final_recommendation.tmp"

	awk -F '=' '$1 != "pliter" && $1 != "plsimaniter"' "$final_recommendation" > "$temporary_recommendation"
	{
		echo "pliter=$final_pliter"
		echo "plsimaniter=$final_plsimaniter"
	} >> "$temporary_recommendation"
	mv "$temporary_recommendation" "$final_recommendation"

	status_update "Final PL confirmation merged: pliter=$final_pliter, plsimaniter=$final_plsimaniter."
}

status_update "Benchmark initialized."
status_update "Output directory: $run_directory"
status_update "Mode: $benchmark_mode; profile: $workflow_profile; tree: $tree_file; configuration: $configuration_file; smoothing: $fixed_smoothing."
status_update "Seed mode: $seed_mode; seeds: ${seeds[*]}."
{
	echo "workflow_profile=$workflow_profile"
	echo "seed_mode=$seed_mode"
	echo "seeds=${seeds[*]}"
} > "$run_directory/benchmark_seeds.txt"

if [ "$benchmark_mode" = "pl" ] || [ "$benchmark_mode" = "all" ] || [ "$benchmark_mode" = "full" ]
then
	status_update "PL search controls: scout starts at $pl_start and doubles; confirmation requires scout pliter >=$pl_scout_min_pliter with streak $pl_scout_consecutive_steps, then uses adaptive 20-50% growth rounded to $pl_step; maximum=$pl_max; convergence threshold=${pl_convergence_percent}% with streak=$pl_consecutive_steps; buffer=${pl_buffer_percent}%."
fi

if [ "$benchmark_mode" = "cv" ] || [ "$benchmark_mode" = "all" ] || [ "$benchmark_mode" = "full" ]
then
	if [ "$workflow_profile" = "fast" ]
	then
		status_update "Fast random-CV search: one broad pilot, fixed cviter=$fast_cviter and cvsimaniter=$fast_cvsimaniter, then one refined full CV. A second seed runs only for a close result; a third only if the first two disagree."
	else
		status_update "Thorough random-CV search: broad pilots, local cvsimaniter and cviter tests, then selected-pair confirmation across three seeds; candidates cviter=${cv_iterations[*]}; cvsimaniter=${cv_siman_iterations[*]}."
	fi
fi

if [ "$benchmark_mode" = "full" ]
then
	run_prime_selection || exit 7
	if [ "$workflow_profile" = "thorough" ]
	then
		run_plsiman_screen || exit 8
	else
		pl_simaniter=5000
		{
			echo "workflow_profile=$workflow_profile"
			echo "recommended_plsimaniter=$pl_simaniter"
			echo "basis=previous empirical equivalence tests"
		} > "$run_directory/plsiman_recommendation.txt"
		status_update "Fast mode uses empirically supported plsimaniter=$pl_simaniter without repeating the equivalence screen."
	fi
	run_pl_benchmarks "initial_pl" || exit 9
fi

if [ "$benchmark_mode" = "pl" ] || [ "$benchmark_mode" = "all" ]
then
	run_pl_benchmarks "pl" || exit 9
fi

if [ "$benchmark_mode" = "cv" ] || [ "$benchmark_mode" = "all" ] || [ "$benchmark_mode" = "full" ]
then
	run_cv_benchmarks || exit 6
fi

if [ "$benchmark_mode" = "full" ]
then
	run_full_cv_validation || exit 10
	if [ -n "$final_smoothing" ]
	then
		status_update "Repeating adaptive PL convergence at optimized smoothing=$final_smoothing."
		fixed_smoothing=$final_smoothing
		if ! run_pl_benchmarks "final_pl"
		then
			failed_recommendation="$run_directory/final_recommendation.failed.tmp"
			{
				echo "status=incomplete"
				awk -F '=' '$1 != "status"' "$run_directory/final_recommendation.txt"
				echo "failure_reason=final_pl_convergence_failed"
			} > "$failed_recommendation"
			mv "$failed_recommendation" "$run_directory/final_recommendation.txt"
			status_update "ERROR: final PL convergence failed; final recommendation marked incomplete."
			exit 11
		fi
		update_final_pl_recommendation || exit 12
	fi
fi

cleanup_work_directory
trap - INT TERM EXIT

status_update "Benchmark finished successfully. Results are in $run_directory."
