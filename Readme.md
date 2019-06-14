# Nordic BLE Protocol Buffers Service Example

This example requires use of the NRF52 development kit.

## Setup for OSX (tested)

1. Run `make sdk`. This will download your sdk files.
2. Run `make tools_osx`. This will download your ARMGCC toolchain (for Mac). For other environments see below.
3. Run `make genkey` once (and only once)! This will set up your key for DFU.
4. Run `make` and this will build your bootloader and main app.
5. Run `make flash_all` to flash the whole app to your NRF52 Development Kit.

## Setup for other platforms

1. Download `gcc-arm-none-eabi-6-2017-q2-update` toolchain from [here](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads). 2. Set your `GCC_ARM_TOOLCHAIN` environment variable to the path where you extracted your toolchain (usually <path>/<to>/gcc-arm-none-eabi-6-2017-q2-update/bin)
3. Install [`nrfutil`](https://github.com/NordicSemiconductor/pc-nrfutil)
4. Install [`nrfjprog`](https://www.nordicsemi.com/Software-and-Tools/Development-Tools/nRF5-Command-Line-Tools/Download#infotabs)
5. In the makefile update your `MERGEHEX` and `NRFJPROG` variables to the full path where those binaries are.