#!/usr/bin/env bash
# Build the raydepsets standalone zipapp binary from the Ray repo.
#
# Reads the commit hash from .raycommit, clones ray at that commit,
# installs dependencies, and produces the binary in _output/.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RAY_COMMIT="$(cat "$SCRIPT_DIR/.raycommit" | tr -d '[:space:]')"
RAY_REPO="https://github.com/ray-project/ray.git"
WORK_DIR="$SCRIPT_DIR/_build"
OUTPUT_DIR="$SCRIPT_DIR/_output"
RAYDEPSETS_SRC="ci/raydepsets"

echo "==> Building raydepsets binary for Ray commit: $RAY_COMMIT"

# Clean previous build artifacts
rm -rf "$WORK_DIR" "$OUTPUT_DIR"
mkdir -p "$WORK_DIR" "$OUTPUT_DIR"

# Shallow-clone ray at the target commit
echo "==> Cloning ray repo (shallow)..."
git clone --no-checkout --filter=blob:none "$RAY_REPO" "$WORK_DIR/ray"
cd "$WORK_DIR/ray"
git checkout "$RAY_COMMIT"

# Ensure uv is available (required at runtime by raydepsets)
if ! command -v uv &>/dev/null; then
    echo "==> Installing uv..."
    pip install --quiet uv
fi

# Install raydepsets and its dependencies from the source pyproject.toml
echo "==> Installing raydepsets dependencies..."
pip install --quiet "$WORK_DIR/ray/$RAYDEPSETS_SRC"

# Build the zipapp binary
echo "==> Building zipapp binary..."
python "$WORK_DIR/ray/$RAYDEPSETS_SRC/build_zipapp.py" "$OUTPUT_DIR/raydepsets"

echo "==> Done! Binary is at: $OUTPUT_DIR/raydepsets"
echo "    Upload the contents of $OUTPUT_DIR/ as a GitHub release artifact."
