#!/usr/bin/env bash
# Wraps npx difit with a pseudo-tty to avoid STDIN mode.

set -euo pipefail

# Validate arguments: require at least 2 positional args (target and base).
# Strip known flags (--clean, etc.) before counting.
positional_args=()
for arg in "$@"; do
  case "$arg" in
    --*) ;;  # skip flags
    *) positional_args+=("$arg") ;;
  esac
done

if [[ ${#positional_args[@]} -lt 2 ]]; then
  echo "Error: difit requires both <target> and <base> arguments." >&2
  echo "Usage: run-difit.sh [--clean] <target> <base>" >&2
  exit 1
fi

MIN_EXPECTED_SECONDS=10
start_time=$(date +%s)

if [[ "$(uname)" == "Darwin" ]]; then
  # macOS: script <file> <command...>
  script -q /dev/null npx difit "$@" | tr -d '\r'
else
  # Linux: script -c <command> <file>
  script -qc "npx difit $(printf '%q ' "$@")" /dev/null | tr -d '\r'
fi

elapsed=$(( $(date +%s) - start_time ))
if [[ $elapsed -lt $MIN_EXPECTED_SECONDS ]]; then
  echo "Warning: difit exited in ${elapsed}s (expected interactive session)" >&2
fi
