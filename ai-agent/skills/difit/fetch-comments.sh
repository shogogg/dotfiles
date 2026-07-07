#!/usr/bin/env bash
# Fetches review comments from a running difit server via its HTTP API.
#
# Reads the auto-assigned port from difit's output file, then queries
# /api/comments-output. This retrieves comments reliably regardless of how the
# difit process is later terminated — unlike difit's stdout-on-shutdown mechanism,
# which is lost when the process receives SIGTERM (e.g. via TaskStop) or when its
# output pipe is broken.
#
# Requires difit to be launched with --keep-alive so the server stays reachable
# even after the browser tab is closed.
#
# Usage: fetch-comments.sh <output_file>

set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Error: fetch-comments.sh requires <output_file> argument." >&2
  exit 1
fi

output_file="$1"

if [[ ! -f "$output_file" ]]; then
  echo "Error: output file not found: $output_file" >&2
  exit 1
fi

# Extract the port from difit's startup message, e.g.:
#   🚀 difit server started on http://localhost:4970
port=$(grep -oE 'localhost:[0-9]+' "$output_file" | head -1 | cut -d: -f2)

if [[ -z "$port" ]]; then
  echo "Error: could not determine difit server port from $output_file" >&2
  exit 1
fi

curl -fsS --max-time 5 "http://localhost:${port}/api/comments-output"
