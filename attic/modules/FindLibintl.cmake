# Try to find Libintl functionality
# Once done this will define
#
#  LIBINTL_FOUND - system has Libintl
#  LIBINTL_INCLUDE_DIR - Libintl include directory
#  LIBINTL_LIBRARIES - Libraries needed to use Libintl
#
# TODO: This will enable translations only if Gettext functionality is
# present in libc. Must have more robust system for release, where Gettext
# functionality can also reside in standalone Gettext library, or the one
# embedded within kdelibs (cf. gettext.m4 from Gettext source).

# SPDX-FileCopyrightText: 2006 Chusslove Illich <caslav.ilic@gmx.net>
# SPDX-FileCopyrightText: 2007 Alexander Neundorf <neundorf@kde.org>
#
# SPDX-License-Identifier: BSD-3-Clause

if(LIBINTL_INCLUDE_DIR AND LIBINTL_LIB_FOUND)
  set(Libintl_FIND_QUIETLY TRUE)
endif()

find_path(LIBINTL_INCLUDE_DIR libintl.h)

set(LIBINTL_LIB_FOUND FALSE)

if(LIBINTL_INCLUDE_DIR)
  include(CheckFunctionExists)
  check_function_exists(dgettext LIBINTL_LIBC_HAS_DGETTEXT)

  if (LIBINTL_LIBC_HAS_DGETTEXT)
    set(LIBINTL_LIBRARIES)
    set(LIBINTL_LIB_FOUND TRUE)
  else (LIBINTL_LIBC_HAS_DGETTEXT)
    find_library(LIBINTL_LIBRARIES NAMES intl libintl )
    if(LIBINTL_LIBRARIES)
      set(LIBINTL_LIB_FOUND TRUE)
    endif()
  endif (LIBINTL_LIBC_HAS_DGETTEXT)

endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(Libintl  DEFAULT_MSG  LIBINTL_INCLUDE_DIR  LIBINTL_LIB_FOUND)

mark_as_advanced(LIBINTL_INCLUDE_DIR  LIBINTL_LIBRARIES  LIBINTL_LIBC_HAS_DGETTEXT  LIBINTL_LIB_FOUND)
