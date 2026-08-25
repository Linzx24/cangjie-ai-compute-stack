#!/usr/bin/env bash
set -euo pipefail

expected_version="${CANGJIE_VERSION:-1.1.3}"
project_path="${1:-/workspace/examples/hello-cangjie}"

compiler_version="$(cjc --version 2>&1)"
project_manager_version="$(cjpm --version 2>&1)"

printf '%s\n' "$compiler_version"
printf '%s\n' "$project_manager_version"

if [[ "$compiler_version" != *"${expected_version}"* ]]; then
    printf 'Expected Cangjie %s, but compiler reported a different version.\n' "$expected_version" >&2
    exit 1
fi

cd "$project_path"
cjpm build
cjpm test --no-color

printf 'Docker/Linux verification passed for %s.\n' "$project_path"
