# Nordic BLE Protocol Buffers Service Example

![Sheep](images/protobuf.jpg)

This example requires use of the NRF52 development kit. If you have no idea what the repository is, [head on over to part 1 of the tutorial.](https://www.jaredwolff.com/how-to-define-your-own-bluetooth-low-energy-configuration-service-using-protobuf/)

This repository is also a great starting point for developing a Bluetooth Low Energy project that needs OTA DFU.

## Setup for OSX (tested)

1. Initialize the full repository (there are submodules!): `git submodule update --init`
1. Install `protoc` using Homebrew: `brew install protobuf`
2. Run `make sdk`. This will download your SDK files.
3. Run `make tools_osx`. This will download your ARMGCC toolchain (for Mac). For other environments see below.
4. Run `make gen_key` once (and only once)! This will set up your key for DFU.
5. Run `make` and this will build your bootloader and main app.
6. Run `make flash_all` to flash the whole app to your NRF52 Development Kit.

## Setup for other platforms

1. Download `gcc-arm-none-eabi-6-2017-q2-update` toolchain from [here](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads).
2. Set your `GCC_ARM_TOOLCHAIN` environment variable to the path where you extracted your toolchain (usually <path>/<to>/gcc-arm-none-eabi-6-2017-q2-update/bin)
3. Install [`nrfutil`](https://github.com/NordicSemiconductor/pc-nrfutil)
4. Install [`nrfjprog`](https://www.nordicsemi.com/Software-and-Tools/Development-Tools/nRF5-Command-Line-Tools/Download#infotabs)
5. In the makefile update your `MERGEHEX` and `NRFJPROG` variables to the full path where those binaries are.
6. Install `protoc`. [More info here.](https://developers.google.com/protocol-buffers/docs/downloads)

## Creating your own Protocol Buffer

## Creating your own Service


## License

MIT Licensed