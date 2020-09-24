OUTPUT_ARCH(mips)
OUTPUT_FORMAT(elf32-tradlittlemips)
SECTIONS
{
  . = 0x80100000;
  .text : { *(.text_inflate) }
  .text_spare : { *(.text) }
}
