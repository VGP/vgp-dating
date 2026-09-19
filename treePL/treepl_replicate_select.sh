#!/bin/bash

# Run an already optimized, non-CV treePL configuration with multiple seeds.
# Retain only a summary, the lowest-objective tree, and its selection
# record; per-replicate configurations, logs, and trees are temporary.
#
# Usage:
#   ./treepl_replicate_select.sh CONFIG [RUNS] [random]
#   ./treepl_replicate_select.sh CONFIG [RUNS] fixed [START_SEED]
#
# Example:
#   ./treepl_replicate_select.sh roadies_v1.1.16b/roadies_v1.1.16b.config 10 random
#   ./treepl_replicate_select.sh roadies_v1.1.16b/roadies_v1.1.16b.config 10 fixed 1729
#
# Results:
#   <configuration directory>/generated/treepl_replicate_runs/
#
# This script deliberately runs replicates sequentially because each treePL
# configuration may already use multiple OpenMP threads through nthreads.

if [ "$#" -lt 1 ] || [ "$#" -gt 4 ]
then
	echo "Usage:"
	echo "  $0 CONFIG [RUNS] [random]"
	echo "  $0 CONFIG [RUNS] fixed [START_SEED]"
	exit 1
fi

configuration_input=$1
replicate_count=${2:-10}
seed_mode=${3:-random}
starting_seed=${4:-1729}
seed_increment=1009

if [ ! -f "$configuration_input" ]
then
	echo "Error: configuration file not found: $configuration_input"
	exit 2
fi

case "$replicate_count" in
	''|*[!0-9]*|0)
		echo "Error: RUNS must be a positive integer"
		exit 3
		;;
esac

case "$seed_mode" in
	random)
		if [ "$#" -eq 4 ]
		then
			echo "Error: START_SEED applies only to fixed seed mode"
			exit 4
		fi
		;;
	fixed)
		case "$starting_seed" in
			''|*[!0-9]*)
				echo "Error: START_SEED must be a non-negative integer"
				exit 4
				;;
		esac
		;;
	*)
		echo "Error: seed mode must be random or fixed"
		exit 4
		;;
esac

if awk '
	/^[[:space:]]*#/ {next}
	/^[[:space:]]*(cv|randomcv|prime)[[:space:]]*$/ {found=1}
	END {exit(found ? 0 : 1)}
' "$configuration_input"
then
	echo "Error: this runner requires cv, randomcv, and prime to be commented out"
	exit 5
fi

configuration_file="$(cd "$(dirname "$configuration_input")" && pwd)/$(basename "$configuration_input")"
configuration_directory=$(dirname "$configuration_file")
configuration_basename=$(basename "$configuration_file")
configuration_label=${configuration_basename%.config}
run_root="$configuration_directory/generated/treepl_replicate_runs"
summary_file="$run_root/replicate_summary.tsv"
selection_file="$run_root/selected_replicate.txt"
selected_tree="$run_root/${configuration_label}.lowest_objective.tre"

mkdir -p "$run_root"
printf "replicate\tseed\truntime_seconds\tfinal_objective\tstatus\n" > "$summary_file"

active_pid=""
current_replicate_directory=""
lowest_objective=""
selected_replicate=""
selected_seed=""
used_seeds=()

status_update() {
	printf "[%s] %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

stop_active_process() {
	if [ -n "$active_pid" ]
	then
		status_update "Stopping active treePL process (PID $active_pid)."
		kill "$active_pid" 2>/dev/null
	fi
}

stop_active_process_and_exit() {
	stop_active_process
	if [ -n "$current_replicate_directory" ] && [ -d "$current_replicate_directory" ]
	then
		rm -rf -- "$current_replicate_directory"
	fi
	exit 130
}

trap stop_active_process_and_exit INT TERM
trap stop_active_process EXIT

status_update "Replicate analysis initialized."
status_update "Configuration: $configuration_file"
if [ "$seed_mode" = "fixed" ]
then
	status_update "Replicates: $replicate_count; seed mode: fixed; starting seed: $starting_seed; seed increment: $seed_increment."
else
	status_update "Replicates: $replicate_count; seed mode: random; every generated seed will be recorded."
fi
status_update "Output directory: $run_root"

replicate=1
while [ "$replicate" -le "$replicate_count" ]
do
	if [ "$seed_mode" = "fixed" ]
	then
		seed=$((starting_seed + (replicate - 1) * seed_increment))
	else
		while true
		do
			seed=$(od -An -N4 -tu4 /dev/urandom | tr -d '[:space:]')
			seed=$((seed % 2147483646 + 1))
			seed_already_used=0
			for existing_seed in "${used_seeds[@]}"
			do
				if [ "$seed" -eq "$existing_seed" ]
				then
					seed_already_used=1
				fi
			done
			if [ "$seed_already_used" -eq 0 ]
			then
				used_seeds+=("$seed")
				break
			fi
		done
	fi
	replicate_name=$(printf "replicate_%03d_seed_%d" "$replicate" "$seed")
	replicate_directory="$run_root/$replicate_name"
	current_replicate_directory="$replicate_directory"
	replicate_config="$replicate_directory/$replicate_name.config"
	replicate_log="$replicate_directory/$replicate_name.log"
	replicate_tree="$replicate_directory/$replicate_name.tre"
	mkdir -p "$replicate_directory"

	awk '
		/^[[:space:]]*#/ {print; next}
		/^[[:space:]]*(seed|outfile)[[:space:]]*=/ {next}
		{print}
	' "$configuration_file" > "$replicate_config"
	{
		echo
		echo "# Replicate-specific settings"
		echo "seed = $seed"
		echo "outfile = $replicate_tree"
	} >> "$replicate_config"

	status_update "Replicate $replicate/$replicate_count starting: seed=$seed."
	start_time=$(date +%s)
	(
		cd "$configuration_directory" || exit 1
		exec treePL "$replicate_config"
	) > "$replicate_log" 2>&1 &
	active_pid=$!

	if wait "$active_pid"
	then
		exit_status=0
	else
		exit_status=$?
	fi
	active_pid=""
	end_time=$(date +%s)
	runtime_seconds=$((end_time - start_time))

	final_objective=$(awk '
		$1=="after" && $2=="opt" && $3=="calc:" {value=$4}
		END {if(value!="") print value}
	' "$replicate_log")

	if [ "$exit_status" -eq 0 ] && [ -s "$replicate_tree" ] && [ -n "$final_objective" ]
	then
		status="complete"
	else
		status="incomplete"
	fi

	printf "%s\t%s\t%s\t%s\t%s\n" \
		"$replicate" "$seed" "$runtime_seconds" "$final_objective" "$status" >> "$summary_file"

	status_update "Replicate $replicate $status: seed=$seed, runtime=${runtime_seconds}s, objective=${final_objective:-unavailable}."

	if [ "$status" = "complete" ]
	then
		is_new_best=$(awk -v candidate="$final_objective" -v current="$lowest_objective" \
			'BEGIN {print(current=="" || candidate+0<current+0 ? 1 : 0)}')
		if [ "$is_new_best" -eq 1 ]
		then
			cp "$replicate_tree" "$selected_tree"
			lowest_objective=$final_objective
			selected_replicate=$replicate
			selected_seed=$seed
			status_update "New lowest objective retained: replicate=$replicate, seed=$seed, objective=$final_objective."
		fi
	fi

	rm -rf -- "$replicate_directory"
	current_replicate_directory=""
	replicate=$((replicate + 1))
done

if [ -z "$lowest_objective" ] || [ ! -s "$selected_tree" ]
then
	status_update "ERROR: no replicate produced both a tree and a final objective."
	exit 6
fi

{
	echo "status=complete"
	echo "seed_mode=$seed_mode"
	echo "selected_replicate=$selected_replicate"
	echo "selected_seed=$selected_seed"
	echo "lowest_objective=$lowest_objective"
	echo "selected_tree=$selected_tree"
	echo "summary=$summary_file"
} > "$selection_file"

status_update "Selection complete: replicate=$selected_replicate, seed=$selected_seed, objective=$lowest_objective."
status_update "Selected tree: $selected_tree"
status_update "Selection record: $selection_file"
