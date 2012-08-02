include theos/makefiles/common.mk

SUBPROJECTS = AEPrefs jpsupport Extensions/*

TWEAK_NAME = AssistantExtensions
AssistantExtensions_FILES  = AEAssistantdMsgCenter.mm AEContext.mm AEExtension.mm AESpringBoardMsgCenter.mm AEStringAdditions.mm AESupport.mm SiriObjects.mm AEX.mm
AssistantExtensions_FILES += shared.mm AEHooks.xm AEDevHelper.xm AEExtensionSnippetController.xm
AssistantExtensions_CFLAGS  = -Os -funroll-loops -g -DSC_PRIVATE
AssistantExtensions_CFLAGS += -fobjc-abi-version=2 -fno-exceptions -fobjc-exceptions -fobjc-call-cxx-cdtors
AssistantExtensions_CFLAGS += -Iinclude
AssistantExtensions_LDFLAGS  = -multiply_defined suppress -Llib -Fframeworks
AssistantExtensions_LDFLAGS += -fobjc-exceptions -fobjc-call-cxx-cdtors
AssistantExtensions_LDFLAGS += -lpcre
AssistantExtensions_FRAMEWORKS = UIKit CoreLocation
AssistantExtensions_PRIVATE_FRAMEWORKS = AppSupport VoiceServices

TOOL_NAME = AETool
AETool_FILES = AETool.m
AETool_PRIVATE_FRAMEWORKS = AppSupport

include $(THEOS_MAKE_PATH)/tweak.mk
include $(THEOS_MAKE_PATH)/tool.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-stage::
	$(ECHO_NOTHING)mkdir -p "$(THEOS_STAGING_DIR)/usr/include"$(ECHO_END)
	$(ECHO_NOTHING)cp SiriObjects.h "$(THEOS_STAGING_DIR)/usr/include/"$(ECHO_END)

debclean:
	rm -rf *.deb