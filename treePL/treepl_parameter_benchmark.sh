#!/bin/bash

# Benchmark treePL optimization settings without touching production outputs.
#
# Usage:
#   ./treepl_parameter_benchmark.sh CONFIG TREE LABEL SMOOTHING [pl|cv|all]
#   ./treepl_parameter_benchmark.sh CONFIG TREE LABEL [fixed|random] full
#   ./treepl_parameter_benchmark.sh CONFIG TREE LABEL full [fixed|random]
#
# Example:
#   ./treepl_parameter_benchmark.sh \
#     roadies_v1.1.16b_wrapper.config \
#     roadies_v1.1.16b.nwk \
#     roadies_v1.1.16b \
#     0.001 \
#     pl
#
# Results are written directly to:
#   ./treepl_parameter_benchmark/
#
# Edit the search controls below if a smaller or larger experiment is desired.

if [ "$#" -lt 4 ] || [ "$#" -gt 5 ]
then
	echo "Usage:"
	echo "  $0 CONFIG TREE LABEL SMOOTHING [pl|cv|all]"
	echo "  $0 CONFIG TREE LABEL [fixed|random] full"
	echo "  $0 CONFIG TREE LABEL full [fixed|random]"
	exit 1
fi

configuration_input=$1
tree_input=$2
label=$3
seed_mode="fixed"

if [ "$4" = "full" ]
then
	benchmark_mode="full"
	seed_mode=${5:-fixed}
	# Used only for the initial optimizer-convergence stage. Full mode later
	# optimizes smoothing by CV and repeats PL convergence at that value.
	fixed_smoothing=1
elif [ "$#" -eq 5 ] && [ "$5" = "full" ] && \
     { [ "$4" = "fixed" ] || [ "$4" = "random" ]; }
then
	benchmark_mode="full"
	seed_mode=$4
	fixed_smoothing=1
else
	fixed_smoothing=$4
	benchmark_mode=${5:-all}
fi

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

benchmark_root="$(pwd)/treepl_parameter_benchmark"
run_directory="$benchmark_root"
work_directory="$run_directory/.work"
mkdir -p "$run_directory" "$work_directory"

# Use reproducible fixed seeds by default. Full mode accepts "random" directly
# before or after "full" to generate and record three fresh independent seeds.
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
pl_confirmation_growth_percent=20
pl_convergence_percent=0.1
pl_consecutive_steps=2
pl_buffer_percent=20
pl_rounding=10

# Cross-validation candidates used by the staged pilot search.
cv_iterations=(3 5 10)
cv_siman_iterations=(5000 7500 15000)
random_cv_pliter_default=20
random_cv_pliter_min=10
random_cv_pliter_max=50
cv_start=10000
cv_stop=0.00001
expected_cv_values=(10000 1000 100 10 1 0.1 0.01 0.001 0.0001 0.00001)

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

write_common_configuration() {
	destination=$1

	{
		echo "treefile = $tree_file"
		cat "$configuration_file"
		echo "thorough"
		echo "opt = $opt"
		echo "optad = $optad"
		echo "optcvad = $optcvad"
	} > "$destination"
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

cv_results_are_complete() {
	result_file=$1

	for expected_value in "${expected_cv_values[@]}"
	do
		if ! cv_value_is_present "$result_file" "$expected_value"
		then
			return 1
		fi
	done

	return 0
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

run_prime_selection() {
	prime_directory="$work_directory/prime"
	prime_config="$prime_directory/prime.config"
	prime_results="$prime_directory/prime_results.tsv"
	prime_summary="$run_directory/prime_recommendation.txt"
	mkdir -p "$prime_directory"
	: > "$prime_results"

	{
		echo "treefile = $tree_file"
		cat "$configuration_file"
		echo "thorough"
		echo "prime"
	} > "$prime_config"

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
		if [ "$pl_phase" = "scout" ]
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

	# Two broad pilot seeds locate the order of magnitude.
	run_random_cv_case "pilot" "${seeds[0]}" 3 5000 "$cv_start" "$cv_stop" 0.1
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

	completed_pilots=$(awk -F '\t' '$1=="pilot" && $11=="complete" {n++} END {print n+0}' "$cv_summary")
	if [ "$completed_pilots" -lt 2 ]
	then
		status_update "ERROR: fewer than two broad random-CV pilots completed; local tuning cannot continue."
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

	# Test simulated-annealing effort locally first.
	for candidate_cvsimaniter in "${cv_siman_iterations[@]}"
	do
		run_random_cv_case "cvsiman" "${seeds[0]}" 3 "$candidate_cvsimaniter" "$local_cv_start" "$local_cv_stop" 0.1
	done
	highest_siman_best=$(awk -F '\t' -v highest="${cv_siman_iterations[${#cv_siman_iterations[@]}-1]}" \
		'$1=="cvsiman" && $5==highest && $11=="complete" {print $9}' "$cv_summary")
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
	recommended_cviter=$(awk -F '\t' -v target="$highest_cviter_best" '
		$1=="cviter" && $11=="complete" && $9==target {
			if(!found || $4+0<best+0){best=$4; found=1}
		} END {if(found) print best}' "$cv_summary")
	recommended_cviter=${recommended_cviter:-${cv_iterations[${#cv_iterations[@]}-1]}}

	# Confirm only the selected pair with the remaining seeds.
	run_random_cv_case "confirm" "${seeds[1]}" "$recommended_cviter" "$recommended_cvsimaniter" "$local_cv_start" "$local_cv_stop" 0.1
	run_random_cv_case "confirm" "${seeds[2]}" "$recommended_cviter" "$recommended_cvsimaniter" "$local_cv_start" "$local_cv_stop" 0.1

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
	status_update "Starting refined full leave-one-out CV: center=$screening_smoothing, range=$refined_cv_start to $refined_cv_stop, multiplier=$refined_cv_step."

	for seed in "${seeds[@]}"
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
	done

	final_smoothing=$(awk -F '\t' '
		NR > 1 && $11 == "complete" {count[$9]++}
		END {
			for (value in count) {
				if (count[value] > best_count) {
					best_count = count[value]
					best_value = value
				}
			}
			if (best_value != "") {
				print best_value
			}
		}
	' "$full_cv_summary")

	if [ -n "$final_smoothing" ]
	then
		{
			echo "status=complete"
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
			echo "smooth=$final_smoothing"
		} > "$final_recommendation"
		status_update "Full CV validation finished. Final modal smoothing=$final_smoothing."
	else
		echo "status=incomplete" > "$final_recommendation"
		status_update "ERROR: full CV validation did not produce a final smoothing recommendation."
	fi

	status_update "Full workflow recommendation: $final_recommendation"
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
status_update "Mode: $benchmark_mode; tree: $tree_file; configuration: $configuration_file; smoothing: $fixed_smoothing."
status_update "Seed mode: $seed_mode; seeds: ${seeds[*]}."
{
	echo "seed_mode=$seed_mode"
	echo "seeds=${seeds[*]}"
} > "$run_directory/benchmark_seeds.txt"

if [ "$benchmark_mode" = "pl" ] || [ "$benchmark_mode" = "all" ] || [ "$benchmark_mode" = "full" ]
then
	status_update "PL search controls: scout starts at $pl_start and doubles; confirmation requires scout pliter >=$pl_scout_min_pliter with streak $pl_scout_consecutive_steps, then uses adaptive 20-50% growth rounded to $pl_step; maximum=$pl_max; convergence threshold=${pl_convergence_percent}% with streak=$pl_consecutive_steps; buffer=${pl_buffer_percent}%."
fi

if [ "$benchmark_mode" = "cv" ] || [ "$benchmark_mode" = "all" ] || [ "$benchmark_mode" = "full" ]
then
	status_update "Random-CV staged search: two broad pilots (third only if they differ by more than one decade), then local cvsimaniter and cviter tests, followed by selected-pair confirmation across three seeds; candidates cviter=${cv_iterations[*]}; cvsimaniter=${cv_siman_iterations[*]}; range=$cv_start to $cv_stop; fixed randomcviter=10; fixed randomcvsamp=0.1."
fi

if [ "$benchmark_mode" = "full" ]
then
	run_prime_selection || exit 7
	run_plsiman_screen || exit 8
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
		run_pl_benchmarks "final_pl" || exit 11
		update_final_pl_recommendation
	fi
fi

cleanup_work_directory
trap - INT TERM EXIT

status_update "Benchmark finished successfully. Results are in $run_directory."
