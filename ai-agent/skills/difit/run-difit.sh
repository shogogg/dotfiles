#!/usr/bin/env bash
# Wraps npx difit with a pseudo-tty to avoid STDIN mode.

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

# Validate: require exactly 2 positional args (target and base).
if [[ ${#positional_args[@]} -lt 2 ]]; then
  echo "Error: difit requires both <target> and <base> arguments." >&2
  echo "Usage: run-difit.sh [--clean] <target> <base>" >&2
  exit 1
fi

# Convert HEAD to @ (difit convention) in positional arguments.
converted_args=()
for arg in "${positional_args[@]}"; do
  if [[ "$arg" == "HEAD" ]]; then
    converted_args+=("@")
  else
    converted_args+=("$arg")
  fi
done

# Rebuild full argument list: flags + converted positional args.
set -- "${flags[@]+"${flags[@]}"}" "${converted_args[@]}"

MIN_EXPECTED_SECONDS=3
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
