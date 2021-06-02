# SPDX-FileCopyrightText: 2021 Carson Black <uhhadd@gmail.com>
# SPDX-License-Identifier: BSD-3-Clause

_kde_helper = [lhs rhs]{
    if (eq $lhs "") {
        put $rhs
    } else {
        put $lhs
    }
}

E:PATH = @KDE_INSTALL_FULL_BINDIR@:$E:PATH

# LD_LIBRARY_PATH only needed if you are building without rpath
# E:LD_LIBRARY_PATH = @KDE_INSTALL_FULL_LIBDIR@:$E:LD_LIBRARY_PATH

E:XDG_DATA_DIRS = @KDE_INSTALL_FULL_DATADIR@:($_kde_helper $E:XDG_DATA_DIRS "/usr/local/share/:/usr/share/")
E:XDG_CONFIG_DIRS = @KDE_INSTALL_FULL_CONFDIR@:($_kde_helper $E:XDG_CONFIG_DIRS "/etc/xdg")

E:QT_PLUGIN_PATH = @KDE_INSTALL_FULL_QTPLUGINDIR@:$E:QT_PLUGIN_PATH
E:QML2_IMPORT_PATH = @KDE_INSTALL_FULL_QMLDIR@:$E:QML2_IMPORT_PATH

E:QT_QUICK_CONTROLS_STYLE_PATH = @KDE_INSTALL_FULL_QMLDIR@/QtQuick/Controls.2/:$E:QT_QUICK_CONTROLS_STYLE_PATH

del _kde_helper
