PROJ_DIR				:= $(shell pwd)
SDK_ROOT        := ./_sdk
SDK_TEMP        := ./_sdk_temp
OTA_DIR         := ./_ota
BUILD_DIR       := ./_build
OUT_DIR         := ./_out
TOOLCHAIN_DIR   := ./_toolchain
BOOTLOADER_DIR  := ./bootloader
DFU_DIR         := ./dfu
SDK_CONFIG_DIR  := ./sdk_config
MAIN_DIR        := ./main
PROTO_DIR       := ./proto
BIN_DIR         := ./bin
SOURCE_DIR      := ./src
INCLUDE_DIR     := ./include
EXTERNAL_DIR    := ./external

SETTINGS        := settings
BL_SETTINGS     := bl_settings
BL_SETTINGS_SD  := bl_settings_sd

NANOPB_DIR      := $(EXTERNAL_DIR)/nanopb
NANOPB_GEN      := $(NANOPB_DIR)/generator/nanopb_generator.py

# App filename
APP_FILENAME    := protobuf

# Commands
MERGEHEX				:= $(BIN_DIR)/mergehex/mergehex
NRFJPROG				:= $(BIN_DIR)/nrfjprog/nrfjprog

# Get firmware version
VER_STRING := $(shell git describe --tags --abbrev=0)
VER_STRING_W_GITHASH := $(shell git describe --tags --long)

# Download and install SDK deps
SDK_ZIP     := .nrf_sdk.zip
NRF_SDK_FOLDER_NAME := nRF5_SDK_15.2.0_9412b96
NRF_SDK_URL := https://www.nordicsemi.com/-/media/Software-and-other-downloads/SDKs/nRF5/Binaries/nRF5SDK15209412b96.zip
NRF_SDK_MD5 := 6677511a17f5247686fbec73093f4c0c
GCC_ARCHIVE := .gcc-arm-none-eabi-6-2017-q2-update-mac.tar.bz2
GCC_OUTPUT_FOLDER := gcc-arm-none-eabi-6-2017-q2-update
GCC_URL := https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu-rm/6-2017q2/gcc-arm-none-eabi-6-2017-q2-update-mac.tar.bz2
GCC_MD5 := d536d7fb167c04b24f7f0d40cd739cac

# Soft device info
SOFT_DEVICE := $(SDK_ROOT)/components/softdevice/s132/hex/s132_nrf52_6.1.0_softdevice.hex

# Protocol Buffers
PROTO_SRC   := $(wildcard $(PROTO_DIR)/*.proto)
PROTO_PB    := $(PROTO_SRC:.proto=.pb)

.PHONY: sdk sdk_clean clean build debug merge merge_all erase flash flash_all flash_softdevice ota settings default gen_key tools_osx

default: build

gen_key:
	@echo Generating pem key. You should only run this once!
	cd $(DFU_DIR) && nrfutil keys generate private.pem
	cd $(DFU_DIR) && nrfutil keys display --key pk --format code private.pem > dfu_public_key.c

settings: build
	@echo Generating settings .hex file
	nrfutil settings generate --family NRF52 --application $(BUILD_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).hex --application-version-string $(VER_STRING) --bootloader-version 1 --bl-settings-version 1 $(BUILD_DIR)/$(SETTINGS).hex

build:
	@export GCC_ARM_TOOLCHAIN=$(PROJ_DIR)/$(TOOLCHAIN_DIR) && make -C $(BOOTLOADER_DIR) -j
	@export GCC_ARM_TOOLCHAIN=$(PROJ_DIR)/$(TOOLCHAIN_DIR) && make -C $(MAIN_DIR) -j
	@mkdir -p $(BUILD_DIR)
	@cp -f $(MAIN_DIR)/_build/nrf52832_xxaa.hex $(BUILD_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).hex
	@cp -f $(BOOTLOADER_DIR)/_build/nrf52832_xxaa_s132.hex $(BUILD_DIR)/$(APP_FILENAME).bootloader.$(VER_STRING_W_GITHASH).hex

merge: settings
	@echo Merging settings with bootloader
	$(MERGEHEX) -m $(BUILD_DIR)/$(APP_FILENAME).bootloader.$(VER_STRING_W_GITHASH).hex $(BUILD_DIR)/$(SETTINGS).hex -o $(BUILD_DIR)/$(BL_SETTINGS).hex
	@echo Merging app with bootloader + settings
	@mkdir -p $(OUT_DIR)
	$(MERGEHEX) -m $(BUILD_DIR)/$(BL_SETTINGS).hex $(BUILD_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).hex -o $(OUT_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).combined.hex

merge_all: merge
	@echo Merging all files
	$(MERGEHEX) -m $(SOFT_DEVICE) $(OUT_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).combined.hex -o $(OUT_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).full.hex

flash_all: merge_all
	@echo Flashing all
	$(NRFJPROG) -f nrf52 --program $(OUT_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).full.hex --chiperase
	$(NRFJPROG) -f nrf52 --reset

flash: merge
	@echo Flashing firmware
	$(NRFJPROG) -f nrf52 --program $(OUT_DIR)/$(APP_FILENAME).app.$(VER_STRING_W_GITHASH).combined.hex --sectorerase
	$(NRFJPROG) -f nrf52 --reset

flash_softdevice:
	@echo Flashing softdevice
	$(NRFJPROG) -f nrf52 --program $(SOFT_DEVICE) --sectorerase
	$(NRFJPROG) -f nrf52 --reset

erase:
	@echo Erasing device
	$(NRFJPROG) -e

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
		if [ ! -f $(SDK_TEMP) ]; then \
			unzip $(SDK_ZIP) -d $(SDK_TEMP); \
		fi; \
		mv $(SDK_TEMP)/$(NRF_SDK_FOLDER_NAME) $(SDK_ROOT); \
		rmdir $(SDK_TEMP); \
	fi; \
	@echo Copyiing toolchain configuration file..
	@cp -f $(SDK_CONFIG_DIR)/build_all.sh $(SDK_ROOT)/external/micro-ecc/
	@cd $(SDK_ROOT)/external/micro-ecc/ && sh build_all.sh
	@cp -f $(SDK_CONFIG_DIR)/Makefile.posix $(SDK_ROOT)/components/toolchain/gcc/
	@echo SDK deps download and install complete.
	@rm -rf $(SDK_ZIP) $(SDK_TEMP) $(GCC_ARCHIVE)

tools_osx:
	@echo Installing OSX tools
	if [ ! -d $(TOOLCHAIN_DIR) ]; then \
		if [ ! -f $(GCC_ARCHIVE) ]; then \
			echo Downloading gcc...; \
			curl -o $(GCC_ARCHIVE) $(GCC_URL); \
		fi; \
		if [ "`md5 -q $(GCC_ARCHIVE)`" != "$(GCC_MD5)" ]; then \
			echo GCC archive MD5 does not match. Delete and reinstall.; \
			exit 1; \
		fi; \
		if [ ! -d $(GCC_OUTPUT_FOLDER) ]; then \
			tar jxfkv $(GCC_ARCHIVE); \
		fi; \
		if [ -d $(GCC_OUTPUT_FOLDER) ]; then \
			mv $(GCC_OUTPUT_FOLDER) $(TOOLCHAIN_DIR); \
		fi; \
	fi;

%.pb: %.proto
	protoc -I$(PROTO_DIR) --go_out=$(PROTO_DIR) $<
	protoc -I$(PROTO_DIR) -o$*.pb $<
	@$(NANOPB_GEN) -I$(PROTO_DIR) $@
	pbjs -t static-module -p$(PROTO_DIR) $*.proto > $@.js
	@mkdir -p $(SOURCE_DIR)/proto
	@mkdir -p $(INCLUDE_DIR)/proto
	@mv $*.pb.c $(SOURCE_DIR)/proto
	@mv $*.pb.h $(INCLUDE_DIR)/proto

protobuf: protoclean $(PROTO_PB)
	@echo building the protocol buffers $(PROTO_PB)

protoclean:
	@rm -fr $(PROTO_DIR)/*.pb

sdk_clean:
		@echo SDK Clean..
		@rm -rf $(SDK_ROOT)
		@rm -f $(SDK_ZIP)
		@rm -f $(GCC_ARCHIVE)

clean:
		@echo Cleaning..
		@rm -rf $(BUILD_DIR)
