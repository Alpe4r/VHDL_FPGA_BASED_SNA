# FPGA-Based Scalar Network Analyzer (SNA) Control System
## FPGA Tabanlı Skaler Network Analizörü (SNA) Kontrol Sistemi

This repository contains a fully synchronous hardware architecture designed on the **Digilent Nexys A7-100T (Artix-7)** FPGA platform. The system functions as a **Scalar Network Analyzer (SNA)** controller, managing high-speed frequency sweeping, analog data acquisition from an RF logarithmic detector, and real-time RF power (dBm) calculations.

Bu depo, **Digilent Nexys A7-100T (Artix-7)** FPGA platformu üzerinde tasarlanmış tam senkron bir donanım mimarisini içermektedir. Sistem, yüksek hızlı frekans taraması (sweep), harici bir RF logaritmik detektörden analog veri toplama ve gerçek zamanlı RF güç (dBm) hesaplamalarını yöneten bir **Skaler Network Analizörü (SNA)** kontrolörü olarak çalışır.

---

## 🌍 Language / Dil Seçimi
* [English Description (#english)](#english)
* [Türkçe Açıklama (#türkçe)](#türkçe)

---

<a name="english"></a>
## 🇬🇧 English

### Hardware Architecture & Data Flow
The system operates under a central Main Finite State Machine (FSM) utilizing strict handshake protocols across 5 core hardware modules to prevent metastability and data loss:

1. **Frequency Sweep Control (SPI Master):** Drives an external DAC (Digital-to-Analog Converter) chip via a high-speed SPI interface to step-scan the RF stimulus frequency.
2. **Analog Data Acquisition (XADC):** Digitizes the logarithmic analog voltage coming from the RF detector (DUT output) through the JXADC Pmod header (VAUX3 channel) with 12-bit resolution.
3. **Real-Time Power Calculation (dBm LUT):** Maps the 12-bit raw XADC data instantly into a 32-bit Q16 Fixed-Point dBm value using an on-chip 4096-element Look-Up Table (LUT) for maximum signal processing performance.
4. **Data Transmission Interface (UART TX):** Transmits the calculated RF power and frequency step data to a PC via the RS232 protocol for graphical visualization or terminal logging.
5. **Main FSM:** The central brain that synchronizes all operations under a 100 MHz system clock, ensuring zero phase and timing violations.

### Hardware Optimizations
* **Timing Closure Safeguard:** The computation-ready flag (`dbm_ready`) in the `dbm_calc` module is delayed by exactly 1 clock cycle. This prevents the Main FSM from capturing unstable data in the `WAIT_CALC` state, ensuring compliance with setup/hold times.
* **XADC DRP Pulse Generation:** To avoid locking up the Dynamic Reconfiguration Port (DRP) of the XADC IP, the `start_adc` trigger signal is processed through an edge detector to generate a stable, 1-clock-cycle wide `den_pulse`.

---

<a name="türkçe"></a>
## 🇹🇷 Türkçe

### Sistem Mimarisi ve Veri Akışı
Cihaz, sinyal kaçırmayı ve kararsızlığı (metastability) önleyen sıkı el sıkışma (handshake) protokollerine sahip, sonlu durum makinesi (Main FSM) kontrollü 5 ana donanım bloğundan oluşur:

1. **Frekans Tarama Kontrolü (SPI Master):** Test sinyalinin frekansını adım adım taramak amacıyla, harici bir DAC çipini yüksek hızlı SPI arayüzü üzerinden sürer.
2. **Analog Veri Toplama (XADC):** RF detektörden (DUT çıkışından) gelen logaritmik analog voltajı JXADC Pmod başlığı (VAUX3 kanalı) üzerinden 12-bit çözünürlükle dijitalleştirir.
3. **Gerçek Zamanlı Güç Hesaplama (dBm LUT):** XADC'den gelen 12-bitlik ham veriyi, 4096 elemanlı donanımsal bir Look-Up Table (LUT) kullanarak anında 32-bit Q16 Fixed-Point formatında dBm değerine dönüştürür.
4. **Veri Aktarım Arayüzü (UART TX):** Elde edilen RF güç ve frekans adımı verilerini, bilgisayara RS232 protokolü üzerinden aktarır.
5. **Main FSM:** Tüm bu süreçlerin 100 MHz ana saat frekansı altında, faz ve zamanlama hatası olmadan senkronize çalışmasını yöneten merkez beyindir.

### Donanımsal Optimizasyonlar
* **Zamanlama (Timing) Kararlılığı:** `dbm_calc` modülündeki hazır bayrağı (`dbm_ready`), FSM'in `WAIT_CALC` durumunda veri hattı tam oturmadan hatalı değer okumasını engellemek adına 1 clock cycle geciktirilerek optimize edilmiştir.
* **XADC DRP Güvenli Tetikleme:** XADC IP bloğunun DRP arayüzünün kilitlenmesini önlemek için, `start_adc` tetikleme sinyali bir kenar yakalayıcı (edge detector) üzerinden geçirilerek tam 1 clock cycle genişliğinde kararlı bir `den_pulse` sinyaline dönüştürülmüştür.

---

## 📌 Pin Mapping / Fiziksel Pin Eşleşmeleri (`constraints.xdc`)

| Port Name | FPGA Pin | Board Label | Function / İşlev |
| :--- | :--- | :--- | :--- |
| `clk` | E3 | CLK100MHZ | 100 MHz System Oscillator / Sistem Osilatörü |
| `reset` | N17 | BTNC (Center) | System Reset / Sistemi Sıfırlar |
| `start_sweep_i` | M18 | BTNU (Up) | Starts Frequency Sweep / Taramayı Başlatır |
| `cs` | C17 | PMOD JA - Pin 1 | SPI Chip Select (DAC) |
| `mosi` | D18 | PMOD JA - Pin 2 | SPI MOSI (Frequency Data) |
| `sclk` | G17 | PMOD JA - Pin 4 | SPI Serial Clock / Seri Saat |
| `vauxp3` | A13 | JXADC - Pin 1 | RF Detector Analog Input (+) / Canlı Giriş |
| `vauxn3` | A14 | JXADC - Pin 7 | RF Detector Analog Ground (-) / Toprak |
| `tx_pin` | D4 | USB-UART Bridge | FPGA UART Transmission Line / PC Aktarım Hattı |

---

## 🔬 Lab Guide / Kullanım Kılavuzu

1. **Program the Board:** Load the generated `.bit` file onto the Nexys A7 via Vivado Hardware Manager.
   * **Kartı Programlayın:** Üretilen `.bit` dosyasını Vivado Hardware Manager üzerinden Nexys A7 kartınıza yükleyin.
2. **Serial Connection:** Open a serial terminal (e.g., Putty, RealTerm) on your PC with a Baud Rate of 115200 or 9600.
   * **Seri Bağlantı:** Bilgisayarınızda bir Seri Port izleme yazılımı (Baud Rate: 115200 veya 9600) aktif edin.
3. **Execution:** Press **BTNC (Center)** to reset the SNA system, then press **BTNU (Up)** to initiate the scalar network analyzer sweep. The live power spectrum will begin logging onto your screen.
   * **Çalıştırma:** Kart üzerindeki **BTNC (Orta Buton)** ile sistemi resetleyin, ardından **BTNU (Yukarı Buton)** düğmesine bastığınız anda skaler tarama başlayacak ve ekranınıza RF güç spektrumu akacaktır.
