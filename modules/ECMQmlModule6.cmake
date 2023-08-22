#
# SPDX-FileCopyrightText: 2023 Arjen Hiemstra <ahiemstra@heimr.nl>
#
# SPDX-License-Identifier: BSD-3-Clause

# Qt 6 implementation of ECMQmlModule

include(CMakeParseArguments)

find_package(Qt6 COMPONENTS Core Qml REQUIRED CONFIG)

set(QT_QML_OUTPUT_DIRECTORY ${CMAKE_RUNTIME_OUTPUT_DIRECTORY})
qt6_policy(SET QTP0001 NEW)

function(ecm_add_qml_module ARG_TARGET)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "NO_PLUGIN;QT_NO_PLUGIN;GENERATE_PLUGIN_SOURCE" "URI;VERSION;CLASSNAME" "")

    if ("${ARG_TARGET}" STREQUAL "")
        message(FATAL_ERROR "ecm_add_qml_module called without a valid target name.")
    endif()

    if ("${ARG_URI}" STREQUAL "")
        message(FATAL_ERROR "ecm_add_qml_module called without a valid module URI.")
    endif()

    string(FIND "${ARG_URI}" " " "_space")
    if (${_space} GREATER_EQUAL 0)
        message(FATAL_ERROR "ecm_add_qml_module called without a valid module URI.")
    endif()

    set(_arguments ${ARG_TARGET} URI ${ARG_URI})

    if (ARG_VERSION)
        list(APPEND _arguments VERSION ${ARG_VERSION})
    endif()

    if (ARG_CLASSNAME)
        message(AUTHOR_WARNING "The CLASSNAME argument to ecm_add_qml_module is deprecated for Qt 6; Use CLASS_NAME instead.")
        list(APPEND _arguments CLASS_NAME ${ARG_CLASSNAME})
    endif()

    if (ARG_NO_PLUGIN)
        message(AUTHOR_WARNING "The NO_PLUGIN argument to ecm_add_qml_module is deprecated for Qt 6; For Qt 6 QML modules always require a plugin library. Use GENERATE_PLUGIN_SOURCE to do this automatically.")
    endif()

    if (ARG_QT_NO_PLUGIN)
        list(APPEND _arguments NO_PLUGIN)
    endif()

    if (NOT ARG_GENERATE_PLUGIN_SOURCE)
        list(APPEND _arguments NO_GENERATE_PLUGIN_SOURCE)
    endif()

    if (NOT TARGET ${ARG_TARGET})
        list(APPEND _arguments PLUGIN_TARGET ${ARG_TARGET})
    endif()

    if (BUILD_SHARED_LIBS)
        list(APPEND _arguments SHARED)
    else()
        list(APPEND _arguments STATIC)
    endif()

    list(APPEND _arguments ${ARG_UNPARSED_ARGUMENTS})

    qt6_add_qml_module(${_arguments})

    if (NOT MINGW)
        # KDECMakeSettings sets the prefix to empty but Qt will not load a QML
        # plugin without prefix. So we need to force it here.
        set_target_properties(${ARG_TARGET} PROPERTIES PREFIX "lib")
    endif()
endfunction()

function(ecm_add_qml_module_dependencies ARG_TARGET)
    message(AUTHOR_WARNING "ecm_add_qml_module_dependencies is deprecated for Qt 6; use the DEPENDENCIES argument to ecm_add_qml_module() instead.")
endfunction()

function(ecm_target_qml_sources ARG_TARGET)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "PRIVATE" "VERSION;PATH" "SOURCES")

    if ("${ARG_SOURCES}" STREQUAL "")
        message(FATAL_ERROR "ecm_target_qml_sources called without required argument SOURCES")
    endif()

    if (ARG_VERSION)
        set_source_files_properties(${ARG_SOURCES} PROPERTIES QT_QML_SOURCE_VERSIONS "${ARG_VERSION}")
    endif()

    if (ARG_PRIVATE)
        set_source_files_properties(${ARG_SOURCES} PROPERTIES QT_QML_INTERNAL_TYPE TRUE)
    endif()

    foreach(_path ${ARG_SOURCES})
        get_filename_component(_file "${_path}" NAME)
        set(_resource_alias "${_file}")
        if (ARG_PATH)
            set(_resource_alias "${ARG_PATH}/${_file}")
        endif()
        set_source_files_properties("${_path}" PROPERTIES QT_RESOURCE_ALIAS "${_resource_alias}")
        qt6_target_qml_sources(${ARG_TARGET} QML_FILES "${_path}" ${ARG_UNPARSED_ARGUMENTS})
    endforeach()
endfunction()

function(ecm_finalize_qml_module ARG_TARGET)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "" "DESTINATION;VERSION" "")

    if ("${ARG_DESTINATION}" STREQUAL "")
        message(FATAL_ERROR "ecm_finalize_qml_module called without required argument DESTINATION")
    endif()

    set(_version "${PROJECT_VERSION}")
    if (ARG_VERSION)
        set(_version "${ARG_VERSION}")
    endif()

    # This is effectively a workaround for missing upstream API, see QTBUG-100102

    qt6_query_qml_module(${ARG_TARGET}
        URI module_uri
        VERSION module_version
        PLUGIN_TARGET module_plugin_target
        TARGET_PATH module_target_path
        QMLDIR module_qmldir
        TYPEINFO module_typeinfo
        QML_FILES module_qml_files
        RESOURCES module_resources
    )

    set(module_dir "${ARG_DESTINATION}/${module_target_path}")

    # Install the QML module runtime loadable plugin
    install(TARGETS "${module_plugin_target}"
        LIBRARY DESTINATION "${module_dir}"
        RUNTIME DESTINATION "${module_dir}"
    )

    # Install the QML module meta information.
    install(FILES "${module_qmldir}"   DESTINATION "${module_dir}")
    install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

    # Install QML files, possibly renamed.
    list(LENGTH module_qml_files num_files)
    if (NOT "${module_qml_files}" MATCHES "NOTFOUND" AND ${num_files} GREATER 0)
        qt6_query_qml_module(${ARG_TARGET} QML_FILES_DEPLOY_PATHS qml_files_deploy_paths)

        math(EXPR last_index "${num_files} - 1")
        foreach(i RANGE 0 ${last_index})
            list(GET module_qml_files       ${i} src_file)
            list(GET qml_files_deploy_paths ${i} deploy_path)
            get_filename_component(dst_name "${deploy_path}" NAME)
            get_filename_component(dest_dir "${deploy_path}" DIRECTORY)
            install(FILES "${src_file}" DESTINATION "${module_dir}/${dest_dir}" RENAME "${dst_name}")
        endforeach()
    endif()

    # Install resources, possibly renamed.
    list(LENGTH module_resources num_files)
    if (NOT "${module_resources}" MATCHES "NOTFOUND" AND ${num_files} GREATER 0)
        qt6_query_qml_module(${ARG_TARGET} RESOURCES_DEPLOY_PATHS resources_deploy_paths)

        math(EXPR last_index "${num_files} - 1")
        foreach(i RANGE 0 ${last_index})
            list(GET module_resources       ${i} src_file)
            list(GET resources_deploy_paths ${i} deploy_path)
            get_filename_component(dst_name "${deploy_path}" NAME)
            get_filename_component(dest_dir "${deploy_path}" DIRECTORY)
            install(FILES "${src_file}" DESTINATION "${module_dir}/${dest_dir}" RENAME "${dst_name}")
        endforeach()
    endif()

    file(GENERATE OUTPUT "${CMAKE_CURRENT_BINARY_DIR}/kde-qmlmodule.version" CONTENT "${_version}\n")
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/kde-qmlmodule.version" DESTINATION "${module_dir}")
endfunction()