APP_STL := stlport_static
APP_CFLAGS += --sysroot $(NDK_ROOT)/platforms/android-14/arch-arm -DOS_ANDROID -DRHO_NO_JS_API
#APP_CFLAGS += --sysroot $(NDK_ROOT)/platforms/android-9/arch-arm -DOS_ANDROID
#APP_CFLAGS += --sysroot /home/lexis/android/android-ndk-r6/platforms/android-9/arch-arm -DOS_ANDROID
