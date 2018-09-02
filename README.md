[![Bare metal 8086tiny](https://img.youtube.com/vi/TMNoba17FXc/0.jpg)](https://www.youtube.com/watch?v=TMNoba17FXc "Bare metal 8086tiny")

# Bare metal 8086 emulator for Raspberry Pi

As part of a Hackathon, 8086tiny was ported hastily to the [Ultibo](https://ultibo.org/) bare metal environment for Raspberry Pi.
This allows for quick booting, at the expense of other luxuries.

This is by no means a complete port, just a proof-of-concept.
It has several failures:
* Arrows keys don't work
* Non-existent ANSI support
* Incorrect palette handling
* The code is _awful_

## Running

* Format an SD card to be FAT32
* Copy the Raspberry Pi [firmware files](https://github.com/raspberrypi/firmware/tree/master/boot) onto it
* Compile `lib8086tiny.a`
* Compile the Ultibo `kernel7.img` and copy it to the root of the SD card
* Put your `bios` file in the root of the SD card
* Put your `fd.img` floppy disk image file in the root of the SD card
* (Optionally) Put your `disk.img` hard disk image file in the root of the SD card

## Compiling

To build the library
* Install the arm-none-eabi toolchain from [here](https://developer.arm.com/open-source/gnu-toolchain/gnu-rm/downloads)
* Run `make` as usual
* This should result in `lib8086tiny.a`

To build the bare metal kernel
* Compile the project from inside Ultibo Lazarus, or by using one of the batch files
*Note*: you will need to edit the path to your Ultibo installation in the batch files.

---

8086tiny
========

8086tiny is a completely free (MIT License) open source PC XT-compatible emulator/virtual machine written in C. It is, we believe, the smallest of its kind (the fully-commented source is under 25K). Despite its size, 8086tiny provides a highly accurate 8086 CPU emulation, together with support for PC peripherals including XT-style keyboard, floppy/hard disk, clock, audio, and Hercules/CGA graphics. 8086tiny is powerful enough to run software like AutoCAD, Windows 3.0, and legacy PC games: the 8086tiny distribution includes Alley Cat, the author's favorite PC game of all time.

8086tiny is highly portable and runs on practically any little endian machine, from simple 32-bit MCUs upwards. 8086tiny has successfully been deployed on 32-bit/64-bit Intel machines (Windows, Mac OS X and Linux), Nexus 4/ARM (Android), iPad 3 and iPhone 5S (iOS), and Raspberry Pi (Linux).

The philosophy of 8086tiny is to keep the code base as small as possible, and through the open source license encourage individual developers to tune and extend it as per their specific requirements, adding support, for example, for more complex instruction sets (e.g. Pentium) or peripherals (e.g. mouse). Forking this repository is highly encouraged!

Any questions, comments or suggestions are very welcome in our forum at 8086tiny.freeforums.net.
