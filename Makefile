APP_NAME := EasyTouch
BUILD_DIR := build
APP_DIR := $(BUILD_DIR)/$(APP_NAME).app
CONTENTS_DIR := $(APP_DIR)/Contents
MACOS_DIR := $(CONTENTS_DIR)/MacOS
RESOURCES_DIR := $(CONTENTS_DIR)/Resources
TEST_DIR := $(BUILD_DIR)/tests

CC := clang
OBJCFLAGS := -fobjc-arc -Wall -Wextra -Werror -I Sources/EasyTouch
APP_FRAMEWORKS := -framework Cocoa -framework ApplicationServices
TEST_FRAMEWORKS := -framework Foundation
DEV_SIGN_IDENTITY := $(shell security find-identity -v -p codesigning | awk -F\" '/EasyTouch Local Development Root/ { print $$2; exit }')
SIGN_IDENTITY ?= $(if $(DEV_SIGN_IDENTITY),$(DEV_SIGN_IDENTITY),-)
APP_SOURCES := Sources/EasyTouch/main.m Sources/EasyTouch/ETThreeFingerTouchHandler.m Sources/EasyTouch/ETKeyboardShortcutSender.m Sources/EasyTouch/ETGlobalTrackpadTouchMonitor.m Sources/EasyTouch/ETShortcutBindingRecorder.m

.PHONY: all clean test

all: $(APP_DIR)

$(APP_DIR): $(MACOS_DIR)/$(APP_NAME) $(CONTENTS_DIR)/Info.plist
	codesign --force --sign "$(SIGN_IDENTITY)" $(APP_DIR)

$(MACOS_DIR)/$(APP_NAME): $(APP_SOURCES)
	@mkdir -p $(MACOS_DIR)
	$(CC) $(OBJCFLAGS) $^ -o $@ $(APP_FRAMEWORKS)

$(CONTENTS_DIR)/Info.plist: Sources/EasyTouch/Info.plist
	@mkdir -p $(CONTENTS_DIR) $(RESOURCES_DIR)
	cp $< $@

test: $(TEST_DIR)/ThreeFingerTouchHandlerTests $(TEST_DIR)/KeyboardShortcutSenderTests $(TEST_DIR)/ShortcutBindingRecorderTests
	$(TEST_DIR)/ThreeFingerTouchHandlerTests
	$(TEST_DIR)/KeyboardShortcutSenderTests
	$(TEST_DIR)/ShortcutBindingRecorderTests

$(TEST_DIR)/ThreeFingerTouchHandlerTests: Tests/ThreeFingerTouchHandlerTests.m Sources/EasyTouch/ETThreeFingerTouchHandler.m
	@mkdir -p $(TEST_DIR)
	$(CC) $(OBJCFLAGS) $^ -o $@ $(TEST_FRAMEWORKS)

$(TEST_DIR)/KeyboardShortcutSenderTests: Tests/KeyboardShortcutSenderTests.m Sources/EasyTouch/ETKeyboardShortcutSender.m Sources/EasyTouch/ETThreeFingerTouchHandler.m Sources/EasyTouch/ETShortcutBindingRecorder.m
	@mkdir -p $(TEST_DIR)
	$(CC) $(OBJCFLAGS) $^ -o $@ $(TEST_FRAMEWORKS) -framework ApplicationServices

$(TEST_DIR)/ShortcutBindingRecorderTests: Tests/ShortcutBindingRecorderTests.m Sources/EasyTouch/ETShortcutBindingRecorder.m
	@mkdir -p $(TEST_DIR)
	$(CC) $(OBJCFLAGS) $^ -o $@ $(TEST_FRAMEWORKS) -framework ApplicationServices

clean:
	rm -rf $(BUILD_DIR)
