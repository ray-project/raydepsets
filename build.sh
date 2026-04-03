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
bazel build //ci/raydepsets:raydepsets --build_python_zip

# Copy outputs to _output/
echo "==> Copying build artifacts..."
cp bazel-bin/ci/raydepsets/raydepsets "$OUTPUT_DIR/raydepsets"
cp bazel-bin/ci/raydepsets/raydepsets.zip "$OUTPUT_DIR/raydepsets.zip"

echo "==> Done! Binary is at: $OUTPUT_DIR/raydepsets"
echo "    Upload the contents of $OUTPUT_DIR/ as a GitHub release artifact."
