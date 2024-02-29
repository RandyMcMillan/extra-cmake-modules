# SPDX-FileCopyrightText: 2024 DOAN Tran Cong Danh <congdanhqx@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

#[=======================================================================[.rst:
FindQHelpGenerator
------------------------

Try to find the Qt help generator.

This will define the following variables:

``QHelpGenerator_FOUND``
True if (the requested version of) QHelpGenerator is available
``QHelpGenerator_VERSION``
    The version of the Qt help generator. Note that this not the
    same as the version of Qt it is provided by.
``QHelpGenerator_QT_VERSION``
    The version of Qt that the Qt help generator is from.
``QHelpGenerator_EXECUTABLE``
    The path to the Qt help generator executable.

If ``QHelpGenerator_FOUND`` is TRUE, it will also define the following
imported target:

``QHelpGenerator::Generator``
    The Qt help generator.

In general we recommend using the imported target, as it is easier to use.

Since 6.0.0.
#]=======================================================================]

include(${CMAKE_CURRENT_LIST_DIR}/../modules/ECMQueryQt.cmake)

if (BUILD_WITH_QT6)
    ecm_query_qt(qhelpgenerator_dir QT_HOST_LIBEXECS)
else()
    ecm_query_qt(qhelpgenerator_dir QT_HOST_BINS)
endif()

find_program(QHelpGenerator_EXECUTABLE
    NAMES
        qhelpgenerator
    HINTS ${qhelpgenerator_dir}
    DOC "Qt help generator"
)

if (QHelpGenerator_EXECUTABLE)
    if(NOT TARGET QHelpGenerator::Generator)
        add_executable(QHelpGenerator::Generator IMPORTED)
        set_target_properties(QHelpGenerator::Generator PROPERTIES
            IMPORTED_LOCATION "${QHelpGenerator_EXECUTABLE}"
        )
    endif()

    execute_process(
        COMMAND "${QHelpGenerator_EXECUTABLE}" -v
        OUTPUT_VARIABLE _QHelpGenerator_version_raw
        ERROR_VARIABLE _QHelpGenerator_version_raw
    )
    if (_QHelpGenerator_version_raw MATCHES "^Qt Help Generator version ([0-9]+(\\.[0-9]+)*) \\(Qt ([0-9]+(\\.[0-9]+)*)\\)")
        set(QHelpGenerator_VERSION "${CMAKE_MATCH_1}")
        set(QHelpGenerator_QT_VERSION "${CMAKE_MATCH_3}")
    endif()
    unset(_QHelpGenerator_version_raw)
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(QHelpGenerator
    FOUND_VAR
        QHelpGenerator_FOUND
    REQUIRED_VARS
        QHelpGenerator_EXECUTABLE
    VERSION_VAR
        QHelpGenerator_VERSION
)

mark_as_advanced(QHelpGenerator_EXECUTABLE)
