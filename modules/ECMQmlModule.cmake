#
# SPDX-FileCopyrightText: 2021 Arjen Hiemstra <ahiemstra@heimr.nl>
#
# SPDX-License-Identifier: BSD-3-Clause

#[========================================================================[.rst:
ECMQmlModule
------------

This file contains helper functions to make it easier to create QML modules. It
takes care of a number of things that often need to be repeated. It also takes
care of special handling of QML modules between shared and static builds. When
building a static version of a QML module, the relevant QML source files are
bundled into the static library. When using a shared build, the QML plugin and
relevant QML files are copied to ``CMAKE_BINARY_DIR/bin`` to make it easier to
run things directly from the build directory.

Example usage:

.. code-block:: cmake

    ecm_add_qml_module(ExampleModule URI "org.example.Example" VERSION 1.4)

    target_sources(ExampleModule ExamplePlugin.cpp)

    ecm_target_qml_sources(ExampleModule SOURCES ExampleItem.qml)
    ecm_target_qml_sources(ExampleModule SOURCES AnotherExampleItem.qml VERSION 1.5)

    ecm_finalize_qml_module(ExampleModule DESTINATION ${KDE_INSTALL_QMLDIR})


::
    ecm_add_qml_module(<target name> [NO_PLUGIN] URI <module uri> [VERSION <module version>])

This will declare a new CMake target called ``<target name>``. The ``URI``
argument is required and should be a proper QML module URI.

If the ``VERSION`` argument is specified, it is used to initialize the default
version that is used by  ``ecm_target_qml_sources`` when adding QML files. If it
is not specified, a  default of 1.0 is used.

If the option ``NO_PLUGIN`` is set, a target is declared that is not expected to
contain any C++ QML plugin.

You can add C++ and QML source files to the target using ``target_sources`` and
``ecm_target_qml_sources``, respectively.

Since 5.86.0

::
    ecm_target_qml_sources(<target> SOURCES <source.qml> [<source.qml> ...] [VERSION <version>])

Add the list of QML files specified by the ``SOURCES`` argument as source files
to the QML module target ``<target>``.

If the optional ``VERSION`` argument is specified, all QML files will be added
with the specified version. If it is not specified, they will use the version of
the QML module target.

This function will fail if ``<target>`` is not a QML module target.

Since 5.86.0

::
    ecm_finalize_qml_module(<target> DESTINATION <QML install destination>)

Finalize the specified QML module target. This must be called after all other
setup (like adding sources) on the target has been done. It will perform a
number of tasks:

- It will generate a qmldir file from the QML files added to the target. If the
  module has a C++ plugin, this will also be included in the qmldir file.
- If ``BUILD_SHARED_LIBS`` is off, a QRC file is generated from the QML files
  added to the target. This QRC file will be included when compiling the C++ QML
  module. The built static library will be installed in a subdirection of
  ``DESTINATION`` based on the QML module's uri. Note that if ``NO_PLUGIN`` is
  set, a C++ QML plugin will be generated to include the QRC files.
- If ``BUILD_SHARED_LIBS`` in on, all generated files, QML sources and the C++
  plugin will be installed in a subdirectory of ``DESTINATION`` based upon the
  QML module's uri. In addition, these files will also be copied to
  ``${CMAKE_BINARY_DIR}/bin`` in a similar subdirectory.

This function will fail if ``<target>`` is not a QML module target.

Since 5.86.0

#]========================================================================]

include(CMakeParseArguments)

set(_ECM_QMLMODULE_STATIC_QMLONLY_H   "${CMAKE_CURRENT_LIST_DIR}/ECMQmlModule.h.in")
set(_ECM_QMLMODULE_STATIC_QMLONLY_CPP "${CMAKE_CURRENT_LIST_DIR}/ECMQmlModule.cpp.in")

macro(_verify_qml_target ARG_TARGET)
    if (NOT TARGET ${ARG_TARGET})
        message(FATAL_ERROR "Target ${ARG_TARGET} does not exist")
    endif()
    get_target_property(_qml_uri ${ARG_TARGET} "_ecm_qml_uri")
    if ("${_qml_uri}" STREQUAL "" OR "${_qml_uri}" STREQUAL "_ecm_qml_uri-NOTFOUND")
        message(FATAL_ERROR "Target ${ARG_TARGET} is not a QML plugin target")
    endif()
endmacro()

function(_generate_qmldir ARG_TARGET)
    get_target_property(_qml_uri ${ARG_TARGET} "_ecm_qml_uri")
    get_target_property(_qml_files ${ARG_TARGET} "_ecm_qml_files")
    get_target_property(_qml_only ${ARG_TARGET} "_ecm_qml_only")

    set(_qmldir_template "module ${_qml_uri}")

    if (NOT ${_qml_only})
        string(APPEND _qmldir_template "\nplugin ${ARG_TARGET}")
    endif()

    foreach(_file ${_qml_files})
        get_filename_component(_filename ${_file} NAME)
        get_filename_component(_classname ${_file} NAME_WE)
        get_property(_version SOURCE ${_file} PROPERTY _ecm_qml_version)
        string(APPEND _qmldir_template "\n${_classname} ${_version} ${_filename}")
    endforeach()

    string(APPEND _qmldir_template "\n")

    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_qmldir" "${_qmldir_template}")
    set_target_properties(${ARG_TARGET} PROPERTIES _ecm_qmldir_file "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}_qmldir")
endfunction()

function(_generate_qrc ARG_TARGET)
    get_target_property(_qml_uri ${ARG_TARGET} "_ecm_qml_uri")
    get_target_property(_qml_files ${ARG_TARGET} "_ecm_qml_files")
    get_target_property(_qmldir_file ${ARG_TARGET} "_ecm_qmldir_file")

    string(REPLACE "." "/" _qml_prefix ${_qml_uri})

    set(_qrc_template "<RCC>\n<qresource prefix=\"${_qml_prefix}\">\n<file alias=\"qmldir\">${_qmldir_file}</file>")

    foreach(_file ${_qml_files})
        get_filename_component(_filename ${_file} NAME)
        string(APPEND _qrc_template "\n<file alias=\"${_filename}\">${_file}</file>")
    endforeach()

    string(APPEND _qrc_template "\n</qresource>\n</RCC>\n")

    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.qrc" "${_qrc_template}")
    qt_add_resources(_qrc_output "${CMAKE_CURRENT_BINARY_DIR}/${ARG_TARGET}.qrc")

    target_sources(${ARG_TARGET} PRIVATE ${_qrc_output})
endfunction()

function(ecm_add_qml_module ARG_TARGET)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "NO_PLUGIN" "URI;VERSION" "")

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

    if (${BUILD_SHARED_LIBS} AND ${ARG_NO_PLUGIN})
        # CMake doesn't like library targets without sources, so if we have no
        # C++ sources, use a plain target that we can add all the install stuff
        # to.
        add_custom_target(${ARG_TARGET} ALL)
    else()
        add_library(${ARG_TARGET})
    endif()

    if ("${ARG_VERSION}" STREQUAL "")
        set(ARG_VERSION "1.0")
    endif()

    set_target_properties(${ARG_TARGET} PROPERTIES
        _ecm_qml_uri "${ARG_URI}"
        _ecm_qml_files ""
        _ecm_qml_only "${ARG_NO_PLUGIN}"
        _ecm_qml_version "${ARG_VERSION}"
    )
endfunction()

function(ecm_target_qml_sources ARG_TARGET)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "" "VERSION" "SOURCES")

    _verify_qml_target(${ARG_TARGET})

    if ("${ARG_SOURCES}" STREQUAL "")
        message(FATAL_ERROR "ecm_target_qml_sources called without required argument SOURCES")
    endif()

    if ("${ARG_VERSION}" STREQUAL "")
        get_target_property(ARG_VERSION ${ARG_TARGET} "_ecm_qml_version")
    endif()

    foreach(_file ${ARG_SOURCES})
        set_property(SOURCE ${_file} PROPERTY _ecm_qml_version "${ARG_VERSION}")
        set_property(TARGET ${ARG_TARGET} APPEND PROPERTY _ecm_qml_files ${CMAKE_CURRENT_SOURCE_DIR}/${_file})
    endforeach()
endfunction()

function(ecm_finalize_qml_module ARG_TARGET)
    cmake_parse_arguments(PARSE_ARGV 1 ARG "" "DESTINATION" "")

    _verify_qml_target(${ARG_TARGET})

    if ("${ARG_DESTINATION}" STREQUAL "")
        message(FATAL_ERROR "ecm_finalize_qml_module called without required argument DESTINATION")
    endif()

    _generate_qmldir(${ARG_TARGET})

    get_target_property(_qml_uri ${ARG_TARGET} "_ecm_qml_uri")
    string(REPLACE "." "/" _plugin_path "${_qml_uri}")

    get_target_property(_qml_only ${ARG_TARGET} "_ecm_qml_only")

    if (NOT BUILD_SHARED_LIBS)
        _generate_qrc(${ARG_TARGET})

        if (${_qml_only})
            # If we do not have any C++ sources for the target, we need a way to
            # compile the generated QRC file. So generate a very plain C++ QML
            # plugin that we include in the target.
            configure_file(${_ECM_QMLMODULE_STATIC_QMLONLY_H} ${CMAKE_CURRENT_BINARY_DIR}/QmlModule.h @ONLY)
            configure_file(${_ECM_QMLMODULE_STATIC_QMLONLY_CPP} ${CMAKE_CURRENT_BINARY_DIR}/QmlModule.cpp @ONLY)

            target_sources(${ARG_TARGET} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/QmlModule.cpp)
            target_link_libraries(${ARG_TARGET} PRIVATE Qt::Qml)
        endif()

        install(TARGETS ${ARG_TARGET} DESTINATION ${ARG_DESTINATION}/${_plugin_path})

        return()
    endif()

    add_custom_command(
        TARGET ${ARG_TARGET}
        POST_BUILD
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/bin/
        COMMAND ${CMAKE_COMMAND} -E make_directory ${_plugin_path}
        BYPRODUCTS ${CMAKE_BINARY_DIR}/bin/${_plugin_path}
    )

    get_target_property(_qmldir_file ${ARG_TARGET} "_ecm_qmldir_file")
    install(FILES ${_qmldir_file} DESTINATION ${ARG_DESTINATION}/${_plugin_path} RENAME "qmldir")

    add_custom_command(
        TARGET ${ARG_TARGET}
        POST_BUILD
        WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/bin/
        COMMAND ${CMAKE_COMMAND} -E copy ${_qmldir_file} ${_plugin_path}/qmldir
    )

    if (NOT ${_qml_only})
        install(TARGETS ${ARG_TARGET} DESTINATION ${ARG_DESTINATION}/${_plugin_path})

        add_custom_command(
            TARGET ${ARG_TARGET}
            POST_BUILD
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/bin/
            COMMAND ${CMAKE_COMMAND} -E copy $<TARGET_FILE:${ARG_TARGET}> ${_plugin_path}
        )
    endif()

    get_target_property(_qml_files ${ARG_TARGET} "_ecm_qml_files")
    install(FILES ${_qml_files} DESTINATION ${ARG_DESTINATION}/${_plugin_path})

    list(LENGTH _qml_files _qml_file_count)
    if (${_qml_file_count} GREATER 0)
        add_custom_command(
            TARGET ${ARG_TARGET}
            POST_BUILD
            WORKING_DIRECTORY ${CMAKE_BINARY_DIR}/bin/
            COMMAND ${CMAKE_COMMAND} -E copy ${_qml_files} ${_plugin_path}
        )
    endif()
endfunction()
