ARCHS := arm64
TARGET := iphone:clang:latest:14.0

INSTALL_TARGET_PROCESSES := PMNDev

include $(THEOS)/makefiles/common.mk

APPLICATION_NAME := PMNDev
PACKAGE_NAME := com.pmndev.freefire

PMNDev_USE_MODULES := 0
PMNDev_FILES += main.mm PMNDevOverlay.mm Memory.mm GameLogic.mm

PMNDev_CFLAGS += -fobjc-arc \
-Wno-unused-function \
-Wno-deprecated-declarations \
-Wno-unused-variable \
-Wno-unused-value \
-Wno-module-import-in-extern-c -Wno-unused-but-set-variable

PMNDev_CFLAGS += -Iinclude
PMNDev_CFLAGS += -include hud-prefix.pch
PMNDev_LDFLAGS += Core.a

PMNDev_CCFLAGS += -std=c++14
PMNDev_CCFLAGS += -DNOTIFY_LAUNCHED_HUD=\"ch.xxtou.notification.hud.launched\"
PMNDev_CCFLAGS += -DNOTIFY_DISMISSAL_HUD=\"ch.xxtou.notification.hud.dismissal\"
PMNDev_CCFLAGS += -DNOTIFY_RELOAD_HUD=\"ch.xxtou.notification.hud.reload\"
PMNDev_CCFLAGS += -DNOTIFY_RELOAD_APP=\"ch.xxtou.notification.app.reload\"

PMNDev_FRAMEWORKS += CoreGraphics QuartzCore UIKit Foundation
PMNDev_PRIVATE_FRAMEWORKS += BackBoardServices GraphicsServices IOKit SpringBoardServices

PMNDev_CODESIGN_FLAGS += -Sent.plist

include $(THEOS_MAKE_PATH)/application.mk
include $(THEOS_MAKE_PATH)/aggregate.mk

after-package::
	@rm -rf packages Payload
	@mkdir -p Payload packages
	@cp -rp $(THEOS_STAGING_DIR)/Applications/$(APPLICATION_NAME).app Payload
	@cd . && zip -qr $(APPLICATION_NAME).tipa Payload
	@mv $(APPLICATION_NAME).tipa packages/$(APPLICATION_NAME).tipa
	@rm -rf Payload
