#!/usr/bin/env bash

# Based on okular/hooks/pre-commit, credits go to Albert Astals Cid

readonly output=$(git clang-format -v --diff)

if [[ "$output" == *"no modified files to format"* ]]; then exit 0; fi
if [[ "$output" == *"clang-format did not modify any files"* ]]; then exit 0; fi

# Output the diff if we are already in a known shell
readonly parentProcessName=$(cat "/proc/$(ps -o ppid= $(ps -o ppid= $PPID)| sed 's/ //g')/comm")
if [ "$parentProcessName" == 'bash' ] || [ "$parentProcessName" == 'fish' ] || [ "$parentProcessName" == 'zsh' ]
then
    echo ""
    echo "The \"git clang-format --diff\" output is:"
    git clang-format --diff
    echo ""
    read -p "Do you want to apply the formatting? y/n " yn < /dev/tty
    while true; do
        case $yn in
            [Yy]* ) git clang-format -f; exit 0; break;;
            [Nn]* ) echo "Aborting due to unformatted files"; exit 1;;
            * ) echo "Please answer y or n.";;
        esac
    done
else
  echo "ERROR: You have unformatted changes, please format your files. You can do this using the following commands:"
  echo "       git clang-format --force # format the changed parts"
  echo "       git clang-format --diff # preview the changes done by the formatter"
fi
exit 1
