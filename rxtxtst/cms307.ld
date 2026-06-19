__DYNAMIC = 0;
MEMORY
	{
    ROM   :	org = 0x00000000, len = 128K
	 RAM   :	org = 0x00180000, len = 32K
	}

SECTIONS
{
  .text 0 : {
     _btext = .;
     *(.text)
     _etext = .;
   } >ROM  
  .data : {
     _bdata = .;
     *(.data)   
     _edata = .;
  } >RAM AT> ROM
  _sidata = LOADADDR(.data);
  .bss  SIZEOF(.data) + ADDR(.data) : {
     _bbss = .;
     *(.bss) *(COMMON) 
     _ebss = .;
  } >RAM
}
