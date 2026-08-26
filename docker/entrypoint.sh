#!/usr/bin/env bash
set -euo pipefail

# The official SDK setup script probes optional environment variables such as
# LD_LIBRARY_PATH without supplying defaults, so nounset must be disabled only
# while that script is loaded.
set +u
source "${CANGJIE_HOME}/envsetup.sh"
set -u
exec "$@"
