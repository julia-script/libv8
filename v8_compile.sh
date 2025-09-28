#!/bin/sh

set -e

dir="$(cd "$(dirname "$0")" && pwd)"
v8_dir="${dir}/v8"

if [ ! -d "$v8_dir" ]; then
  echo "v8 not found at $v8_dir"
  exit 1
fi

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

os="$(sh "${dir}/scripts/get_os.sh")"

cores="2"

if [ "$os" = "Linux" ]; then
  cores="$(grep -c processor /proc/cpuinfo)"
elif [ "$os" = "macOS" ]; then
  cores="$(sysctl -n hw.logicalcpu)"
fi

target_cpu="$(sh "${dir}/scripts/get_arch.sh")"

echo "Building V8 for $os $target_cpu"

cc_wrapper=""
if command -v ccache >/dev/null 2>&1 ; then
  cc_wrapper="ccache"
fi

gn_args="$(grep -v '^#\|^$' "${dir}/args/${os}.gn" | tr -d '\r' | tr '\n' ' ')"
gn_args="${gn_args}cc_wrapper=\"$cc_wrapper\""
gn_args="${gn_args} target_cpu=\"$target_cpu\""
gn_args="${gn_args} v8_target_cpu=\"$target_cpu\""

cd "${dir}/v8"

gn gen "./out/release" --args="$gn_args"

echo "==================== Build args start ===================="
gn args "./out/release" --list | tee "${dir}/gn-args_${os}.txt"
echo "==================== Build args end ===================="

(
  set -x
  ninja -C "./out/release" -j "$cores" v8_monolith
)

ls -lh ./out/release/obj/libv8_*.a

cd -
