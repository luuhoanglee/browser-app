#!/usr/bin/env bash
set -euo pipefail

base_sha="${CI_BASE_SHA:-}"
if [[ -z "$base_sha" || "$base_sha" == "0000000000000000000000000000000000000000" ]]; then
  base_sha="$(git rev-parse HEAD^)"
fi

mapfile -t dart_files < <(
  git diff --name-only --diff-filter=ACMRT "$base_sha" HEAD -- '*.dart'
)

if [[ ${#dart_files[@]} -eq 0 ]]; then
  echo "No changed Dart files."
  exit 0
fi

dart format --output=none --set-exit-if-changed "${dart_files[@]}"
