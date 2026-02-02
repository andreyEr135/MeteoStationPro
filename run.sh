#!/bin/bash

export DISPLAY=:0
export QT_QPA_EGLFS_PHYSICAL_WIDTH=154
export QT_QPA_EGLFS_PHYSICAL_HEIGHT=90
export QT_SCALE_FACTOR=0.6
# Запуск из директории с программой
cd "$(dirname $0)"
./MeteoStation -platform eglfs

