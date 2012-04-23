include theos/makefiles/common.mk

SUBPROJECTS = AEPrefs customizer standard sbstoggles chatbot

TWEAK_NAME = AssistantExtensions
AssistantExtensions_FILES = AEAssistantdMsgCenter.mm AEContext.mm AEExtension.mm AESpringBoardMsgCenter.mm AEStringAdditions.mm AESupport.mm SiriObjects.mm AEX.mm
AssistantExtensions_FILES += main.mm shared.mm AEHooks.xm AEDevHelper.xm
AssistantExtensions_FRAMEWORKS = Foundation UIKit CoreFoundation Accounts Twitter CoreLocation
AssistantExtensions_PRIVATE_FRAMEWORKS = AppSupport GraphicsServices AssistantUI SAObjects VoiceServices BulletinBoard
AssistantExtensions_LDFLAGS  = -multiply_defined suppress -Llib -Fframeworks -dynamiclib
AssistantExtensions_LDFLAGS += -ObjC++ -fobjc-exceptions -fobjc-call-cxx-cdtors
AssistantExtensions_LDFLAGS += -lobjc -lsubstrate -lpthread -lpcre
AssistantExtensions_CFLAGS = -Os -funroll-loops -g -DSC_PRIVATE -fobjc-abi-version=2 -fno-exceptions -fobjc-exceptions -fobjc-call-cxx-cdtors -Iinclude

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/usr/include"$(ECHO_END)
	$(ECHO_NOTHING)cp SiriObjects.h "$(THEOS_STAGING_DIR)/usr/include/"$(ECHO_END)

distclean:
	rm -rf *.deb | true

test: distclean package install
