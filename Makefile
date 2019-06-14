SDK_ROOT        := ./_sdk
SDK_TEMP        := ./_sdk_temp
OTA_DIR         := ./_ota
BUILD_DIR       := ./_build
OUT_DIR         := ./_out
DFU_DIR         := ./dfu
SDK_CONFIG_DIR  := ./sdk_config
MAIN_DIR        := ./main
PROTO_DIR       := ./proto
BIN_DIR         := ./bin
SOURCE_DIR      := ./src
INCLUDE_DIR     := ./include

SETTINGS        := settings
BL_SETTINGS     := bl_settings
BL_SETTINGS_SD  := bl_settings_sd

# Get bootloader version
BOOTLOADER_VER_STRING := $(shell cd bootloader; git describe --tags --abbrev=0)
BOOTLOADER_VER_STRING_W_GITHASH := $(shell cd bootloader; git describe --tags --long)

# Get firmware version
VER_STRING := $(shell git describe --tags --abbrev=0)
VER_STRING_W_GITHASH := $(shell git describe --tags --long)

# Download and install SDK deps
SDK_ZIP     := .nrf_sdk.zip
NRF_SDK_FOLDER_NAME := nRF5_SDK_15.2.0_9412b96
NRF_SDK_URL := https://www.nordicsemi.com/-/media/Software-and-other-downloads/SDKs/nRF5/Binaries/nRF5SDK15209412b96.zip
NRF_SDK_MD5 := 6677511a17f5247686fbec73093f4c0c

# Soft device info
SOFT_DEVICE := $(SDK_ROOT)/components/softdevice/s132/hex/s132_nrf52_6.1.0_softdevice.hex

# Protocol Buffers
PROTO_SRC   := $(wildcard $(PROTO_DIR)/*.proto)
PROTO_PB    := $(PROTO_SRC:.proto=.pb)

.PHONY: sdk sdk_clean clean build debug merge mergeall erase flash ota settings default

default: build

settings: build
	@echo Generating settings .hex file
	nrfutil settings generate --family NRF52 --application $(BUILD_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).hex --application-version-string $(VER_STRING) --bootloader-version 1 --bl-settings-version 1 $(BUILD_DIR)/$(SETTINGS).hex

build:
	@make -C $(BOOTLOADER_DIR) -j
	@make -C $(MAIN_DIR) -j

merge: settings
	@echo Merging settings with bootloader
	mergehex -m $(BUILD_DIR)/$(APP_FILENAME).bootloader.$(BOOTLOADER_VER_STRING_W_GITHASH).hex $(BUILD_DIR)/$(SETTINGS).hex -o $(BUILD_DIR)/$(BL_SETTINGS).hex
	@echo Merging app with bootloader + settings
	@mkdir -p $(OUT_DIR)
	mergehex -m $(BUILD_DIR)/$(BL_SETTINGS).hex $(BUILD_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).hex -o $(OUT_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).combined.hex

mergeall: merge
	@echo Merging all files
	mergehex -m $(SOFT_DEVICE) $(OUT_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).combined.hex -o $(OUT_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).full.hex

flash: merge
	@echo Flashing firmware
	nrfjprog -f nrf52 --program $(OUT_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).combined.hex --sectorerase
	nrfjprog -f nrf52 --reset

flash_softdevice:
	@echo Flashing softdevice
	nrfjprog -f nrf52 --program $(SOFT_DEVICE) --sectorerase
	nrfjprog -f nrf52 --reset

erase:
	@echo Erasing device
	nrfjprog -e

ota: build
	@echo Generating OTA package
	@mkdir -p $(OTA_DIR)
	nrfutil pkg generate --sd-req 0xAF --hw-version 52 --key-file $(DFU_DIR)/$(DFU_CERT) \
		--application-version-string $(VER_STRING) --application $(BUILD_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).hex \
		$(OTA_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).zip

debug:
	@echo Debug using JLinkExe
	JLinkExe -device NRF52 -speed 4000 -if SWD -autoconnect 1

sdk:
	@echo Installing NRF SDK
	@if [ ! -d $(SDK_ROOT) ]; then \
		if [ ! -f $(SDK_ZIP) ]; then \
			echo Downloading sdk deps...; \
			curl -o $(SDK_ZIP) $(NRF_SDK_URL); \
		fi; \
		if [ "`md5 -q $(SDK_ZIP)`" != "$(NRF_SDK_MD5)" ]; then \
			echo SDK archive MD5 does not match. Delete and reinstall.; \
			exit 1; \
		fi; \
		unzip $(SDK_ZIP) -d $(SDK_TEMP); \
	fi; \
	if ( -d $(SDK_ROOT)/$(NRF_SDK_FOLDER_NAME) ); then \
		mv $(SDK_TEMP)/$(NRF_SDK_FOLDER_NAME) $(SDK_ROOT); \
		rmdir $(SDK_TEMP)/$(NRF_SDK_FOLDER_NAME); \
	fi; \
	@echo Copyiing toolchain configuration file..
	@cp -f $(SDK_CONFIG_DIR)/Makefile.posix $(SDK_ROOT)/components/toolchain/gcc/
	@echo SDK deps download and install complete.
	@rm -rf $(SDK_ZIP) $(SDK_TEMP)

%.pb: %.proto
	protoc -I$(PROTO_DIR) --go_out=$(PROTO_DIR) $<
	protoc -I$(PROTO_DIR) -o$*.pb $<
	@$(BIN_DIR)/protogen/nanopb_generator.py -I$(PROTO_DIR) $@
	pbjs -t static-module -p$(PROTO_DIR) $*.proto > $@.js
	@mv $*.pb.c $(SOURCE_DIR)/protobuf
	@mv $*.pb.h $(INCLUDE_DIR)/protobuf

protobuf: protoclean $(PROTO_PB)
	@echo building the protocol buffers $(PROTO_PB)

protoclean:
	@rm -fr $(PROTO_DIR)/*.pb

sdk_clean:
		@echo SDK Clean..
		@rm -rf $(SDK_ROOT)
		@rm -f $(SDK_ZIP)

clean:
		@echo Cleaning..
		@rm -rf $(BUILD_DIR)
