/*
 * MC68307 Hello World with UART TX ISR
 * (C) Ole Saether 1995
 */
#include "mc68307.h"

#define TX_BUF_SIZE 32

        .bss
txwp:   .byte   0                       // Write pointer (0-TX_BUF_SIZE-1)
txrp:   .byte   0                       // Read pointer (0-TX_BUF_SIZE-1)
txcnt:  .byte   0                       // Number of chars in buffer
txbuf:  .fill   TX_BUF_SIZE             // TX_BUF_SIZE character circular buffer

        .text
        .org    0
        .long   0x188000                // Stack pointer
        .long   start                   // Reset vector

        .org    304
        .long   uartisr

message:
        .string "Hello World!\r\n"
.align 	4 
start:  move.w   #0x2700,sr              // Disable interrupts
        move.l   #0xff000010,SCR
        move.w   #0x0100,MBAR

        move.w   #0,WRR                  // Disable watch dog
        move.w   #0xc001,BR0             // ROM at address 0x000000
        move.w   #0x1fc2,OR0             // 128kB ROM, ignore FC's
        move.w   #0x0301,BR1             // RAM at address 0x180000
        move.w   #0x1fc0,OR1             // 128kB RAM, ignore FC's
        // This loop can be removed if you are not using the CMS micro module:
        move.w   #0xff,d0                // Clear the RAM CS latch
rloop:  move.b   0x180000,d1             
        dbra    d0,rloop

        bsr     uart_init        
        
        clr.b   txwp
        clr.b   txrp
        clr.b   txcnt
        
        move.w  #0x7070,PICR            // Set interrupt priority
        move.b  #0x40,PIVR              // Interrupt base vector
        move.w  #0x2000,sr              // Enable level 7 interrupts

        move.l  #message,d0
        bsr     puts
main_loop:
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
        move.w  #0x000C,PBCNT           // PB2 and PB3 used for UART
        move.b  #0x20,UCR               // Reset receiver
        move.b  #0x30,UCR               // Reset transmitter
        move.b  #0x4C,UIVR              // UART interrupt vector
        move.b  #0xE0,UACR              // Set 2, Timer mode, divided by 1 (CTMS=110)
        move.b  #0x00,UBG1              // MSB
        move.b  #0x03,UBG2              // 115200 baud
//        move.b  #0x30,UBG2              // 9600 baud
        move.b  #0,UISR                 // 0x10B is UIMR on write: mask all UART interrupts
        move.b  #0x10,UCR               // Reset mode register pointer
        move.b  #0x13,UMR1              // 8N1
        move.b  #0x07,UMR2              // 1 stop bit
        move.b  #0xDD,UCSR              // Clock select
        move.b  #0x04,UCR               // Enable transmitter ONLY
        move.b  #0x00,UIMR              // NO interrupts for now
        rts

uartisr:
        btst    #2,USR
        beq     2f

        move.b   #0,UIMR
        movem.l  d0-d1/a0,-(sp)

        tst.b    txcnt
        beq     1f                      // Branch if no data in buffer
        lea     txbuf,a0                // Buffer base address
        moveq  #0,d1
        move.b   txrp,d1                 // Load read pointer        
        move.b  (a0,d1),d0
        move.b   d0,UTB                  // Send the character
        addq.b   #1,txrp
        andi.b   #(TX_BUF_SIZE-1),txrp
        subq.b   #1,txcnt
        tst.b    txcnt
        beq     1f
        move.b   #1,UIMR                 // Enable TX interrupt for remaining chars
1:      movem.l  (sp)+,d0-d1/a0
2:      rte

putch:  movem.l  d1/a0,-(sp)
        cmp.b    #TX_BUF_SIZE,txcnt
        bge     3f                      // Buffer full
        tst.b    txcnt
        bne     1f
        btst    #2,USR                  // Check TXRDY bit
        beq     1f                      // Write to buffer if not TXRDY
        move.b  d0,UTB                  // Send first character (already in d0)
        bra     3f                      // Direct send: leave TxRDY interrupt disabled
1:      lea     txbuf,a0
        moveq  #0,d1
        move.b   txwp,d1
        move.b   d0,(a0,d1)              // Store character
        addq.b   #1,txwp
        andi.b   #(TX_BUF_SIZE-1),txwp
        addq.b   #1,txcnt
2:      move.b   #1,UIMR                 // Enable TX interrupt for remaining chars
3:      movem.l  (sp)+,d1/a0 
        rts
