# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

This is the repo-wide guidance shared by all three sub-projects. Each sub-project may also have its own `CLAUDE.md` (e.g. `hello_world_irq/CLAUDE.md`) describing that program's architecture; Claude Code loads both the root and the sub-directory file when you work inside a sub-project.

## Project overview

MC68307 bare-metal assembly programs originally written in the 1990s, updated for the GNU m68k cross-compiler toolchain. The repository root contains three sibling sub-projects:

- `hello_world/` — pure assembly, polling UART TX
- `hello_world_irq/` — assembly with interrupt-driven UART TX
- `hello_world_c/` — C entry point with assembly startup and UART driver

Shared header: `include/mc68307.h` — defines all SIM/UART/Timer/M-Bus register addresses as `MBASE + offset` macros (MBASE = `0x100000`). Each sub-project includes it via `-I../include`.

## Toolchain

Requires the GNU m68k cross-compiler. Install on Ubuntu:
```
sudo apt install gcc-m68k-linux-gnu
```

Tools used:
- Compiler/assembler: `m68k-linux-gnu-gcc` (assembles `.S` files with `-I../include -Wa,-mcpu=68307 -Wa,--register-prefix-optional`; `--register-prefix-optional` is what allows bare register names like `d0`/`sr` instead of `%d0`)
- Linker: `m68k-linux-gnu-ld` (`-T cms307.ld`, emits a `.map`)
- Binary conversion: `m68k-linux-gnu-objcopy -O ihex`

There are no automated tests — this is bare-metal firmware. "Passing" means it assembles and links cleanly; behaviour is verified on hardware (or against the datasheet). Treat register values as the source of truth and check them against the datasheet before changing them.

## Build commands

Each sub-project has its own `makefile`; `cd` into the sub-project directory first.

```sh
make              # builds hello_world.hex (Intel HEX for flashing)
make clean        # removes all build artifacts
```

`hello_world_c` assembles multiple sources (`init307.S`, `uart.S`, `hello_world.c`) into one image; the other two are single-file. Intermediate outputs: `.o` (object), `.a` (ELF), `.lst` (assembly listing), `.map` (linker map), `.hex` (Intel HEX). All are gitignored.

Note the ISA flags differ by source type: `.S` files assemble with `-Wa,-mcpu=68307`, but `.c` files compile with `-march=68000` (the 68307 has a 68000 core, and gcc has no `-march=68307`). The linker runs with `-z noexecstack`. Keep these in sync if you add sources.

## Datasheet reference

`MC68307UM.pdf` (265-page user manual) lives in the repo root (untracked, large). It is the authority for every register bit. Extract searchable text with `pdftotext -layout ../MC68307UM.pdf -` (from a sub-project dir, or drop the `../` from the root) and grep for register names / table numbers (e.g. Table 8-11 for the UART UACR field encodings).

## Memory layout (cms307.ld)

All three sub-projects use an identical `cms307.ld`:

| Region | Address    | Size  | Contents           |
|--------|------------|-------|--------------------|
| ROM    | 0x000000   | 128 KB | `.text`, load address for `.data` |
| RAM    | 0x180000   | 32 KB  | `.data`, `.bss`    |

The reset vector is at address 0 (SP) and 4 (PC = `start`). Interrupt-driven programs place their ISR vector with `.org` at the table offset matching the device's `PIVR`/`UIVR` configuration.

## UART configuration note

Across all three programs the UART baud generator uses `UACR=0xB0` (baud rate set 2, counter mode, crystal clock — `CTMS=011`). The original 1990s code used `0xE0` (`CTMS=110`), which MC68307UM.pdf Table 8-11 lists as invalid; `0xB0` is the documented value for the intended function.
