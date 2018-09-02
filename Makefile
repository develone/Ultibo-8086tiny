# 8086tiny: a tiny, highly functional, highly portable PC emulator/VM
# Copyright 2013-14, Adrian Cable (adrian.cable@gmail.com) - http://www.megalith.co.uk/8086tiny
#
# This work is licensed under the MIT License. See included LICENSE.TXT.

# 8086tiny builds with graphics and sound support
# 8086tiny_slowcpu improves graphics performance on slow platforms (e.g. Raspberry Pi)
# no_graphics compiles without SDL graphics/sound

CC=arm-none-eabi-gcc
AR=arm-none-eabi-ar
OPTS_ALL=-fno-exceptions -Wno-attributes -mabi=aapcs -marm -march=armv7-a -mfpu=vfpv3-d16 -mfloat-abi=hard -D__DYNAMIC_REENT__ -fsigned-char -std=c99 -c

8086tiny: 8086tiny.c
	${CC} ${OPTS_ALL} 8086tiny.c
	${AR} rcs lib8086tiny.a 8086tiny.o

clean:
	rm lib8086tiny.a
