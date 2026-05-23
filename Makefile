TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HelloGuestAudioFix

HelloGuestAudioFix_FILES = Tweak.x
HelloGuestAudioFix_CFLAGS = -fobjc-arc -std=c++11
HelloGuestAudioFix_FRAMEWORKS = UIKit AVFoundation AudioToolbox

include $(THEOS_MAKE_PATH)/tweak.mk
