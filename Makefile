TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HelloGuestAudioFix

HelloGuestAudioFix_FILES = Tweak.xm
HelloGuestAudioFix_LOGOS_DEFAULT_FILESYSTEM = exige

# FORCE THEOS TO USE INTERNAL SUBSTRATE FALLBACKS INSTEAD OF CYDIASUBSTRATE
HelloGuestAudioFix_LDFLAGS = -static-libsubstrate

include $(THEOS_MAKE_PATH)/tweak.mk
