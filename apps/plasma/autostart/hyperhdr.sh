#!/usr/bin/env bash

# Wait for dbus service to be available
until dbus-send --print-reply --dest=org.freedesktop.DBus / org.freedesktop.DBus.ListNames; do
    sleep 1
done

# Start HyperHDR
hyperhdr
