#!/usr/bin/env bash
set -u

repo=${1:?usage: ci-wrapper.sh REPO BASE HEAD}
base=${2:?usage: ci-wrapper.sh REPO BASE HEAD}
head=${3:?usage: ci-wrapper.sh REPO BASE HEAD}
script_dir=$(cd "$(dirname "$0")" && pwd)
report=$(mktemp)
binary=$(mktemp)
trap 'rm -f "$report" "$binary"' EXIT

status=0
if ! (cd "$script_dir" && go build -o "$binary" .) >"$report" 2>&1; then
    status=2
else
    "$binary" --repo "$repo" --base "$base" --head "$head" >"$report" 2>&1 || status=$?
fi

cat "$report"
if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
    {
        echo '## XDR evolution rules (advisory)'
        echo
        echo "Compared \`$base\` with \`$head\`. Exit status: \`$status\`."
        echo
        echo '```text'
        cat "$report"
        echo '```'
    } >>"$GITHUB_STEP_SUMMARY"
fi

# Compatibility findings are advisory. Build/load/parse errors are not.
if [[ $status -eq 0 || $status -eq 1 ]]; then
    exit 0
fi
exit "$status"
