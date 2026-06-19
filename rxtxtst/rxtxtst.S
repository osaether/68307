/*
 * MC68307 UART RX+TX Interrupt Demo
 * (C) Ole Saether 1995
 *
 * Demonstrates interrupt-driven UART with ring buffers for both
 * TX and RX. Prints a banner on startup, then echoes received characters.
 *
 * UIMR bit 0 = TxRDY interrupt enable
 * UIMR bit 1 = RxRDY interrupt enable
 * USR  bit 0 = RxRDY (receiver data available)
 * USR  bit 2 = TxRDY (transmitter ready)
 */
#include "mc68307.h"

#define TX_BUF_SIZE 32
#define RX_BUF_SIZE 32

        .bss
txwp:   .byte   0                       // TX write pointer
txrp:   .byte   0                       // TX read pointer
txcnt:  .byte   0                       // TX bytes in buffer
txbuf:  .fill   TX_BUF_SIZE             // TX ring buffer

rxwp:   .byte   0                       // RX write pointer
rxrp:   .byte   0                       // RX read pointer
rxcnt:  .byte   0                       // RX bytes in buffer
rxbuf:  .fill   RX_BUF_SIZE             // RX ring buffer

        .text
        .org    0
        .long   0x188000                // Initial stack pointer
        .long   start                   // Reset vector

        .org    304
        .long   uartisr

message:
        .string "MC68307 RX/TX IRQ demo - type to echo\r\n"
.align  4
start:  movew   #0x2700,sr              // Disable interrupts
        movel   #0xff000010,SCR
        movew   #0x0100,MBAR

        movew   #0,WRR                  // Disable watchdog
        movew   #0xc001,BR0             // ROM at 0x000000
        movew   #0x1fc2,OR0             // 128kB ROM
        movew   #0x0301,BR1             // RAM at 0x180000
        movew   #0x1fc0,OR1             // 128kB RAM
        // CMS micro module: clear RAM CS latch
        movew   #0xff,d0
rloop:  moveb   0x180000,d1
        dbra    d0,rloop

        bsr     uart_init

        moveb   #0,txwp
        moveb   #0,txrp
        moveb   #0,txcnt
        moveb   #0,rxwp
        moveb   #0,rxrp
        moveb   #0,rxcnt

        movew   #0x0040,PICR            // UART interrupt at priority level 4
        moveb   #0x40,PIVR              // Interrupt base vector
        movew   #0x2000,sr              // Enable all interrupts

        movel   #message,d0
        bsr     puts
main_loop:
        bsr     getch                   // d0 = received character
        bsr     putch                   // echo it back
        bra     main_loop

puts:   moveml  d1/a0,-(sp)
        movel   d0,a0
        moveql  #0,d1
1:      moveb   (a0,d1),d0
        cmpb    #0,d0
        beq     2f
        bsr     putch
        addql   #1,d1
        jmp     1b
2:      moveml  (sp)+,d1/a0
        rts

uart_init:
        movew   #0x000C,PBCNT           // PB2/PB3 as UART RXD/TXD
        moveb   #0x20,UCR               // Reset receiver
        moveb   #0x30,UCR               // Reset transmitter
        moveb   #0x4C,UIVR              // UART interrupt vector
        moveb   #0xE0,UACR              // Set 2, Timer mode, divide by 1
        moveb   #0x00,UBG1              // Baud rate MSB
        moveb   #0x03,UBG2              // 115200 baud
        moveb   #0,UISR                 // Clear interrupt status
        moveb   #0x10,UCR               // Reset mode register pointer
        moveb   #0x13,UMR1              // 8N1
        moveb   #0x07,UMR2              // 1 stop bit
        moveb   #0xDD,UCSR              // Clock select
        moveb   #0x05,UCR               // Enable TX and RX
        moveb   #0x02,UIMR              // Enable RxRDY interrupt; TxRDY added by putch
        rts

// ISR handles both RxRDY (USR bit 0) and TxRDY (USR bit 2)
uartisr:
        btst    #0,USR                  // Check RxRDY
        bne     uartisr_h
        btst    #2,USR                  // Check TxRDY
        beq     uartisr_e               // Spurious - exit without touching registers

uartisr_h:
        moveml  d0-d1/a0,-(sp)
        moveb   #0,UIMR                 // Disable UART interrupts during critical section

        // RX: read byte from hardware into RX ring buffer
        btst    #0,USR
        beq     uartisr_norx
        moveb   URB,d0                  // Read received byte (clears RxRDY)
        cmpb    #RX_BUF_SIZE,rxcnt
        bge     uartisr_norx            // Drop if buffer full
        lea     rxbuf,a0
        moveql  #0,d1
        moveb   rxwp,d1
        moveb   d0,(a0,d1)
        addqb   #1,rxwp
        andib   #(RX_BUF_SIZE-1),rxwp
        addqb   #1,rxcnt
uartisr_norx:

        // TX: send next byte from TX ring buffer
        tstb    txcnt
        beq     uartisr_notx
        lea     txbuf,a0
        moveql  #0,d1
        moveb   txrp,d1
        moveb   (a0,d1),d0
        moveb   d0,UTB                  // Send character
        addqb   #1,txrp
        andib   #(TX_BUF_SIZE-1),txrp
        subqb   #1,txcnt
uartisr_notx:

        // Restore UIMR: always enable RxRDY (bit 1); TxRDY (bit 0) only if TX buffer non-empty
        moveql  #2,d1                   // RxRDY enable
        tstb    txcnt
        beq     uartisr_ex
        addqb   #1,d1                   // Also TxRDY enable
uartisr_ex:
        moveb   d1,UIMR
        moveml  (sp)+,d0-d1/a0
uartisr_e:
        rte

// getch: blocking read from RX ring buffer; returns character in d0
getch:  moveml  d1/a0,-(sp)
getch_w:
        tstb    rxcnt
        beq     getch_w                 // Wait for data
        lea     rxbuf,a0
        moveql  #0,d1
        moveb   rxrp,d1
        moveb   (a0,d1),d0
        addqb   #1,rxrp
        andib   #(RX_BUF_SIZE-1),rxrp
        subqb   #1,rxcnt
        moveml  (sp)+,d1/a0
        rts

// putch: write character in d0 to TX ring buffer (or direct if buffer empty and UART ready)
putch:  moveml  d1/a0,-(sp)
4:      cmpb    #TX_BUF_SIZE,txcnt
        bge     4b                      // Wait if buffer full
        tstb    txcnt
        bne     1f
        btst    #2,USR                  // Check TxRDY
        beq     1f                      // Not ready - use buffer
        moveb   d0,UTB                  // Send directly (bypass buffer)
        bra     2f
1:      lea     txbuf,a0
        moveql  #0,d1
        moveb   txwp,d1
        moveb   d0,(a0,d1)
        addqb   #1,txwp
        andib   #(TX_BUF_SIZE-1),txwp
        addqb   #1,txcnt
2:      moveb   #3,UIMR                 // Enable both RxRDY and TxRDY interrupts
3:      moveml  (sp)+,d1/a0
        rts
