# Changelog

All notable changes to the `hello_world_irq` program are documented in this file.

## [Unreleased]

### Fixed

- **UART baud-rate timer mode (UACR).** Changed `UACR` from `0xE0` to `0xB0` in
  `uart_init`. `0xE0` sets the timer mode/source field `CTMS2-0` to `110`, which
  MC68307UM.pdf Table 8-11 lists as invalid ("other values are invalid on the
  MC68307 and should not be used"). The only valid encoding is `011` (Counter,
  Crystal or External Clock), so the correct value for baud-rate set 2 in counter
  mode is `0xB0`.
- **Uninitialized variables declared with data initializers in `.bss`.** Replaced
  `.byte 0` / `.fill` with `.skip` for `txwp`, `txrp`, `txcnt`, and `txbuf`. The
  `.bss` section is NOBITS and is not loaded from ROM, so the `0` initializers were
  silently discarded; correctness relied entirely on the runtime re-initialization
  in `start`. Reserving uninitialized space with `.skip` reflects the actual
  semantics.
