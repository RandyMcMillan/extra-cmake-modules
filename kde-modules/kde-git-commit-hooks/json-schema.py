#!/usr/bin/python3
# SPDX-FileCopyrightText: 2023 Alexander Lohnau <alexander.lohnau@gmx.de>
# SPDX-License-Identifier: BSD-2-Clause

import os
import subprocess
import yaml
import sys

def get_changed_files():
    result = subprocess.run(['git', 'diff', '--name-only', 'HEAD'], capture_output=True, text=True)
    return [file for file in result.stdout.splitlines() if file.endswith('.json')]

config_file = '.kde-ci.yml'

# Check if the file exists
if os.path.exists(config_file):
    with open(config_file, 'r') as file:
        config = yaml.safe_load(file)
else:
    print(f'{config_file} does not exist in current directory')
    config = {}

# Extract excluded files, used for tests that intentionally have broken files
excluded_files = ['compile_commands.json', 'ci-utilities']
if 'Options' in config and 'json-validate-ignore' in config['Options']:
    excluded_files += config['Options']['json-validate-ignore']

# Find JSON files
files = []
for file_path in get_changed_files():
    if not any(excluded_file in file_path for excluded_file in excluded_files):
        files.append(file_path)

if files:
    files_option = ' '.join(files)
    if len(sys.argv) > 1:
        schemafile = sys.argv[1]
    else:
        schemafile = os.path.join(os.path.dirname(__file__), 'resources', 'kpluginmetadata.schema.json')
    print(f"Validating {files_option} with {schemafile}")
    result = subprocess.run(['check-jsonschema', *files, '--schemafile', schemafile])
    # Fail the pipeline if command failed
    if result.returncode != 0:
        exit(1)

