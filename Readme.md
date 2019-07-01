# Nordic BLE Protocol Buffers Service Example

![Sheep](images/protobuf.jpg)

This example requires use of the NRF52 development kit. If you have no idea what the repository is, [head on over to part 1 of the tutorial.](https://www.jaredwolff.com/how-to-define-your-own-bluetooth-low-energy-configuration-service-using-protobuf/) Ready for the next step? [Part 2 is available here.](https://www.jaredwolff.com/how-to-protocol-buffer-bluetooth-low-energy-service-part-2/)

This repository is also a great starting point for developing a Bluetooth Low Energy project that needs OTA DFU.

Note: use this repository in conjunction with the [Javascript test app.](https://bitbucket.org/jaredwolff/ble-protobuf-js/)

## Setup for OSX (tested)

1. Initialize the full repository (there are submodules!): `git submodule update --init`
2. Install `protoc` using Homebrew: `brew install protobuf`
3. Run `make sdk`. This will download your SDK files.
4. Run `make tools_osx`. This will download your ARMGCC toolchain (for Mac). For other environments see below.
5. Run `make gen_key` once (and only once)! This will set up your key for DFU.
6. Run `make` and this will build your bootloader and main app.
6. Run `make flash_all` to flash the whole app to your NRF52 Development Kit.
7. Run `make debug` to connect to the device for debugging. Then, run `jlinkrttclient` to get your debug console. Both steps are required.

## Setup for other platforms

1. Download `gcc-arm-none-eabi-6-2017-q2-update` toolchain from [here](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads).
2. Set your `GCC_ARM_TOOLCHAIN` environment variable to the path where you extracted your toolchain (usually <path>/<to>/gcc-arm-none-eabi-6-2017-q2-update/bin)
3. Install [`nrfutil`](https://github.com/NordicSemiconductor/pc-nrfutil)
4. Install [`nrfjprog`](https://www.nordicsemi.com/Software-and-Tools/Development-Tools/nRF5-Command-Line-Tools/Download#infotabs)
5. In the makefile update your `MERGEHEX` and `NRFJPROG` variables to the full path where those binaries are.
6. Install `protoc`. [More info here.](https://developers.google.com/protocol-buffers/docs/downloads)

## Creating your own Protocol Buffer

### The `.proto` and `.options` files

Create a file called `command.proto`. You can make the contents of that file what's below:

```
syntax = "proto3";

message event {
  enum event_type {
    command = 0;
    response = 1;
  }
  event_type type = 1;
  string message = 2;
}
```

It may look foreign at first but once you take a deeper look, it’s not that much different than a standard C struct or hash table.

I'm using two types of data in this example: a `string` and `enum` as a type. There are actually a few more which you can read up at the [documentation](https://developers.google.com/protocol-buffers/docs/proto). When compiled, the equivalent c struct looks like:

```
/* Struct definitions */
typedef struct _event {
    event_event_type type;
    char message[64];
/* @@protoc_insertion_point(struct:event) */
} event;
```

Where `event_event_type` is

```
/* Enum definitions */
typedef enum _event_event_type {
    event_event_type_command = 0,
    event_event_type_response = 1
} event_event_type;
```

You can nest as many messages inside each other as your hearts content. Typically though, a message is as small as possible so data transmission is as efficient as possible. This is particularly important for resource constrained systems or LTE deployments where you're charged for *every* megabyte used. **Note:** when elements are not used or defined they are typically *not* included in the encoded Protocol Buffer payload.

Normally, when you create a generic message like this, there is no limit to the size of the string `message`. That option can be set in the `.options` file:

```
event.message	max_size:64
```

This way, the memory can be statically allocated in my microprocessor code at compile time. If the message size is greater than 64 bytes then it will get chopped off in the code (or you'll simply get an error during decode). It's up to you, the software engineer, to figure out the absolute maximum amount of bytes  (or characters) that you may need for this type of data.

You can look at more of the `nanopb` related features at [their documentation.](https://jpa.kapsi.fi/nanopb/docs/concepts.html)

### Compiling the `.proto` and `.options` files

Using this repository, it's as simple as running `make protobuf`. The files can be individually compiled as well:

If we want to generate a static Go file the command looks like:

```bash
protoc -I<directory with .proto> --go_out=<output directory> command.proto
```
If you've installed the nanopb plugin, you can do something similar to generate C code:

```bash
protoc -I<directory with .proto> -ocommand.pb command.proto
<path>/<to>/protogen/nanopb_generator.py -I<directory with .proto> command
```
The first file creates a generic "object" file. The second actually creates the static C library.

For javascript:

```bash
pbjs -t static-module -p<directory with .proto> command.proto > command.pb.js
```

## Creating your own Service

*Coming in Part 2!*

## License

MIT Licensed