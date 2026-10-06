#!/bin/sh
# Started by greetd as the greeter user: cage hosts the quickshell greeter, one window spans all screens
# and the greeter draws its own copy of the scene on each screen
export QT_QPA_PLATFORM=wayland
# No Qt title bar and border around the window
export QT_WAYLAND_DISABLE_WINDOWDECORATION=1
exec cage -d -s -m extend -- quickshell -p /etc/greetd/greeter
