# FPGA Tabanlı RF Tarama (Sweep) ve dBm Hesaplama Sistemi

Bu proje, **Digilent Nexys A7-100T (Artix-7)** FPGA geliştirme kartı kullanılarak, harici bir RF Logaritmik Detektörden alınan analog sinyallerin işlenmesi, dBm değerine dönüştürülmesi ve sonuçların gerçek zamanlı olarak PC'ye aktarılması amacıyla geliştirilmiş tam senkron bir donanım mimarisidir.

## Mimarinin Genel Yapısı ve Çalışma Mantığı

Sistem, bir ana sonlu durum makinesi (Main FSM) kontrolünde 5 temel donanım modülünün el sıkışma (handshake) protokolleriyle haberleşmesiyle çalışır:

1. **XADC Modülü:** RF detektörden gelen analog voltajı JXADC Pmod portu üzerinden (VAUX3 kanalı) okur ve 12-bitlik dijital veriye dönüştürür.
2. **dBm Hesaplama (LUT) Modülü:** XADC'den gelen 12-bitlik ham veriyi, içerisindeki 4096 elemanlı Look-Up Table (LUT) kullanarak hızlıca 32-bit Q16 Fixed-Point formatında dBm değerine dönüştürür.
3. **SPI Master Modülü:** Frekans taramasını kontrol etmek amacıyla harici bir DAC (Dijitalden Analoga Dönüştürücü) çipini sürer.
4. **UART TX Modülü:** Hesaplanan 32-bitlik hassas dBm verilerini, bilgisayar ortamında (Putty, RealTerm vb.) görüntülenebilmesi için RS232 protokolü üzerinden PC'ye aktarır.
5. **Main FSM:** Tüm bu modüllerin zamanlamasını, veri kaçırmadan ve sinyal kararsızlığı (metastability) yaşamadan çalışmasını sağlayan projenin beynidir.

---

## Donanım Özellikleri ve Uygulanan Optimizasyonlar

* **Geliştirme Kartı:** Digilent Nexys A7-100T (XC7A100T-1CSG324C)
* **Sistem Frekansı:** 100 MHz (Ana Saat Sinyali)
* **Zamanlama (Timing) İyileştirmesi:** FSM'in `WAIT_CALC` durumunda kararsız veya hatalı veri yakalamasını önlemek amacıyla, `dbm_calc` modülündeki hazır bayrağı (`dbm_ready`) 1 saat çevrimi (clock cycle) geciktirilerek veri hattının tam oturması sağlanmıştır.
* **XADC DRP Güvenliği:** XADC IP'sinin Dynamic Reconfiguration Port (DRP) arayüzünü kilitlememesi için `start_adc` tetiklemesinden kenar yakalayıcı (edge detector) ile 1 saat çevrimlik kararlı bir `den_pulse` üretilmiştir.

---

## Fiziksel Bağlantı Şeması (Pinout)

Sistem kart üzerindeki şu fiziksel pinlere map edilmiştir (`constraints.xdc`):

| Port İsmi | FPGA Pini | Kart Üzerindeki Karşılığı | Açıklama |
| :--- | :--- | :--- | :--- |
| `clk` | E3 | CLK100MHZ | 100 MHz Sabit Osilatör |
| `reset` | N17 | BTNC (Orta Buton) | Sistemi Başlangıç Durumuna Getirir |
| `start_sweep_i` | M18 | BTNU (Yukarı Buton) | Frekans Taramasını Başlatır |
| `cs` | C17 | PMOD JA - Pin 1 | DAC Çipi SPI Chip Select |
| `mosi` | D18 | PMOD JA - Pin 2 | DAC Çipi SPI Master Out Slave In |
| `sclk` | G17 | PMOD JA - Pin 4 | DAC Çipi SPI Saat Sinyali |
| `vauxp3` | A13 | JXADC - Pin 1 | RF Detektör Analog (+) Girişi |
| `vauxn3` | A14 | JXADC - Pin 7 | RF Detektör Analog (-) / GND Girişi |
| `tx_pin` | D4 | USB-UART Bridge | PC'ye Veri Gönderme Hattı (TX) |

---

## Kullanım Talimatı

1. Projenin `.bit` dosyasını (Bitstream) Vivado Hardware Manager üzerinden Nexys A7 kartınıza yükleyin.
2. Kartı bilgisayara bağladığınız USB kablosu üzerinden bir Seri Port izleme programı (Baud Rate: 115200 veya 9600) açın.
3. Kart üzerindeki **BTNC (Orta Buton)** ile sistemi resetleyin.
4. **BTNU (Yukarı Buton)** düğmesine bastığınız anda tarama başlayacak ve bilgisayar ekranınıza gerçek zamanlı dBm verileri akacaktır.
