# SPDX-FileCopyrightText: 2021 Ahmad Samir <a.samirh78@gmail.com>
#
# SPDX-License-Identifier: BSD-3-Clause

#[=======================================================================[.rst:

FindLibMount
------------

Try to find the libmount library (part of util-linux), once done this will define:

``LibMount_FOUND``
    System has LibMount.

``LibMount_INCLUDE_DIRS``
    The libudev include directory.

``LibMount_LIBRARIES``
    The libudev libraries.

``LibMount_VERSION``
    The libudev version.

If ``LibMount_FOUND`` is TRUE, it will also define the following imported target:

``LibMount::LibMount``
    The libmount library

Since 5.83.0
#]=======================================================================]

find_package(PkgConfig QUIET)
pkg_check_modules(PC_LIBMOUNT QUIET mount)

find_path(LibMount_INCLUDE_DIRS NAMES libmount.h HINTS ${PC_LIBMOUNT_INCLUDE_DIRS})
find_library(LibMount_LIBRARIES NAMES mount HINTS ${PC_LIBMOUNT_LIBRARY_DIRS})

set(LibMount_VERSION ${PC_LIBMOUNT_VERSION})

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LibMount
    FOUND_VAR LibMount_FOUND
    REQUIRED_VARS LibMount_INCLUDE_DIRS LibMount_LIBRARIES
    VERSION_VAR LibMount_VERSION
)

mark_as_advanced(LibMount_INCLUDE_DIRS LibMount_LIBRARIES)

if(LibMount_FOUND AND NOT TARGET LibMount::LibMount)
    add_library(LibMount::LibMount UNKNOWN IMPORTED)
    set_target_properties(LibMount::LibMount PROPERTIES
        IMPORTED_LOCATION "${LibMount_LIBRARIES}"
        INTERFACE_INCLUDE_DIRECTORIES "${LibMount_INCLUDE_DIRS}"
        INTERFACE_COMPILE_DEFINITIONS "${PC_LIBMOUNT_CFLAGS_OTHER}"
    )
endif()

include(FeatureSummary)
set_package_properties(LibMount PROPERTIES
    DESCRIPTION "API for getting info about mounted filesystems (part of util-linux)"
    URL "https://www.kernel.org/pub/linux/utils/util-linux/"
)
