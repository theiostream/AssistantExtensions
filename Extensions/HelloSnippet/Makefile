include ../../theos/makefiles/common.mk

BUNDLE_NAME = HelloSnippet
HelloSnippet_BUNDLE_EXTENSION = assistantExtension
HelloSnippet_FILES = HelloCommands.mm HelloSnippet.mm
HelloSnippet_INSTALL_PATH = /Library/AssistantExtensions/
HelloSnippet_FRAMEWORKS = UIKit

IBTOOL=/Developer/usr/bin/ibtool
XibList = $(wildcard *.xib)
NibList = $(XibList:.xib=.nib)

%.nib:
	$(IBTOOL) --compile Resources/$(notdir $@) $*.xib
	
include $(THEOS_MAKE_PATH)/bundle.mk