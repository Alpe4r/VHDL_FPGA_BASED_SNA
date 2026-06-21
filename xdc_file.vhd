## Nexys A7-100T Kisit Dosyasi

## Sistem Saat Sinyali
set_property -dict { PACKAGE_PIN E3    IOSTANDARD LVCMOS33 } [get_ports { clk }];
create_clock -add -name sys_clk_pin -period 10.00 -waveform {0 5} [get_ports { clk }];

## Kullanici Giris Butonlari
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { reset }];
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { start_sweep_i }];

## Pmod JA - DAC SPI Baglantilari
set_property -dict { PACKAGE_PIN C17   IOSTANDARD LVCMOS33 } [get_ports { cs }];
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { mosi }];
set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { sclk }];

## JXADC - RF Detektor Analog Girisleri
set_property -dict { PACKAGE_PIN A14   IOSTANDARD LVCMOS33 } [get_ports { vauxn3 }];
set_property -dict { PACKAGE_PIN A13   IOSTANDARD LVCMOS33 } [get_ports { vauxp3 }];

## USB-UART Bilgisayar Haberlesme Arayuzu
set_property -dict { PACKAGE_PIN D4    IOSTANDARD LVCMOS33 } [get_ports { tx_pin }];

## Zamanlama Kisitlamalari
set_false_path -from [get_clocks sys_clk_pin] -to [get_ports sclk]
