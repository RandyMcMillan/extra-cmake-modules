# SPDX-FileCopyrightText: 2021 Alexander Lohnau <alexander.lohnau@gmx.de>
# SPDX-License-Identifier: BSD-3-Clause

set PATH "@KDE_INSTALL_FULL_BINDIR@:$PATH"

# LD_LIBRARY_PATH only needed if you are building without rpath
# set --path  LD_LIBRARY_PATH @KDE_INSTALL_FULL_LIBDIR@ $LD_LIBRARY_PATH

if set -q XDG_DATA_DIRS
    set -x XDG_DATA_DIRS "/usr/local/share/:/usr/share/"
end
set -x XDG_DATA_DIRS "@KDE_INSTALL_FULL_DATADIR@:$XDG_DATA_DIRS"

if set -q XDG_CONFIG_DIRS
    set -x XDG_CONFIG_DIRS "/etc/xdg"
end
set -x XDG_CONFIG_DIRS "@KDE_INSTALL_FULL_CONFDIR@:$XDG_CONFIG_DIRS"

set -x QT_PLUGIN_PATH "@KDE_INSTALL_FULL_QTPLUGINDIR@:$QT_PLUGIN_PATH"
set -x QML2_IMPORT_PATH "@KDE_INSTALL_FULL_QMLDIR@:$QML2_IMPORT_PATH"

set -x QT_QUICK_CONTROLS_STYLE_PATH "@KDE_INSTALL_FULL_QMLDIR@/QtQuick/Controls.2/:$QT_QUICK_CONTROLS_STYLE_PATH"
