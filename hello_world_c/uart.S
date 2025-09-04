//
 *
 * MC68307 UATT TX handler
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
        .global putch
putch:  moveml d0/a0,-(sp)
        cmp.b   #TX_BUF_SIZE,txcnt
        bge     3f                      // Buffer full */
        tst.b   txcnt
        bne     1f
        btst    #2,USR                  // Check TXRDY bit
        beq     1f                      // Write to buffer if not ready
        moveb   sp@(15),UTB             // Send first character
        bra     2f
1:      lea     txbuf,a0                // Buffer base address
        moveql  #0,d0
        moveb   txwp,d0                 // Get write pointer
        moveb   sp@(15),(a0,d0)         // Store character
        addqb   #1,txwp
        andib   #(TX_BUF_SIZE-1),txwp
        addqb   #1,txcnt
2:      moveb   #1,UIMR                 // Enable TX interrupt for remaining chars
3:      moveml (sp)+,d0/a0
        rts

        .global uart_init
uart_init:
        moveb   #0,txwp
        moveb   #0,txrp
        moveb   #0,txcnt
        movew   #0x000C,PBCNT           // PB2 and PB3 used for UART
        moveb   #0x20,UCR               // Reset receiver
        moveb   #0x30,UCR               // Reset transmitter
        moveb   #0x4C,UIVR              // UART interrupt vector
        moveb   #0xE0,UACR              // Set 2, Timer mode, divided by 1
        moveb   #0x00,UBG1              // MSB
        moveb   #0x03,UBG2              // 115200 baud
//        moveb  #0x30,UBG2              // 9600 baud
        moveb   #0,UISR                 // Clear interrupt status register
        moveb   #0x10,UCR               // Reset mode register pointer
        moveb   #0x13,UMR1              // 8N1
        moveb   #0x07,UMR2              // 1 stop bit
        moveb   #0xDD,UCSR              // Clock select
        moveb   #0x04,UCR               // Enable transmitter ONLY
        moveb   #0x00,UIMR              // NO interrupts for now
        rts

.align 4
        .global uartisr
uartisr:
        btst    #2,USR                  // Is it a TX interrupt?
        beq     2f

        moveb   #0,UIMR
        moveml  d0-d1/a0,-(sp)          // Save registers */
        tstb    txcnt
        beq     1f                      // No data in buffer */
        lea     txbuf,a0                // Buffer base address */
        moveql  #0,d1                   // Clear all 32 bits of d1 */
        moveb   txrp,d1                 // Load read pointer */
        moveb   (a0,d1),d0
        moveb   d0,UTB                  // Send the actual character */       
        addqb   #1,txrp
        andib   #(TX_BUF_SIZE-1),txrp
        subqb   #1,txcnt
        tstb    txcnt
        beq     1f
        moveb   #1,UIMR                 // Enable TX interrupt for remaining chars */
1:      moveml  (sp)+,d0-d1/a0          // Restore registers */
2:      rte
