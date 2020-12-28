#.rst:
# KDECommitKooks
# --------------------
#
# This module provides a functionality to enforce formatting
# or in the future other QS checks.
#
# This module provides the following function:
#
# ::
#
#   kde_clang_format(CHECKS CLANG_FORMAT)
#
# This function will create a pre-commit hook which contains all the given checks.
# In case the source dir does not contain the .git folder, the GIT_DIR
# parameter can be passed in.
#
# Example usage:
#
# .. code-block:: cmake
#
#   include(KDECommitHooks)
#   kde_configure_pre_commit_hook(CHECKS CLANG_FORMAT)
#
# Since 5.78

#=============================================================================
# SPDX-FileCopyrightText: 2020 Alexander Lohnau <alexander.lohnau@gmx.de>
#
# SPDX-License-Identifier: BSD-3-Clause

# try to find clang-format in path
find_program(KDE_CLANG_FORMAT_EXECUTABLE clang-format)
include(CMakeParseArguments)
set(PRE_COMMIT_HOOK_UNIX "${CMAKE_CURRENT_LIST_DIR}/kde-commit-hooks/pre-commit.cmake")
set(CLANG_FORMAT_UNIX "${CMAKE_CURRENT_LIST_DIR}/kde-commit-hooks/clang-format.sh.cmake")

function(KDE_CONFIGURE_PRE_COMMIT_HOOK)
    set(_oneValueArgs GIT_DIR)
    set(_multiValueArgs CHECKS)
    cmake_parse_arguments(ARG "" "${_oneValueArgs}" "${_multiValueArgs}" ${ARGN} )

    if(NOT ARG_CHECKS)
        message(FATAL_ERROR "No checks were specified")
    endif()
    if(NOT ARG_GIT_DIR)
        set(ARG_GIT_DIR "${CMAKE_SOURCE_DIR}/.git")
    endif()

    # In case of tarballs there is no .git directory
    if (EXISTS ${ARG_GIT_DIR})
        # The pre-commit hook is a bash script, consequently it won't work on non-unix platforms
        if (UNIX)
            configure_file(${PRE_COMMIT_HOOK_UNIX} "${ARG_GIT_DIR}/hooks/pre-commit" COPYONLY)
            configure_file(${CLANG_FORMAT_UNIX} "${ARG_GIT_DIR}/hooks/pre-commit-dir/clang-format.sh" COPYONLY)
            list(FIND ARG_CHECKS "CLANG_FORMAT" _index)
            if (${_index} GREATER -1)
                file(APPEND "${ARG_GIT_DIR}/hooks/pre-commit" "'${ARG_GIT_DIR}/hooks/pre-commit-dir/clang-format.sh'\n")
            endif()
        endif()
    endif()
endfunction()