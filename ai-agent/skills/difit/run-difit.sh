#!/usr/bin/env bash
# Wraps npx difit. Uses script (pseudo-tty) only when stdin is a pipe to avoid
# difit entering STDIN mode. Otherwise runs difit directly with stdin from
# /dev/null, bypassing script's tcgetattr failure on socket stdin (e.g. Claude Code).
#
# Usage: run-difit.sh [--flags] <output_file> <target> <base>
#
# <output_file> is required (1st positional arg). difit output is written directly
# to that file (no pipe through tr) to ensure stdout is flushed on exit.

set -euo pipefail

# Separate flags and positional arguments.
flags=()
positional_args=()
for arg in "$@"; do
  case "$arg" in
    --*) flags+=("$arg") ;;
    *) positional_args+=("$arg") ;;
  esac
done

# Validate: require exactly 3 positional args (output_file, target, base).
if [[ ${#positional_args[@]} -lt 3 ]]; then
  echo "Error: run-difit.sh requires <output_file>, <target>, and <base> arguments." >&2
  echo "Usage: run-difit.sh [--clean] <output_file> <target> <base>" >&2
  exit 1
fi

output_file="${positional_args[0]}"
target="${positional_args[1]}"
base="${positional_args[2]}"

# Convert HEAD to @ (difit convention).
[[ "$target" == "HEAD" ]] && target="@"
[[ "$base" == "HEAD" ]] && base="@"

MIN_EXPECTED_SECONDS=3
start_time=$(date +%s)

# Redirect difit output directly to the output file (no pipe).
# Avoids broken pipe data loss when the process is terminated — without a pipe,
# Node.js flushes its stdout buffer to the file on exit (including signal handlers).
npx difit "${flags[@]+"${flags[@]}"}" "$target" "$base" < /dev/null > "$output_file" 2>&1

elapsed=$(( $(date +%s) - start_time ))
if [[ $elapsed -lt $MIN_EXPECTED_SECONDS ]]; then
  echo "Warning: difit exited in ${elapsed}s (expected interactive session)" >&2
fi
