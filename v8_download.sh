#!/bin/sh

set -e

dir="$(cd "$(dirname "$0")" && pwd)"
branch="$1"

depot_tools_dir="${dir}/depot_tools"

# Ensure depot_tools is available (initialize submodule if missing or empty)
if [ ! -d "$depot_tools_dir" ] || [ -z "$(ls -A "$depot_tools_dir" 2>/dev/null)" ]; then
  echo "depot_tools not found or empty at ${depot_tools_dir}, initializing submodule..."
  (
    set -x
    git -C "$dir" submodule update --init --recursive depot_tools
  )
fi

if [ ! -d "$depot_tools_dir" ] || [ -z "$(ls -A "$depot_tools_dir" 2>/dev/null)" ]; then
  echo "Error: depot_tools not available after initialization at ${depot_tools_dir}"
  exit 1
fi

export DEPOT_TOOLS_DIR="$depot_tools_dir"

PATH="${DEPOT_TOOLS_DIR}:$PATH"
export PATH

# Check if branch is provided as an argument
# If not, read the branch from VERSION file
if [ -z "$branch" ]; then
  branch="$(head -n1 "${dir}/VERSION" | cut -d'-' -f1)"
fi

test -n "$branch"

(
  set -x
  gclient sync --no-history --reset -r "$branch"
)
