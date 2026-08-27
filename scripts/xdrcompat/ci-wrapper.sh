#!/usr/bin/env bash
set -u

repo=${1:?usage: ci-wrapper.sh REPO BASE HEAD}
base=${2:?usage: ci-wrapper.sh REPO BASE HEAD}
head=${3:?usage: ci-wrapper.sh REPO BASE HEAD}
script_dir=$(cd "$(dirname "$0")" && pwd)
report=$(mktemp)
diag=$(mktemp)
body=$(mktemp)
binary=$(mktemp)
trap 'rm -f "$report" "$diag" "$body" "$binary"' EXIT

# Marker identifying this tool's pull request comment so repeated pushes edit
# one comment in place instead of appending a new one per run.
marker='<!-- xdrcompat-report -->'

# GitHub rejects a comment body over 65536 bytes. Leave room for the framing.
max_body=45000

status=0
if ! (cd "$script_dir" && go build -o "$binary" .) >"$report" 2>&1; then
    status=2
else
    # stdout carries the human report; stderr carries workflow-command
    # annotations and any error diagnostics. Keeping them apart lets the
    # annotations reach the runner without polluting the rendered report.
    "$binary" --repo "$repo" --base "$base" --head "$head" --annotate \
        >"$report" 2>"$diag" || status=$?
fi

cat "$report"
cat "$diag" >&2

count=$(sed -n 's/^\([0-9][0-9]*\) wire-compatibility violation.*/\1/p' "$report" | head -n1)
case $status in
    0) headline=':white_check_mark: No wire-compatibility violations.' ;;
    1) headline=":warning: ${count:-Some} wire-compatibility violation(s) found. This is **advisory** and does not block the merge." ;;
    *) headline=':x: `xdrcompat` could not run. This is an operational failure, not a finding.' ;;
esac

{
    echo "$marker"
    echo '### XDR evolution rules (advisory)'
    echo
    echo "$headline"
    echo
    echo "<details><summary>Full report</summary>"
    echo
    if [[ -s $report ]]; then
        echo '```text'
        head -c "$max_body" "$report"
        if [[ $(wc -c <"$report") -gt $max_body ]]; then
            echo
            echo "[report truncated at ${max_body} bytes; see the step log for the rest]"
        fi
        echo '```'
    fi
    if [[ $status -eq 2 && -s $diag ]]; then
        echo
        echo '```text'
        head -c 4000 "$diag"
        echo '```'
    fi
    echo
    echo '</details>'
    echo
    echo "Compared \`${base}\` with \`${head}\`. Rules and remedies: \`scripts/xdrcompat/README.md\`."
} >"$body"

if [[ -n ${GITHUB_STEP_SUMMARY:-} ]]; then
    cat "$body" >>"$GITHUB_STEP_SUMMARY"
fi

# A pull request comment is the only reporting path a reviewer sees without
# leaving the pull request, so failing to post one is an operational failure
# even though the findings themselves are advisory. GH_TOKEN is deliberately
# left unset for runs that cannot write (fork pull requests), which skips the
# comment rather than failing it.
if [[ ${GITHUB_EVENT_NAME:-} == pull_request && -n ${PR_NUMBER:-} && -n ${GH_TOKEN:-} ]]; then
    comments="repos/${GITHUB_REPOSITORY}/issues/${PR_NUMBER}/comments"
    existing=$(gh api --paginate "$comments" \
        --jq ".[] | select(.body | startswith(\"$marker\")) | .id" | head -n1)

    if [[ -n $existing ]]; then
        endpoint="repos/${GITHUB_REPOSITORY}/issues/comments/${existing}"
        method=PATCH
    else
        endpoint="$comments"
        method=POST
    fi

    if ! gh api --method "$method" "$endpoint" -F body=@"$body" >/dev/null; then
        echo "::error title=xdrcompat::Could not $method the advisory report comment on PR #${PR_NUMBER}."
        exit 2
    fi
fi

# Compatibility findings are advisory. Build/load/parse errors are not.
if [[ $status -eq 0 || $status -eq 1 ]]; then
    exit 0
fi
exit "$status"
