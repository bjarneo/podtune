QT += core gui qml quick quickcontrols2 multimedia
CONFIG += c++17 release link_pkgconfig
PKGCONFIG += alsa
TARGET = podtune
TEMPLATE = app
HEADERS += src/protocol.h src/backend.h src/audio.h src/theme.h
SOURCES += src/main.cpp src/protocol.cpp src/backend.cpp src/audio.cpp src/theme.cpp
RESOURCES += src/resources.qrc
