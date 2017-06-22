QT -= core
    greaterThan(QT_VERSION, 5.6.0): {
        CONFIG += c++14
        DEFINES += CPP_ELEVEN
        DEFINES += RHODES_VERSION_2
        DEFINES += AJAXSERVER
    }

    lessThan(QT_VERSION, 5.6.0): {
        DEFINES += RHODES_VERSION_1
    }

TARGET = rholib
TEMPLATE = lib

CONFIG += staticlib warn_on

INCLUDEPATH += ../..\
../../ruby\
../../../../lib/commonAPI

macx {
  DESTDIR = ../../../osx/bin/rholib
  OBJECTS_DIR = ../../../osx/bin/rholib/tmp
  INCLUDEPATH += ../../curl/include
  HEADERS += ../../common/PosixThreadImpl.h\
../../net/CURLNetRequest.h\
../../net/ssl.h
  SOURCES += ../../common/PosixThreadImpl.cpp\
../../net/CURLNetRequest.cpp\
../../net/ssl.cpp
}

win32 {
  DESTDIR = ../../../win32/bin/rholib
  OBJECTS_DIR = ../../../win32/bin/rholib/tmp
  DEFINES += WIN32 _WINDOWS _CRT_SECURE_NO_WARNINGS _UNICODE UNICODE
  Debug {
    DEFINES += _DEBUG DEBUG
  }
  Release {
    DEFINES += _NDEBUG NDEBUG
  }
  HEADERS += ../../rubyext/WebView.h
  QMAKE_CXXFLAGS_RELEASE += -MP9
  QMAKE_CXXFLAGS_DEBUG += -MP9
}

unix:!macx {
  DESTDIR = ../../../linux/bin/rholib
  OBJECTS_DIR = ../../../linux/bin/rholib/tmp
  INCLUDEPATH += ../../curl/include
  DEFINES += _GNU_SOURCE
  HEADERS += ../../common/PosixThreadImpl.h\
../../net/CURLNetRequest.h\
../../net/ssl.h
  SOURCES += ../../common/PosixThreadImpl.cpp\
../../net/CURLNetRequest.cpp\
../../net/ssl.cpp
}

DEFINES += RHODES_QT_PLATFORM

!isEmpty(RHOSIMULATOR_BUILD) {
  DEFINES += RHODES_EMULATOR
}

!win32 {
  QMAKE_CFLAGS_WARN_ON += -Wno-extra -Wno-unused -Wno-sign-compare -Wno-format -Wno-parentheses
  QMAKE_CXXFLAGS_WARN_ON += -Wno-extra -Wno-unused -Wno-sign-compare -Wno-format -Wno-parentheses
  # QMAKE_CFLAGS += -fvisibility=hidden
  # QMAKE_CXXFLAGS += -fvisibility=hidden
}
win32 {
  QMAKE_CFLAGS_WARN_ON += /wd4189 /wd4018 /wd4189 /wd4996
  QMAKE_CXXFLAGS_WARN_ON += /wd4189 /wd4018 /wd4189 /wd4996
  QMAKE_CFLAGS_RELEASE += /O2
  QMAKE_CXXFLAGS_RELEASE += /O2
}

HEADERS += ../../common/RhoAppAdapter.h\
../../common/IRhoThreadImpl.h\
../../common/RhoThread.h\
../../common/RhodesAppBase.h\
../../common/RhodesApp.h\
../../common/RhoConf.h\
../../common/RhoSimConf.h\
../../statistic/RhoProfiler.h\
../../common/RhoDefs.h\
../../common/RhoFatalError.h\
../../common/RhoFile.h\
../../common/RhoFilePath.h\
../../common/RhoMutexLock.h\
../../common/RhoPort.h\
../../common/RhoStd.h\
../../common/RhoSystem.h\
../../common/RhoTime.h\
../../common/StringConverter.h\
../../logging/RhoLog.h\
../../logging/RhoLogCat.h\
../../logging/RhoLogConf.h\
../../logging/RhoLogSink.h\
../../common/Tokenizer.h\
../../rubyext/GeoLocation.h\
../../common/AutoPointer.h\
../../common/InputStream.h\
../../common/irhoclassfactory.h\
../../common/ThreadQueue.h\
../../net/URI.h\
../../common/AppMenu.h\
../../net/INetRequest.h\
../../net/HttpServer.h\
../../common/SplashScreen.h\
../../common/rhoparams.h\
../../common/app_build_configs.h\
../../common/RhoMath.h\
../../common/map/ESRIMapEngine.h\
../../common/map/GoogleMapEngine.h\
../../common/map/MapEngine.h\
../../common/push/IRhoPushClient.h\
../../common/push/RhoPushManager.h\
../../api_generator/BaseClasses.h\
../../api_generator/GeneratorQueue.h\
../../api_generator/MethodResult.h\
../../api_generator/js_helpers.h\
../../api_generator/StringifyHelper.h

SOURCES += ../../common/RhoTime.cpp\
../../rubyext/RhoAppAdapter.cpp\
../../common/RhoThread.cpp\
../../common/RhodesAppBase.cpp\
../../common/RhodesApp.cpp\
../../common/RhoConf.cpp\
../../common/RhoSimConf.cpp\
../../statistic/RhoProfiler.cpp\
../../common/RhoFile.cpp\
../../logging/RhoLog.cpp\
../../logging/RhoLogConf.cpp\
../../logging/RhoLogSink.cpp\
../../logging/RhoPlainLog.cpp\
../../common/Tokenizer.cpp\
../../rubyext/GeoLocation.cpp\
../../common/ThreadQueue.cpp\
../../net/INetRequest.cpp\
../../net/URI.cpp\
../../common/AppMenu.cpp\
../../common/rhoparams.cpp\
../../rubyext/System.cpp\
../../net/HttpServer.cpp\
../../common/SplashScreen.cpp\
../../common/app_build_configs.c\
../../common/map/OSMMapEngine.cpp\
../../common/map/GeocodingMapEngine.cpp\
../../common/map/BaseMapEngine.cpp\
../../common/RhoMath.cpp\
../../common/map/ESRIMapEngine.cpp\
../../common/map/GoogleMapEngine.cpp\
../../common/map/MapEngine.cpp\
../../common/BundleManager.cpp\
../../common/push/RhoPushManager.cpp\
../../api_generator/js_helpers.cpp\
../../api_generator/MethodResult.cpp\
../../api_generator/StringifyHelper.cpp

HEADERS += ../../unzip/zip.h\
../../unzip/unzip.h\
../../unzip/gunzip.h\
../../unzip/crc32.h\
../../unzip/deflate.h\
../../unzip/inffast.h\
../../unzip/inffixed.h\
../../unzip/inflate.h\
../../unzip/gzguts.h\
../../unzip/inftrees.h\
../../unzip/trees.h\
../../unzip/unzip.h\
../../unzip/zconf.h\
../../unzip/zip.h\
../../unzip/zlib.h\
../../unzip/zutil.h
SOURCES += ../../unzip/unzip.cpp\
../../unzip/adler32.cpp\
../../unzip/crc32.cpp\
../../unzip/deflate.cpp\
../../unzip/gunzip.cpp\
../../unzip/gzclose.cpp\
../../unzip/gzlib.cpp\
../../unzip/gzread.cpp\
../../unzip/gzwrite.cpp\
../../unzip/infback.cpp\
../../unzip/inffast.cpp\
../../unzip/inflate.cpp\
../../unzip/inftrees.cpp\
../../unzip/trees.cpp\
../../unzip/unzip.cpp\
../../unzip/zip.cpp\
../../unzip/zutil.cpp

