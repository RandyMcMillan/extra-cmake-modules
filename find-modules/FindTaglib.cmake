#.rst:
# FindTaglib
#-----------
#
# Try to find the Taglib library.
#
# This will define the following variables:
#
# ``Taglib_FOUND``
#       True if the system has the taglib library of at least the minimum
#       version specified by the version parameter to find_package()
# ``Taglib_INCLUDE_DIRS``
#       The taglib include dirs for use with target_include_directories
# ``Taglib_LIBRARIES``
#       The taglib libraries for use with target_link_libraries()
# ``Taglib_VERSION``
#       The version of taglib that was found
#
# If ``Taglib_FOUND is TRUE, it will also define the following imported
# target:
#
# ``Taglib::Taglib``
#       The Taglib library
#
# Since 5.72.0
#
# SPDX-FileCopyrightText: 2006 Laurent Montel <montel@kde.org>
# SPDX-FileCopyrightText: 2019 Heiko Becker <heirecka@exherbo.org>
# SPDX-FileCopyrightText: 2020 Elvis Angelaccio <elvis.angelaccio@kde.org>
# SPDX-License-Identifier: BSD-3-Clause

if(NOT WIN32)
    find_program(TaglibConfig_EXECUTABLE NAMES taglib-config)
endif()

if(TaglibConfig_EXECUTABLE)
    execute_process(COMMAND ${TaglibConfig_EXECUTABLE} --version
        OUTPUT_VARIABLE TC_Taglib_VERSION
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    execute_process(COMMAND ${TaglibConfig_EXECUTABLE} --libs
        OUTPUT_VARIABLE TC_Taglib_LIBRARIES
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    execute_process(COMMAND ${TaglibConfig_EXECUTABLE} --cflags
        OUTPUT_VARIABLE TC_Taglib_CFLAGS
        OUTPUT_STRIP_TRAILING_WHITESPACE
    )

    set(Taglib_VERSION ${TC_Taglib_VERSION})
    set(Taglib_LIBRARIES ${TC_Taglib_LIBRARIES})
    set(Taglib_CFLAGS ${TC_Taglib_CFLAGS})
    string(REGEX REPLACE " *-I" ";" Taglib_INCLUDE_DIRS "${Taglib_CFLAGS}")

    if (Taglib_INCLUDE_DIRS AND NOT Taglib_VERSION)
        if(EXISTS "${Taglib_INCLUDE_DIRS}/taglib/taglib.h")
            file(READ "${Taglib_INCLUDE_DIRS}/taglib/taglib.h" TAGLIB_H)
            string(REGEX MATCH "#define TAGLIB_MAJOR_VERSION[ ]+[0-9]+" TAGLIB_MAJOR_VERSION_MATCH)
            string(REGEX MATCH "#define TAGLIB_MINOR_VERSION[ ]+[0-9]+" TAGLIB_MINOR_VERSION_MATCH)
            string(REGEX MATCH "#define TAGLIB_PATCH_VERSION[ ]+[0-9]+" TAGLIB_PATCH_VERSION_MATCH)

            string(REGEX REPLACE ".*_MAJOR[ ]+(.*)" "\\1" TAGLIB_MAJOR_VERSION ${TAGLIB_MAJOR_VERSION_MATCH})
            string(REGEX REPLACE ".*_MINOR[ ]+(.*)" "\\1" TAGLIB_MINOR_VERSION ${TAGLIB_MINOR_VERSION_MATCH})
            string(REGEX REPLACE ".*_PATCH[ ]+(.*)" "\\1" TAGLIB_PATCH_VERSION ${TAGLIB_PATCH_VERSION_MATCH})

            set(Taglib_VERSION "${TAGLIB_MAJOR_VERSION}.${TAGLIB_MINOR_VERSION}.${TAGLIB_PATCH_VERSION}")
        endif()
    endif()

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(Taglib
        FOUND_VAR
            Taglib_FOUND
        REQUIRED_VARS
            Taglib_LIBRARIES
            Taglib_INCLUDE_DIRS
        VERSION_VAR
            Taglib_VERSION
    )

    # Deprecated synonyms
    set(TAGLIB_CFLAGS "${Taglib_CFLAGS}")
    set(TAGLIB_INCLUDES "${Taglib_INCLUDE_DIRS}")
    set(TAGLIB_LIBRARIES "${Taglib_LIBRARIES}")
    set(TAGLIB_FOUND "${Taglib_FOUND}")

    if (Taglib_FOUND AND NOT TARGET Taglib::Taglib)
        add_library(Taglib::Taglib UNKNOWN IMPORTED)
        set_target_properties(Taglib::Taglib PROPERTIES
            IMPORTED_LOCATION "${Taglib_LIBRARIES}"
            INTERFACE_COMPILE_OPTIONS "${Taglib_CFLAGS}"
            INTERFACE_INCLUDE_DIRECTORIES "${Taglib_INCLUDE_DIRS}"
        )
    endif()

    mark_as_advanced(Taglib_CFLAGS Taglib_LIBRARIES Taglib_INCLUDE_DIRS)
else()
    find_path(TAGLIB_INCLUDES
        NAMES tag.h
        PATHS ${INCLUDE_INSTALL_DIR}
    )

    find_library(TAGLIB_LIBRARIES
        NAMES tag
        PATHS ${LIB_INSTALL_DIR}
    )

    include(FindPackageHandleStandardArgs)
    find_package_handle_standard_args(Taglib
        DEFAULT_MSG
        TAGLIB_INCLUDES
        TAGLIB_LIBRARIES
    )

    mark_as_advanced(TAGLIB_LIBRARIES TAGLIB_INCLUDES)
endif()

include(FeatureSummary)
set_package_properties(Taglib PROPERTIES
    URL "https://taglib.org/"
    DESCRIPTION "A library for reading and editing the meta-data of audio formats"
)
