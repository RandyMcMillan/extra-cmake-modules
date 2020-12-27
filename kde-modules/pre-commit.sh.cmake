#!/usr/bin/env bash

# Copied from hooks/pre-commit, all credits go to Albert Astals Cid

readonly output=$(git clang-format -v --diff)

if [[ "$output" == *"no modified files to format"* ]]; then exit 0; fi
if [[ "$output" == *"clang-format did not modify any files"* ]]; then exit 0; fi

echo "ERROR: you need to run git clang-format on your commit"
echo "       git clang-format -f is potentially what you want"
exit 1
