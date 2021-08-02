#
# SPDX-FileCopyrightText: 2021 Arjen Hiemstra <ahiemstra@heimr.nl>
#
# SPDX-License-Identifier: BSD-3-Clause

message(DEPRECATION "ECMQMLModules.cmake is deprecated since 5.86.0, please use ECMFindQmlModule.cmake instead")
include(ECMFindQmlModule.cmake)
