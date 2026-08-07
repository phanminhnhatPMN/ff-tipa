ARCHS := arm64
TARGET := iphone:clang:latest:14.0

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := PMNDev
PACKAGE_NAME := com.pmndev.freefire

PMNDev_FILES += main.mm PMNDevOverlay.mm Memory.mm GameLogic.mm

PMNDev_CFLAGS += -fobjc-arc \
-Wno-unused-function \
-Wno-deprecated-declarations \
-Wno-unused-variable

PMNDev_FRAMEWORKS += CoreGraphics QuartzCore UIKit Foundation
PMNDev_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices IOKit SpringBoardServices

PMNDev_CODESIGN_FLAGS += -Sent.plist

include $(THEOS_MAKE_PATH)/application.mk

after-package::
	@rm -rf packages Payload
	@mkdir -p Payload packages
	@cp -rp $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app Payload
	@cd . && zip -qr $(APPLICATION_NAME).tipa Payload
	@mv $(APPLICATION_NAME).tipa packages/$(APPLICATION_NAME).tipa
	@rm -rf Payload
