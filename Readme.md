# Nordic BLE Protocol Buffers Service Example

![Sheep](images/protobuf.jpg)

This example requires use of the NRF52 development kit. If you have no idea what the repository is, [head on over to part 1 of the tutorial.](https://www.jaredwolff.com/how-to-define-your-own-bluetooth-low-energy-configuration-service-using-protobuf/)

## Setup for OSX (tested)

1. Install `protoc` using Homebrew: `brew install protobuf`
2. Install `nanopb` using Homebrew `brew install nanopb-generator`
3. Run `make sdk`. This will download your sdk files.
4. Run `make tools_osx`. This will download your ARMGCC toolchain (for Mac). For other environments see below.
5. Run `make genkey` once (and only once)! This will set up your key for DFU.
6. Run `make` and this will build your bootloader and main app.
7. Run `make flash_all` to flash the whole app to your NRF52 Development Kit.

## Setup for other platforms

1. Download `gcc-arm-none-eabi-6-2017-q2-update` toolchain from [here](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads).
2. Set your `GCC_ARM_TOOLCHAIN` environment variable to the path where you extracted your toolchain (usually <path>/<to>/gcc-arm-none-eabi-6-2017-q2-update/bin)
3. Install [`nrfutil`](https://github.com/NordicSemiconductor/pc-nrfutil)
4. Install [`nrfjprog`](https://www.nordicsemi.com/Software-and-Tools/Development-Tools/nRF5-Command-Line-Tools/Download#infotabs)
5. In the makefile update your `MERGEHEX` and `NRFJPROG` variables to the full path where those binaries are.
6. Install `protoc`. [More info here.](https://developers.google.com/protocol-buffers/docs/downloads)
7. Install `nanopb`. [More info here.](https://github.com/nanopb/nanopb)

## Creating your own Protocol Buffer

## Creating your own Service


## License

MIT Licensed