#!/bin/sh

set -e

dir="$(cd "$(dirname "$0")" && pwd)"

if [ ! -d "${dir}/v8" ]; then
  echo "v8 not found"
  exit 1
fi

os="$(sh "${dir}/scripts/get_os.sh")"

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

(
  set -x
  if [ "$os" = "macOS" ]; then
    g++ -std=c++20 \
      -I"${dir}/v8" -I"${dir}/v8/include" \
      "${dir}/v8/samples/hello-world.cc" \
      -L"${dir}/v8/out/release/obj/" -lv8_monolith \
      -framework CoreFoundation -framework Security \
      -F/System/Library/Frameworks \
      -o hello_world
  else
    g++ -std=c++20 \
      -I"${dir}/v8" -I"${dir}/v8/include" \
      "${dir}/v8/samples/hello-world.cc" \
      -L"${dir}/v8/out/release/obj/" -lv8_monolith \
      -pthread -ldl \
      -o hello_world
  fi
)

sh -c "./hello_world"
