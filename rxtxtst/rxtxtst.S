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
start:  move.w   #0x2700,sr              // Disable interrupts
        move.l   #0xff000010,SCR
        move.w   #0x0100,MBAR

        move.w   #0,WRR                  // Disable watchdog
        move.w   #0xc001,BR0             // ROM at 0x000000
        move.w   #0x1fc2,OR0             // 128kB ROM
        move.w   #0x0301,BR1             // RAM at 0x180000
        move.w   #0x1fc0,OR1             // 128kB RAM
        // CMS micro module: clear RAM CS latch
        move.w   #0xff,d0
rloop:  move.b   0x180000,d1
        dbra    d0,rloop

        bsr     uart_init

        clr.b    txwp
        clr.b    txrp
        clr.b    txcnt
        clr.b    rxwp
        clr.b    rxrp
        clr.b    rxcnt

        move.w   #0x0040,PICR            // UART interrupt at priority level 4
        move.b   #0x40,PIVR              // Interrupt base vector
        move.w   #0x2000,sr              // Enable all interrupts

        move.l   #message,d0
        bsr     puts
main_loop:
        bsr     getch                   // d0 = received character
        bsr     putch                   // echo it back
        bra     main_loop

puts:   move.l   a0,-(sp)
        move.l   d0,a0
1:      move.b   (a0)+,d0
        beq     2f
        bsr     putch
        bra     1b
2:      move.l   (sp)+,a0
        rts

uart_init:
        move.w   #0x000C,PBCNT           // PB2/PB3 as UART RXD/TXD
        move.b   #0x20,UCR               // Reset receiver
        move.b   #0x30,UCR               // Reset transmitter
        move.b   #0x4C,UIVR              // UART interrupt vector
        move.b   #0xE0,UACR              // Set 2, Timer mode, divide by 1
        move.b   #0x00,UBG1              // Baud rate MSB
        move.b   #0x03,UBG2              // 115200 baud
        move.b   #0,UISR                 // Clear interrupt status
        move.b   #0x10,UCR               // Reset mode register pointer
        move.b   #0x13,UMR1              // 8N1
        move.b   #0x07,UMR2              // 1 stop bit
        move.b   #0xDD,UCSR              // Clock select
        move.b   #0x05,UCR               // Enable TX and RX
        move.b   #0x02,UIMR              // Enable RxRDY interrupt; TxRDY added by putch
        rts

// ISR handles both RxRDY (USR bit 0) and TxRDY (USR bit 2)
uartisr:
        btst    #0,USR                  // Check RxRDY
        bne     uartisr_h
        btst    #2,USR                  // Check TxRDY
        beq     uartisr_e               // Spurious - exit without touching registers

uartisr_h:
        movem.l  d0-d1/a0,-(sp)
        move.b   #0,UIMR                 // Disable UART interrupts during critical section

        // RX: read byte from hardware into RX ring buffer
        btst    #0,USR
        beq     uartisr_norx
        move.b   URB,d0                  // Read received byte (clears RxRDY)
        cmp.b    #RX_BUF_SIZE,rxcnt
        bge     uartisr_norx            // Drop if buffer full
        lea     rxbuf,a0
        moveq  #0,d1
        move.b   rxwp,d1
        move.b   d0,(a0,d1)
        addq.b   #1,rxwp
        andi.b   #(RX_BUF_SIZE-1),rxwp
        addq.b   #1,rxcnt
uartisr_norx:

        // TX: send next byte from TX ring buffer
        tst.b    txcnt
        beq     uartisr_notx
        lea     txbuf,a0
        moveq  #0,d1
        move.b   txrp,d1
        move.b   (a0,d1),d0
        move.b   d0,UTB                  // Send character
        addq.b   #1,txrp
        andi.b   #(TX_BUF_SIZE-1),txrp
        subq.b   #1,txcnt
uartisr_notx:

        // Restore UIMR: always enable RxRDY (bit 1); TxRDY (bit 0) only if TX buffer non-empty
        moveq  #2,d1                   // RxRDY enable
        tst.b    txcnt
        beq     uartisr_ex
        addq.b   #1,d1                   // Also TxRDY enable
uartisr_ex:
        move.b   d1,UIMR
        movem.l  (sp)+,d0-d1/a0
uartisr_e:
        rte

// getch: blocking read from RX ring buffer; returns character in d0
getch:  movem.l  d1/a0,-(sp)
getch_w:
        tst.b    rxcnt
        beq     getch_w                 // Wait for data
        lea     rxbuf,a0
        moveq  #0,d1
        move.b   rxrp,d1
        move.b   (a0,d1),d0
        addq.b   #1,rxrp
        andi.b   #(RX_BUF_SIZE-1),rxrp
        subq.b   #1,rxcnt
        movem.l  (sp)+,d1/a0
        rts

// putch: write character in d0 to TX ring buffer (or direct if buffer empty and UART ready)
putch:  movem.l  d1/a0,-(sp)
4:      cmp.b    #TX_BUF_SIZE,txcnt
        bge     4b                      // Wait if buffer full
        tst.b    txcnt
        bne     1f
        btst    #2,USR                  // Check TxRDY
        beq     1f                      // Not ready - use buffer
        move.b   d0,UTB                  // Send directly (bypass buffer)
        move.b   #2,UIMR                 // Direct send: keep RxRDY only, no TxRDY needed
        bra     3f
1:      lea     txbuf,a0
        moveq  #0,d1
        move.b   txwp,d1
        move.b   d0,(a0,d1)
        addq.b   #1,txwp
        andi.b   #(TX_BUF_SIZE-1),txwp
        addq.b   #1,txcnt
2:      move.b   #3,UIMR                 // Buffered: enable both RxRDY and TxRDY interrupts
3:      movem.l  (sp)+,d1/a0
        rts
