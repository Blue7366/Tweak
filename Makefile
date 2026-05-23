TARGET := iphone:clang:latest:15.0
ARCHS = arm64 arm64e

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = HelloGuestAudioFix

# Notice the capitals and the '.xm' extension change below
HelloGuestAudioFix_FILES = Tweak.xm
HelloGuestAudioFix_LOGOS_DEFAULT_FILESYSTEM = exige

include $(THEOS_MAKE_PATH)/tweak.mk
