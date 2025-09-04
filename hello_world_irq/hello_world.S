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
start:  movew   #0x2700,sr              // Disable interrupts
        movel   #0xff000010,SCR
        movew   #0x0100,MBAR

        movew   #0,WRR                  // Disable watch dog
        movew   #0xc001,BR0             // ROM at address 0x000000
        movew   #0x1fc2,OR0             // 128kB ROM, ignore FC's
        movew   #0x0301,BR1             // RAM at address 0x180000
        movew   #0x1fc0,OR1             // 128kB RAM, ignore FC's
        // This loop can be removed if you are not using the CMS micro module:
        movew   #0xff,d0                // Clear the RAM CS latch
rloop:  moveb   0x180000,d1             
        dbra    d0,rloop

        bsr     uart_init        
        
        moveb  #0,txwp
        moveb  #0,txrp
        moveb  #0,txcnt
        
        movew  #0x7070,PICR            // Set interrupt priority
        moveb  #0x40,PIVR              // Interrupt base vector
        movew  #0x2000,sr              // Enable level 7 interrupts

        movel  #message,d0
        bsr     puts
main_loop:
        bra     main_loop

puts:   moveml  d1/a0,-(sp)
        movel   d0,a0
        moveql  #0,d1
1:      moveb   (a0, d1),d0
        cmpb    #0,d0
        beq     2f
        bsr     putch
        addql   #1,d1
        jmp     1b
2:      moveml  (sp)+,d1/a0
        rts

uart_init:
        movew  #0x000C,PBCNT           // PB2 and PB3 used for UART
        moveb  #0x20,UCR               // Reset receiver
        moveb  #0x30,UCR               // Reset transmitter
        moveb  #0x4C,UIVR              // UART interrupt vector
        moveb  #0xE0,UACR              // Set 2, Timer mode, divided by 1
        moveb  #0x00,UBG1              // MSB
        moveb  #0x03,UBG2              // 115200 baud
//        moveb  #0x30,UBG2              // 9600 baud
        moveb  #0,UISR                 // Clear interrupt status register
        moveb  #0x10,UCR               // Reset mode register pointer
        moveb  #0x13,UMR1              // 8N1
        moveb  #0x07,UMR2              // 1 stop bit
        moveb  #0xDD,UCSR              // Clock select
        moveb  #0x04,UCR               // Enable transmitter ONLY
        moveb  #0x00,UIMR              // NO interrupts for now
        rts

uartisr:
        btst    #2,USR
        beq     2f

        moveb   #0,UIMR
        moveml  d0-d1/a0,-(sp)

        tst.b   txcnt
        beq     1f                      // Branch if no data in buffer
        lea     txbuf,a0                // Buffer base address
        moveql  #0,d1
        moveb   txrp,d1                 // Load read pointer        
        moveb  (a0,d1),d0
        moveb   d0,UTB                  // Send the character
        addqb   #1,txrp
        andib   #(TX_BUF_SIZE-1),txrp
        subqb   #1,txcnt
        tst.b   txcnt
        beq     1f
        moveb   #1,UIMR                 // Enable TX interrupt for remaining chars
1:      moveml  (sp)+,d0-d1/a0
2:      rte

putch:  moveml  d1/a0,-(sp)
        cmpb    #TX_BUF_SIZE,txcnt
        bge     3f                      // Buffer full
        tstb    txcnt
        bne     1f
        btst    #2,USR                  // Check TXRDY bit
        beq     1f                      // Write to buffer if not TXRDY
        moveb  d0,UTB                  // Send first character (already in d0)
        bra     2f
1:      lea     txbuf,a0
        moveql  #0,d1
        moveb   txwp,d1
        moveb   d0,(a0,d1)              // Store character
        addqb   #1,txwp
        andib   #(TX_BUF_SIZE-1),txwp
        addqb   #1,txcnt
2:      moveb   #1,UIMR                 // Enable TX interrupt for remaining chars
3:      movem.l (sp)+,d1/a0 
        rts
