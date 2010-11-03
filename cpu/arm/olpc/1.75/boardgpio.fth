purpose: Board-specific setup details - pin assigments, etc.

: set-camera-domain-voltage
   aib-unlock
   h# d401e80c l@  4 or   ( n )  \ Set 1.8V selector bit in AIB_GPIO2_IO
   aib-unlock
   h# d401e80c l!
;

: set-gpio-directions  ( -- )
   3  h# 38 clock-unit-pa +  l!  \ Enable clocks in GPIO clock reset register
   
   d# 01 gpio-dir-out  \ EN_USB_PWR
   d# 04 gpio-dir-out  \ COMPASS_SCL
   d# 08 gpio-dir-out  \ AUDIO_RESET#
   d# 10 gpio-dir-out  \ LED_STORAGE
   d# 11 gpio-dir-out  \ VID2
   d# 33 gpio-dir-out  \ EN_MSD_PWR
   d# 34 gpio-dir-out  \ EN_WLAN_PWR
   d# 35 gpio-dir-out  \ EN_SD_PWR
   d# 57 gpio-set      \ WLAN_PD#
   d# 57 gpio-dir-out  \ WLAN_PD#
   d# 58 gpio-set      \ WLAN_RESET#
   d# 58 gpio-dir-out  \ WLAN_RESET#
   d# 73 gpio-dir-out  \ CAM_RST

   d# 125 gpio-set
   d# 125 gpio-dir-out  \ EC_SPI_ACK
   d# 145 gpio-dir-out  \ EN_CAM_PWR
   d# 146 gpio-dir-out  \ HUB_RESET#
   d# 151 gpio-dir-out  \ DCONLOAD
   d# 155 gpio-clr
   d# 155 gpio-dir-out  \ EC_SPI_CMD

   d# 162 gpio-dir-out  \ DCON_SCL
   d# 163 gpio-dir-out  \ DCON_SDA
;

create mfpr-table
   no-update, \ GPIO_00 - Not connected (TP57)
   0 af,      \ GPIO_01 - EN_USB_PWR
   no-update, \ GPIO_02 - Not connected (TP54)
   no-update, \ GPIO_03 - Not connected (TP53)
   0 af,      \ GPIO_04 - COMPASS_SCL (bitbang)
   0 af,      \ GPIO_05 - COMPASS_SDA (bitbang)
   0 af,      \ GPIO_06 - G_SENSOR_INT
   0 af,      \ GPIO_07 - AUDIO_IRQ#
   0 af,      \ GPIO_08 - AUDIO_RESET#
   0 af,      \ GPIO_09 - COMPASS_INT
   0 af,      \ GPIO_10 - LED_STORAGE
   0 af,      \ GPIO_11 - VID2
   no-update, \ GPIO_12 - Not connected (TP52)
   no-update, \ GPIO_13 - Not connected (TP116)
   no-update, \ GPIO_14 - Not connected (TP64)
   no-update, \ GPIO_15 - Not connected (TP55)
   0 af,      \ GPIO_16 - KEY_IN_1
   0 af,      \ GPIO_17 - KEY_IN_2
   0 af,      \ GPIO_18 - KEY_IN_3
   0 af,      \ GPIO_19 - KEY_IN_4
   0 af,      \ GPIO_20 - KEY_IN_5
   no-update, \ GPIO_21 - Not connected (TP63)
   no-update, \ GPIO_22 - Not connected (TP118)
   no-update, \ GPIO_23 - Not connected (TP61)
   1 af,      \ GPIO_24 - I2S_SYSCLK   (Codec)
   1 af,      \ GPIO_25 - I2S_BITCLK   (Codec)
   1 af,      \ GPIO_26 - I2S_SYNC     (Codec)
   1 af,      \ GPIO_27 - I2S_DATA_OUT (Codec)
   1 af,      \ GPIO_28 - I2S_DATA_IN  (Codec)
   1 af,      \ GPIO_29 - UART1_RXD  (debug board)
   1 af,      \ GPIO_30 - UART1_TXD  (debug board)
   0 af,      \ GPIO_31 - SD_CD# (via GPIO)
   no-update, \ GPIO_32 - Not connected (TP58)
   0 af,      \ GPIO_33 - EN_MSD_PWR
   0 af,      \ GPIO_34 - EN_WLAN_PWR
   0 af,      \ GPIO_35 - EN_SD_PWR
   no-update, \ GPIO_36 - Not connected (TP115)
   1 af,      \ GPIO_37 - SDDA_D3
   1 af,      \ GPIO_38 - SDDA_D2
   1 af,      \ GPIO_39 - SDDA_D1
   1 af,      \ GPIO_40 - SDDA_D0
   1 af,      \ GPIO_41 - SDDA_CMD
   1 af,      \ GPIO_42 - SDDA_CLK
   3 af,      \ GPIO_43 - SPI_MISO  (SSP1) (OFW Boot FLASH)
   3 af,      \ GPIO_44 - SPI_MOSI
   3 af,      \ GPIO_45 - SPI_CLK
   3 af,      \ GPIO_46 - SPI_FRM
   3 af,      \ GPIO_47 - G_SENSOR_SDL (TWSI6)
   3 af,      \ GPIO_48 - G_SENSOR_SDA
   no-update, \ GPIO_49 - Not connected (TP62)
   no-update, \ GPIO_50 - Not connected (TP114)
   no-update, \ GPIO_51 - Not connected (TP59)
   no-update, \ GPIO_52 - Not connected (TP113)
   2 af,      \ GPIO_53 - RTC_SCK (TWSI2) if R124 populated
   2 af,      \ GPIO_54 - RTC_SDA (TWSI2) if R125 populated
\  no-update, \ GPIO_53 - Not connected if nopop R124 to use TWSI6 for RTC
\  no-update, \ GPIO_54 - Not connected if nopop R125 to use TWSI6 for RTC
   no-update, \ GPIO_55 - Not connected (TP51)
   no-update, \ GPIO_56 - Not connected (TP60)
   0 af,      \ GPIO_57 - WLAN_PD#
   0 af,      \ GPIO_58 - WLAN_RESET#

   1 af,      \ GPIO_59 - PIXDATA7
   1 af,      \ GPIO_60 - PIXDATA6
   1 af,      \ GPIO_61 - PIXDATA5
   1 af,      \ GPIO_62 - PIXDATA4
   1 af,      \ GPIO_63 - PIXDATA3
   1 af,      \ GPIO_64 - PIXDATA2
   1 af,      \ GPIO_65 - PIXDATA1
   1 af,      \ GPIO_66 - PIXDATA0
   1 af,      \ GPIO_67 - CAM_HSYNC
   1 af,      \ GPIO_68 - CAM_VSYNC
   1 af,      \ GPIO_69 - PIXMCLK
   1 af,      \ GPIO_70 - PIXCLK

   1 af,      \ GPIO_71 - EC_SCL (TWSI3)
   1 af,      \ GPIO_72 - EC_SDA 
   0 af,      \ GPIO_73 - CAM_RST (use as GPIO out)

   1 af,      \ GPIO_74 - GFVSYNC
   1 af,      \ GPIO_75 - GFHSYNC
   1 af,      \ GPIO_76 - GFDOTCLK
   1 af,      \ GPIO_77 - GF_LDE
   1 af,      \ GPIO_78 - GFRDATA0
   1 af,      \ GPIO_79 - GFRDATA1
   1 af,      \ GPIO_80 - GFRDATA2
   1 af,      \ GPIO_81 - GFRDATA3
   1 af,      \ GPIO_82 - GFRDATA4
   1 af,      \ GPIO_83 - GFRDATA5
   1 af,      \ GPIO_84 - GFGDATA0
   1 af,      \ GPIO_85 - GFGDATA1
   1 af,      \ GPIO_86 - GFGDATA2
   1 af,      \ GPIO_87 - GFGDATA3
   1 af,      \ GPIO_88 - GFGDATA4
   1 af,      \ GPIO_89 - GFGDATA5
   1 af,      \ GPIO_90 - GFBDATA0
   1 af,      \ GPIO_91 - GFBDATA1
   1 af,      \ GPIO_92 - GFBDATA2
   1 af,      \ GPIO_93 - GFBDATA3
   1 af,      \ GPIO_94 - GFBDATA4
   1 af,      \ GPIO_95 - GFBDATA5

   no-update, \ GPIO_96  - Not connected (TP112)

   no-update, \ GPIO_97  - Not connected (R100 nopop) if we use TWSI2 for RTC
   no-update, \ GPIO_98  - Not connected (R106 nopop) if we use TWSI2 for RTC
\  2 af,      \ GPIO_97  - RTC_SCK (TWSI6) if R100 populated
\  2 af,      \ GPIO_98  - RTC_SDA (TWSI6) if R106 populated

   0 af,      \ GPIO_99  - TOUCH_SCR_INT
   0 af,      \ GPIO_100 - DCONSTAT0
   0 af,      \ GPIO_101 - DCONSTAT1

   no-update, \ GPIO_102 - (USIM_CLK) - Not connected (TP48)
   no-update, \ GPIO_103 - (USIM_IO) - Not connected (TP50)

   0 af,      \ GPIO_104 - ND_IO[7]
   0 af,      \ GPIO_105 - ND_IO[6]
   0 af,      \ GPIO_106 - ND_IO[5]
   0 af,      \ GPIO_107 - ND_IO[4]

   1 af,      \ GPIO_108 - CAM_SDL - Use as GPIO, bitbang
   1 af,      \ GPIO_109 - CAM_SDA - Use as GPIO, bitbang

   1 af,      \ GPIO_110 - (ND_IO[13]) - Not connected (TP43)
   1 af,      \ GPIO_111 - (ND_IO[8])  - Not connected (TP108)
   0 af,      \ GPIO_112 - ND_RDY[0]
   3 af,      \ GPIO_113 - (SM_RDY)    - MSD_CMD (externally pulled up)
   1 af,      \ GPIO_114 - G_CLK_OUT - Not connected (TP93)

   4 af,      \ GPIO_115 - UART3_TXD (J4)
   4 af,      \ GPIO_116 - UART3_RXD (J4)
   3 af,      \ GPIO_117 - UART4_RXD - Not connected (TP117)
   3 af,      \ GPIO_118 - UART4_TXD - Not connected (TP56)
   3 af,      \ GPIO_119 - SDI_CLK  (SSP3)
   3 af,      \ GPIO_120 - SDI_CS#
   3 af,      \ GPIO_121 - SDI_MOSI
   3 af,      \ GPIO_122 - SDI_MISO

   3 af,      \ GPIO_123 - 32 KHz_CLK_OUT - Not connected (TP92)

   0 af,      \ GPIO_124 - DCONIRQ
\   0 af,      \ GPIO_125 - EC_SPI_ACK
   0 pull-up, \ GPIO_125 - EC_SPI_ACK

   3 pull-up, \ GPIO_126 - MSD_DATA2
   3 pull-up, \ GPIO_127 - MSD_DATA0
   0 af,      \ GPIO_128 - EB_MODE#
   0 af,      \ GPIO_129 - LID_SW#
   3 pull-up, \ GPIO_130 - MSD_DATA3
   1 +fast pull-up,      \ GPIO_131 - SD_DATA3
   1 +fast pull-up,      \ GPIO_132 - SD_DATA2
   1 +fast pull-up,      \ GPIO_133 - SD_DATA1
   1 +fast pull-up,      \ GPIO_134 - SD_DATA0
   3 pull-up, \ GPIO_135 - MSD_DATA1
\  1 +fast pull-up,      \ GPIO_136 - SD_CMD
   1 +fast af,           \ GPIO_136 - SD_CMD  - CMD is pulled up externally
   no-update, \ GPIO_137 - Not connected (TP111)
   3 pull-up, \ GPIO_138 - MSD_CLK
   1 +fast pull-up,      \ GPIO_139 - SD_CLK
   no-update, \ GPIO_140 - Not connected if R130 is nopop
\  1 af,      \ GPIO_140 - (SD_CD# if R130 is populated)
   1 af,      \ GPIO_141 - SD_WP

   no-update, \ GPIO_142 - (USIM_RSTn) - Not connected (TP49)
   0 af,      \ GPIO_143 - ND_CS0#
   0 af,      \ GPIO_144 - ND_CS1#
   1 af,      \ GPIO_145 - EN_CAM_PWR
   1 af,      \ GPIO_146 - HUB_RESET#

   0 af,      \ GPIO_147 - ND_WE_N
   0 af,      \ GPIO_148 - ND_RE_N
   0 af,      \ GPIO_149 - ND_CLE
   0 af,      \ GPIO_150 - ND_ALE
   1 af,      \ GPIO_151 - DCONLOAD
   1 af,      \ GPIO_152 - (SM_BELn) - Not connected (TP40)
   1 af,      \ GPIO_153 - (SM_BEHn) - Not connected (TP105)
   0 af,      \ GPIO_154 - (SM_INT) - EC_IRQ#
   1 pull-dn, \ GPIO_155 - (EXT_DMA_REQ0) - EC_SPI_CMD
   no-update, \ GPIO_156 - PRI_TDI (JTAG)
   no-update, \ GPIO_157 - PRI_TDS (JTAG)
   no-update, \ GPIO_158 - PRI_TDK (JTAG)
   no-update, \ GPIO_159 - PRI_TDO (JTAG)
   0 af,      \ GPIO_160 - ND_RDY[1]
   1 af,      \ GPIO_161 - ND_IO[12] - Not connected (TP 44)
   1 af,      \ GPIO_162 - (ND_IO[11]) - DCON_SCL
   1 pull-up, \ GPIO_163 - (ND_IO[10]) - DCON_SDA
   1 af,      \ GPIO_164 - (ND_IO[9]) - Not connected (TP106)
   0 af,      \ GPIO_165 - ND_IO[3]
   0 af,      \ GPIO_166 - ND_IO[2]
   0 af,      \ GPIO_167 - ND_IO[1]
   0 af,      \ GPIO_168 - ND_IO[0]

: init-mfprs
   d# 169 0  do
      mfpr-table i wa+ w@   ( code )
      dup 8 =  if           ( code )
         drop               ( )
      else                  ( code )
         i af!              ( )
      then
   loop
;
