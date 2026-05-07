#!/usr/bin/env bash
# Find the cpu that actually achieves the highest sustained boost frequency.
#
# Step 1 — collect every cpu whose cpuinfo_max_freq matches the highest value
#          on this host (i.e., the silicon's TVB/TBM-eligible "favoured" cores).
# Step 2 — if only one candidate, return it. Otherwise stress each candidate
#          briefly and pick the one whose live cpu MHz peaks highest. HWP and
#          intel_pstate report identical theoretical maxes for cores that
#          actually differ in silicon-bin quality — empirical measurement is
#          the only signal that distinguishes them.
#
# Output: a single cpu number on stdout, or empty if detection fails. The
# caller is expected to fall back to a static range when output is empty.
set -u

MAX_FREQ=0
for f in /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq; do
  [ -r "$f" ] || continue
  freq=$(cat "$f")
  [ "$freq" -gt "$MAX_FREQ" ] && MAX_FREQ=$freq
done
[ "$MAX_FREQ" -eq 0 ] && exit 0

CANDIDATES=()
for f in /sys/devices/system/cpu/cpu*/cpufreq/cpuinfo_max_freq; do
  [ -r "$f" ] || continue
  if [ "$(cat "$f")" -eq "$MAX_FREQ" ]; then
    cpu_num=$(echo "$f" | sed -E 's:.*/cpu([0-9]+)/.*:\1:')
    CANDIDATES+=("$cpu_num")
  fi
done

# Single candidate or no candidates → no tiebreaker needed
if [ "${#CANDIDATES[@]}" -le 1 ]; then
  printf '%s' "${CANDIDATES[0]:-}"
  exit 0
fi

read_mhz() {
  awk -v c="$1" '/^processor/{p=$3} p==c && /cpu MHz/ {printf "%.0f", $4; exit}' /proc/cpuinfo
}

declare -A SCORE
# Two rounds in opposite order — averaging cancels the thermal bias of the
# core tested first being measured cooler than the last.
for round in 1 2; do
  if [ "$round" -eq 1 ]; then
    ORDER=("${CANDIDATES[@]}")
  else
    ORDER=()
    for ((i=${#CANDIDATES[@]}-1; i>=0; i--)); do ORDER+=("${CANDIDATES[i]}"); done
  fi

  for cpu in "${ORDER[@]}"; do
    # Cooldown between candidates so each test starts from a similar package
    # thermal state. Skipped on the very first iteration.
    sleep 0.5

    # Pinned busy loop to push HWP toward this core's TVB ceiling.
    taskset -c "$cpu" bash -c 'while :; do :; done' >/dev/null 2>&1 &
    PID=$!
    # Wait for HWP to ramp, then sample several times and keep the peak.
    sleep 0.3
    peak=0
    for _ in 1 2 3 4 5 6; do
      f=$(read_mhz "$cpu")
      [ -n "$f" ] && [ "$f" -gt "$peak" ] && peak=$f
      sleep 0.15
    done
    kill "$PID" 2>/dev/null
    wait "$PID" 2>/dev/null

    SCORE[$cpu]=$(( ${SCORE[$cpu]:-0} + peak ))
  done
done

# Pick the cpu with the best summed peak across both rounds.
BEST_CPU=""
BEST_FREQ=0
for cpu in "${CANDIDATES[@]}"; do
  s=${SCORE[$cpu]:-0}
  if [ "$s" -gt "$BEST_FREQ" ]; then
    BEST_FREQ=$s
    BEST_CPU=$cpu
  fi
done

printf '%s' "$BEST_CPU"
