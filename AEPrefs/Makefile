include ../theos/makefiles/common.mk

BUNDLE_NAME = AEPrefs
AEPrefs_FILES = AEPrefs.mm AEDonate.mm AEExtensionCell.mm
AEPrefs_INSTALL_PATH = /Library/PreferenceBundles
AEPrefs_FRAMEWORKS = UIKit Accounts Twitter
AEPrefs_PRIVATE_FRAMEWORKS = Preferences AppSupport

include $(THEOS_MAKE_PATH)/bundle.mk

after-stage:: 
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/AEPrefs.plist$(ECHO_END)