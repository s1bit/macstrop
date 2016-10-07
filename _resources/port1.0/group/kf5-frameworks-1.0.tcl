# -*- coding: utf-8; mode: tcl; c-basic-offset: 4; indent-tabs-mode: nil; tab-width: 4; truncate-lines: t -*- vim:fenc=utf-8:et:sw=4:ts=4:sts=4
# $Id: kf5-frameworks-1.0.tcl 134210 2015-03-20 06:40:18Z mk@macports.org $

# Copyright (c) 2015 The MacPorts Project
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are
# met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. Neither the name of Apple Computer, Inc. nor the names of its
#    contributors may be used to endorse or promote products derived from
#    this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
# "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
# LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
# A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
# OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
# SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
# LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
# DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
# THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
# OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#
# Usage:
# PortGroup     kf5-frameworks 1.0
#
# This PortGroup provides the required macros to declare dependencies
# on KF5 Frameworks for ports that cannot easily use the main KF5 1.1
# PortGroup, for instance because they don't use CMake. Typically this
# will be ports providing software not provided through/for the KDE
# organisation, for example Qt applications that use just a select
# number of frameworks (like QupZilla can provide a KWallet backend).

# variables to facilitate setting up dependencies to KF5 frameworks that may (or not)
# also exist as port:kf5-foo-devel .
# This may be extended to provide path-style *runtime* dependencies on framework executables;
# kf5.framework_runtime_dependency{name {executable 0}} and kf5.depends_run_frameworks
# (which would have to add a library dependency if no executable dependency is defined).
proc kf5.framework_dependency {name {library 0} {soversion 5}} {
    upvar #0 kf5.${name}_dep dep
    upvar #0 kf5.${name}_lib lib
    if {${library} ne 0} {
        global os.platform build_arch
        if {${os.platform} eq "darwin"} {
            set kf5.lib_path    lib
            if {${soversion} ne ""} {
                set kf5.lib_ext 5.dylib
            } else {
                set kf5.lib_ext dylib
            }
        } elseif {${os.platform} eq "linux"} {
            set kf5.lib_path    lib/${build_arch}-linux-gnu
            if {${soversion} ne ""} {
                set kf5.lib_ext so.5
            } else {
                set kf5.lib_ext so
            }
        }
        set lib                 ${kf5.lib_path}/${library}.${kf5.lib_ext}
        set dep                 path:${lib}:kf5-${name}
        ui_debug "Dependency expression for KF5ramework ${name}: ${dep}"
    } else {
        if {[info exists dep]} {
            return ${dep}
        } else {
            set allknown [info global "kf5.*_dep"]
            ui_error "No KF5 framework is known corresponding to \"${name}\""
            ui_msg "Known framework ports: ${allknown}"
            return -code error "Unknown KF5 framework ${name}"
        }
    }
}

proc kf5.has_translations {} {
    global kf5.pythondep
    global kf5.pyversion
    global prefix
    ui_debug "Adding gettext and ${kf5.pythondep} build dependencies because of KI18n"
    depends_build-append \
                        port:gettext \
                        ${kf5.pythondep}
    configure.args-append \
                        -DPYTHON_EXECUTABLE=${prefix}/bin/python${kf5.pyversion}
}


# kf5.depends_frameworks appends the ports corresponding to the KF5 Frameworks
# short names to depends_lib
# This procedure also adds the build dependencies that KI18n imposes
# Caution though: some KF5 packages will let the KI18n dependency be added
# through cmake's public link interface handling, rather than declaring an
# explicit dependency themselves that is listed in the printed summary.
proc kf5.depends_frameworks {first args} {
    # join ${first} and (the optional) ${args}
    set args [linsert $args[set list {}] 0 ${first}]
    foreach f ${args} {
        set kdep [kf5.framework_dependency ${f}]
        if {![catch {set nativeQSP [active_variants "${kdep}" nativeQSP]}]} {
            global subport
            if {${nativeQSP}} {
                # dependency is built for native QSP locations but the dependent port wants ALT (XDG) locations
                if {([variant_isset qspXDG] || ![variant_isset nativeQSP])} {
                    ui_msg "Warning: ${subport} potential mismatch with kf5-${f}+nativeQSP"
                }
            } elseif {[variant_isset nativeQSP]} {
                # dependency is built for ALT (XDG) QSP locations but the dependent port wants to use native locations
                ui_msg "Warning: ${subport}+nativeQSP potential mismatch with kf5-${f} (-nativeQSP)"
            }
        }
        depends_lib-append \
                        ${kdep}
        platform darwin {
            if {[lsearch {"baloo" "kactivities" "kdbusaddons" "kded" "kdelibs4support-devel" "kglobalaccel" "kio"
                            "kservice" "kwallet" "kwalletmanager" "plasma-framework"} ${f}] ne "-1"} {
                notes "
                    Don't forget that dbus needs to be started as the local\
                    user (not with sudo) before any KDE programs will launch.
                    To start it run the following command:
                     launchctl load -w /Library/LaunchAgents/org.freedesktop.dbus-session.plist
                    "
            }
        }
    }
    if {[lsearch -exact ${args} "ki18n"] ne "-1"} {
        kf5.has_translations
    }
}

# the equivalent to kf5.depends_frameworks for declaring build dependencies.
proc kf5.depends_build_frameworks {first args} {
    # join ${first} and (the optional) ${args}
    set args [linsert $args[set list {}] 0 ${first}]
    foreach f ${args} {
        depends_build-append \
                        [kf5.framework_dependency ${f}]
    }
    if {[lsearch -exact ${args} "ki18n"] ne "-1"} {
        kf5.has_translations
    }
}

kf5.framework_dependency    attica libKF5Attica
kf5.framework_dependency    karchive libKF5Archive
kf5.framework_dependency    kcoreaddons libKF5CoreAddons
kf5.framework_dependency    kauth libKF5Auth
kf5.framework_dependency    kconfig libKF5ConfigCore
kf5.framework_dependency    kcodecs libKF5Codecs
kf5.framework_dependency    ki18n libKF5I18n
# kf5-kdoctools does install a static library but I don't know if it has dependents
set kf5.kdoctools_dep       path:bin/meinproc5:kf5-kdoctools
kf5.framework_dependency    kguiaddons libKF5GuiAddons
kf5.framework_dependency    kwidgetsaddons libKF5WidgetsAddons
kf5.framework_dependency    kconfigwidgets libKF5ConfigWidgets
kf5.framework_dependency    kitemviews libKF5ItemViews
kf5.framework_dependency    kiconthemes libKF5IconThemes
kf5.framework_dependency    kwindowsystem libKF5WindowSystem
kf5.framework_dependency    kcrash libKF5Crash
set kf5.kapidox_dep         path:bin/kgenapidox:kf5-kapidox
kf5.framework_dependency    kdbusaddons libKF5DBusAddons
kf5.framework_dependency    kdnssd libKF5DNSSD
kf5.framework_dependency    kidletime libKF5IdleTime
set kf5.kimageformats_dep   port:kf5-kimageformats
kf5.framework_dependency    kitemmodels libKF5ItemModels
kf5.framework_dependency    kplotting libKF5Plotting
set kf5.oxygen-icons_dep    path:share/icons/oxygen/index.theme:kf5-oxygen-icons5
kf5.framework_dependency    solid libKF5Solid
kf5.framework_dependency    sonnet libKF5SonnetCore
kf5.framework_dependency    threadweaver libKF5ThreadWeaver
kf5.framework_dependency    kcompletion libKF5Completion
kf5.framework_dependency    kfilemetadata libKF5FileMetaData
kf5.framework_dependency    kjobwidgets libKF5JobWidgets
kf5.framework_dependency    knotifications libKF5Notifications
kf5.framework_dependency    kunitconversion libKF5UnitConversion
kf5.framework_dependency    kpackage libKF5Package
kf5.framework_dependency    kservice libKF5Service
kf5.framework_dependency    ktextwidgets libKF5TextWidgets
kf5.framework_dependency    kglobalaccel libKF5GlobalAccel
kf5.framework_dependency    kxmlgui libKF5XmlGui
kf5.framework_dependency    kbookmarks libKF5Bookmarks
kf5.framework_dependency    kwallet libKF5Wallet
kf5.framework_dependency    kio libKF5KIOCore
kf5.framework_dependency    baloo libKF5Baloo
kf5.framework_dependency    kdeclarative libKF5Declarative
kf5.framework_dependency    kcmutils libKF5KCMUtils
kf5.framework_dependency    kemoticons libKF5Emoticons
# this is really a framework...
kf5.framework_dependency    gpgmepp libKF5Gpgmepp
# kf5-kinit does install a library but it may not be the best choice as a dependency:
# hard to tell at this moment how many dependents actually use that rather than
# depending on one of the framework's executables.
kf5.framework_dependency    kinit libkdeinit5_klauncher ""
kf5.framework_dependency    kded libkdeinit5_kded5 ""
kf5.framework_dependency    kparts libKF5Parts
kf5.framework_dependency    kdewebkit libKF5WebKit
set kf5.kdesignerplugin_dep path:bin/kgendesignerplugin:kf5-kdesignerplugin
kf5.framework_dependency    kpty libKF5Pty
kf5.framework_dependency    kdelibs4support libKF5KDELibs4Support
kf5.framework_dependency    frameworkintegration libKF5Style
kf5.framework_dependency    kpeople libKF5People
kf5.framework_dependency    ktexteditor libKF5TextEditor
kf5.framework_dependency    kxmlrpcclient libKF5XmlRpcClient
kf5.framework_dependency    kactivities libKF5Activities
kf5.framework_dependency    kdesu libKF5Su
kf5.framework_dependency    knewstuff libKF5NewStuff
kf5.framework_dependency    knotifyconfig libKF5NotifyConfig
kf5.framework_dependency    plasma-framework libKF5Plasma
kf5.framework_dependency    kjs libKF5JS
kf5.framework_dependency    khtml libKF5KHtml
kf5.framework_dependency    krunner libKF5Runner
kf5.framework_dependency    kwayland libKF5WaylandClient
