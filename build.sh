#!/usr/bin/env bash
# Build the raydepsets standalone zipapp binary from the Ray repo.
#
# Reads the commit hash from .raycommit, clones ray at that commit,
# and uses Bazel to produce the binary in _output/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAY_COMMIT="$(cat "$SCRIPT_DIR/.raycommit" | tr -d '[:space:]')"
RAY_REPO="https://github.com/ray-project/ray.git"
WORK_DIR="$SCRIPT_DIR/_build"
OUTPUT_DIR="$SCRIPT_DIR/_output"

echo "==> Building raydepsets binary for Ray commit: $RAY_COMMIT"

# Clean previous build artifacts
rm -rf "$WORK_DIR" "$OUTPUT_DIR"
mkdir -p "$WORK_DIR" "$OUTPUT_DIR"

# Shallow-clone ray at the target commit
echo "==> Cloning ray repo (shallow)..."
git clone --no-checkout --filter=blob:none "$RAY_REPO" "$WORK_DIR/ray"
cd "$WORK_DIR/ray"
git checkout "$RAY_COMMIT"

# Build raydepsets zip with Bazel
echo "==> Building raydepsets with Bazel..."
bazelisk build //ci/raydepsets:raydepsets --build_python_zip --enable_runfiles --incompatible_use_python_toolchains=false --python_path=python

# Determine platform tag
OS="$(uname -s | tr '[:upper:]' '[:lower:]')"    # linux, darwin
ARCH="$(uname -m)"                                 # x86_64, aarch64, arm64
PLATFORM="${OS}-${ARCH}"

# Copy outputs to _output/ with platform tag
echo "==> Copying build artifacts..."
cp bazel-bin/ci/raydepsets/raydepsets "$OUTPUT_DIR/raydepsets-${PLATFORM}"

echo "==> Done! Binary is at: $OUTPUT_DIR/raydepsets-${PLATFORM}"
echo "    Upload the contents of $OUTPUT_DIR/ as a GitHub release artifact."
