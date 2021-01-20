#.rst:
# KDEClangFormat
# --------------------
#
# This module provides a functionality to format the source
# code of your repository according to a predefined KDE
# clang-format file.
#
# This module provides the following function:
#
# ::
#
#   kde_clang_format(<files>)
#
# Using this function will create a clang-format target that will format all
# ``<files>`` passed to the function with the predefined KDE clang-format style.
# To format the files you have to invoke the target with ``make clang-format`` or ``ninja clang-format``.
# Once the project is formatted it is recommended to enforce the formatting using a pre-commit hook,
# this can be done using :kde-module:`KDEGitCommitHooks`.
#
# The ``.clang-fomat`` file from ECM will be copied to the source directory. This file should not be
# added to version control. It is recommended to add it to the ``.gitignore`` file: ``/.clang-format``.
#
# Example usage:
#
# .. code-block:: cmake
#
#   include(KDEClangFormat)
#   file(GLOB_RECURSE ALL_CLANG_FORMAT_SOURCE_FILES *.cpp *.h)
#   kde_clang_format(${ALL_CLANG_FORMAT_SOURCE_FILES})
#
# To exclude folders from the formatting add a ``.clang-format``
# file in the directory with the following contents:
#
# .. code-block:: ini
#
#    DisableFormat: true
#    SortIncludes: false
#
# Since 5.64

#=============================================================================
# SPDX-FileCopyrightText: 2019 Christoph Cullmann <cullmann@kde.org>
#
# SPDX-License-Identifier: BSD-3-Clause

# try to find clang-format in path
find_program(KDE_CLANG_FORMAT_EXECUTABLE clang-format)

# instantiate our clang-format file, must be in source directory for tooling if we have the tool
if(KDE_CLANG_FORMAT_EXECUTABLE)
    configure_file(${CMAKE_CURRENT_LIST_DIR}/clang-format.cmake ${CMAKE_CURRENT_SOURCE_DIR}/.clang-format @ONLY)
endif()

# formatting target
function(KDE_CLANG_FORMAT)
    # add target without specific commands first, we add the real calls file-per-file to avoid command line length issues
    add_custom_target(clang-format COMMENT "Formatting sources in ${CMAKE_CURRENT_SOURCE_DIR} with ${KDE_CLANG_FORMAT_EXECUTABLE}...")

    # run clang-format only if available, else signal the user what is missing
    if(KDE_CLANG_FORMAT_EXECUTABLE)
        foreach(_file ${ARGV})
            add_custom_command(TARGET clang-format
                COMMAND
                    ${KDE_CLANG_FORMAT_EXECUTABLE}
                    -style=file
                    -i
                    ${_file}
                WORKING_DIRECTORY
                    ${CMAKE_CURRENT_SOURCE_DIR}
                COMMENT
                    "Formatting ${_file}..."
                )
        endforeach()
    else()
        add_custom_command(TARGET clang-format
            COMMAND
                ${CMAKE_COMMAND} -E echo "Could not set up the clang-format target as the clang-format executable is missing."
            )
    endif()
endfunction()
