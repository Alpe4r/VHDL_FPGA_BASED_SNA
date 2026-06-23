Usta, "lale" kelimesi için kusura bakma, yorgunluğuna ve stresine veriyorum; canın sağ olsun. İşin bitirme projesi stresiyle birleşince Vivado insanı gerçekten çıldırtır, çok haklısın.

Hadi gel bu işi tamamen kapatalım. İstediğin gibi repository structure (klasör yapısı), fiziksel pin eşleşmeleri, donanımsal optimizasyonlar ve laboratuvar kılavuzu dahil tüm o kapsamlı detayları, GitHub'da düzgün görünmesi için kod bloksuz ve resimsiz, doğrudan Markdown formatında tek parça halinde veriyorum.

Aşağıdaki metni olduğu gibi kopyalayıp GitHub'daki README.md dosyanın içine yapıştırabilirsin:
FPGA-Based Scalar Network Analyzer (SNA) Control System
FPGA Tabanlı Skaler Network Analizörü (SNA) Kontrol Sistemi

This repository contains a fully synchronous hardware architecture designed on the Digilent Nexys A7-100T (Artix-7) FPGA platform. The system functions as a Scalar Network Analyzer (SNA) controller, managing high-speed frequency sweeping, analog data acquisition from an RF logarithmic detector, and real-time RF power (dBm) calculations.

Bu depo, Digilent Nexys A7-100T (Artix-7) FPGA platformu üzerinde tasarlanmış tam senkron bir donanım mimarisini içermektedir. Sistem, yüksek hızlı frekans taraması (sweep), harici bir RF logaritmik detektörden analog veri toplama ve gerçek zamanlı RF güç (dBm) hesaplamalarını yöneten bir Skaler Network Analizörü (SNA) kontrolörü olarak çalışır.
🌍 Language / Dil Seçimi

    English Description (#english)

    Türkçe Açıklama (#türkçe)

🇬🇧 English
🏛 Comprehensive System Architecture & Data Flow

The architecture operates under a centralized control paradigm managed by the Main Finite State Machine (FSM). To eliminate metastability, prevent phase mismatches, and guarantee zero data loss across distinct clock-domain boundaries, strict hardware-level handshake protocols are enforced among the core modules:
Frequency Sweep Control (SPI Master Module)

Manages the precise stepping of the RF stimulus frequency. It generates high-speed serial clock (sclk), chip select (cs), and master-output-slave-input (mosi) signals. It interfaces directly with an external DAC (Digital-to-Analog Converter) chip to generate the tuning voltage required for the Voltage-Controlled Oscillator (VCO). It utilizes a spi_busy feedback line to stall the Main FSM until the current transmission frame is fully completed.
Analog Data Acquisition (XADC Wrapper Module)

Responsible for digitizing the analog voltage response received from the RF logarithmic detector (representing the Device Under Test - DUT output). It routes the analog differential signal through the hardware-isolated JXADC Pmod header utilizing the dedicated VAUX3 auxiliary channel (vauxp3 / vauxn3). It operates with a 12-bit successive approximation register (SAR) resolution and asserts a data_ready flag immediately upon the completion of a conversion cycle to broadcast data validity to the rest of the pipeline.
Real-Time Power Calculation (dBm LUT Module)

Performs instantaneous digital signal conversion from raw binary voltages to absolute logarithmic power levels. It direct-maps the 12-bit raw XADC output (adc_data_out) into a 32-bit Q16.16 Fixed-Point dBm value (dbm_val). It implements a hardware-synthesized, on-chip 4096-element Look-Up Table (LUT) to avoid clock-heavy division and math operations, keeping the throughput at maximum execution speed.
Data Transmission Interface (UART TX Module)

Acts as the primary telemetry bridge between the FPGA fabric and the host PC. It packages the calculated 32-bit RF power along with the current frequency step data into standard 8-bit frames (data_in). It transmits data asynchronously using the RS232 protocol via the onboard USB-UART bridge. It controls data pacing using a tx_busy status line, preventing the Main FSM from overwriting the transmission registers during active serialization.
Main Finite State Machine (Central Brain)

Orchestrates the global scheduling and operational synchronization of all sub-modules under a single unified 100 MHz clock tree. It sequentially triggers the SPI frequency adjustment, commands the XADC to start sampling via start_adc, monitors calculation flags, and schedules UART transmission bursts while ensuring zero timing violations.
⚡ Detailed Hardware Optimizations

    Timing Closure & Setup/Hold Safeguards: In the dbm_calc module, the computation-ready flag (dbm_ready) is intentionally delayed by exactly one clock cycle relative to the valid data output. This pipelining technique prevents the Main FSM from capturing unstable or transitioning bus states while evaluating the WAIT_CALC state, drastically improving timing slack and preventing setup/hold time violations.

    XADC DRP Pulse Generation & Edge Detection: The internal Dynamic Reconfiguration Port (DRP) interface of the XADC primitive requires precise single-cycle control inputs. To prevent latching or locking up the DRP, the global start_adc trigger signal from the FSM is passed through an internal synchronous edge detector. This circuit converts a multi-cycle enable signal into a stable, exactly 1-clock-cycle wide den_pulse (DRP Enable Pulse).

    Clock & Reset Conditioning: The system utilizes the Xilinx Clocking Wizard IP block to condition the incoming 100 MHz clock from the physical crystal oscillator, removing jitter and phase noise. The reset logic is tied to a Processor System Reset primitive. The FSM and computing logic are held in reset until the clock wizard asserts its locked signal, guaranteeing that no logic operates under unstable or un-synchronized clock phases.

🇹🇷 Türkçe
🏛 Kapsamlı Sistem Mimarisi ve Veri Akışı

Sistem mimarisi, Merkezi Sonlu Durum Makinesi (Main FSM) tarafından yönetilen senkron bir kontrol paradigması altında çalışır. Donanım seviyesindeki modüller arası sinyal kaçırma risklerini, faz uyumsuzluklarını ve kararsızlık (metastability) durumlarını tamamen ortadan kaldırmak için core donanım blokları arasında sıkı el sıkışma (handshake) protokolleri uygulanır:
Frekans Tarama Kontrolü (SPI Master Modülü)

RF sinyal kaynağının frekansının adım adım ve hassas bir şekilde taranmasını yöneter. Yüksek hızlı seri saat (sclk), çip seçme (cs) ve veri hattı (mosi) sinyallerini üretir. Gerilim Kontrollü Osilatörün (VCO) ihtiyaç duyduğu ayar voltajını oluşturmak üzere harici bir DAC (Dijital-Analog Dönüştürücü) çipini doğrudan sürer. Sahip olduğu spi_busy geri bildirim hattı sayesinde, mevcut veri paketi aktarımı tamamen bitene kadar Main FSM'i güvenli bir şekilde bekleme durumunda tutar.
Analog Veri Toplama (XADC Wrapper Modülü)

RF logaritmik detektörden (Test Edilen Cihaz - DUT çıkışından) gelen analog voltaj cevabını dijitalleştirmekten sorumludur. Analog diferansiyel sinyali, donanımsal olarak izole edilmiş JXADC Pmod konnektörü üzerindeki adanmış harici VAUX3 yardımcı kanalından (vauxp3 / vauxn3) içeri alır. 12-bit çözünürlüğe sahip bir ardışık yaklaşımlı (SAR) ADC mimarisi işletir. Her bir dönüşüm döngüsü tamamlandığında anında bir data_ready (veri hazır) bayrağı kaldırarak hattaki verinin geçerli olduğunu tüm sisteme duyurur.
Gerçek Zamanlı Güç Hesaplama (dBm LUT Modülü)

XADC'den gelen ham binary voltaj değerlerini, mutlak logaritmik güç seviyelerine (dBm) dönüştüren anlık dijital sinyal işleme bloğudur. 12-bitlik ham XADC verisini (adc_data_out) girdi olarak alır ve bunu doğrudan 32-bitlik Q16.16 Fixed-Point (Sabit Noktalı) dBm değerine (dbm_val) dönüştürür. Saat frekansını tüketen ağır bölme ve matematiksel işlemlerden kaçınmak amacıyla donanıma gömülü, 4096 elemanlı bir Look-Up Table (LUT) mimarisi kullanır; böylece işlem hattı verimliliğini maksimumda tutar.
Veri Aktarım Arayüzü (UART TX Modülü)

FPGA iç donanımı ile bilgisayar (Host PC) arasındaki ana telemetri köprüsüdür. Hesaplanan 32-bitlik RF güç değerini ve mevcut frekans adımı bilgisini standart 8-bitlik paketler halinde (data_in) düzenler. Kart üzerindeki entegre USB-UART köprüsü vasıtasıyla verileri RS232 protokolü üzerinden bilgisayara asenkron olarak aktarır. Sahip olduğun tx_busy durum hattı ile veri hızını dengeler ve UART serileştirme işlemi devam ederken Main FSM'in veri yazma yazmaçlarını (registers) ezmesini engeller.
Merkezi Sonlu Durum Makinesi (Main FSM - Sistem Beyni)

Tüm alt modüllerin küresel zamanlamasını ve operasyonel senkronizasyonunu 100 MHz'lik tek bir ana saat ağacı altında koordine eder. SPI üzerinden frekans adımını tetikler, XADC'ye start_adc sinyaliyle örnekleme emri verir, hesaplama modüllerinin bayraklarını izler ve UART üzerinden veri gönderim paketlerini organize ederken sistemde sıfır zamanlama hatası olmasını garanti altına alır.
⚡ Detaylı Donanımsal Optimizasyonlar

    Zamanlama Kararlılığı ve Setup/Hold Koruması: dbm_calc modülü içerisinde üretilen hesaplama hazır bayrağı (dbm_ready), geçerli veri çıkışına kıyasla kasıtlı olarak tam 1 saat çevrimi (clock cycle) geciktirilmiştir. Bu boru hattı (pipelining) tekniği, Main FSM'in WAIT_CALC durumundayken veri veri hattı tam oturmadan kararsız veya geçiş evresindeki hatalı bit değerlerini okumasını kesin olarak engeller. Bu sayede Setup/Hold zamanlama toleransları (slack) optimize edilmiş olur.

    XADC DRP Güvenli Tetikleme ve Kenar Yakalayıcı: XADC IP çekirdeğinin dahili Dinamik Yeniden Yapılandırma Portu (DRP), kararlı çalışabilmek için tam olarak tek bir çevrim genişliğinde kontrol girişlerine ihtiyaç duyar. DRP arayüzünün kilitlenmesini veya sürekli aktif kalmasını önlemek amacıyla, FSM'den gelen start_adc tetikleme sinyali dahili bir senkron kenar yakalayıcı (edge detector) devresinden geçirilir. Bu devre, çoklu çevrim süren sinyali tam 1 saat çevrimi genişliğinde kararlı bir den_pulse (DRP Yetkilendirme Palsi) sinyaline indirger.

    Saat ve Reset Şartlandırma Mekanizması: Sistem, fiziksel kristal osilatörden gelen 100 MHz'lik ham saati, faz gürültüsünü (jitter) temizlemek amacıyla Xilinx Clocking Wizard IP bloğından geçirir. Reset mantığı ise bir Processor System Reset primitifine bağlıdır. Clock wizard donanımı frekansı sabitleyip locked (saat oturdu) sinyalini kaldırana kadar tüm FSM ve hesaplama mantığı reset durumunda tutulur. Bu sayede kararsız saat fazlarında hiçbir lojik kapının çalışmaması güvenceye alınır.

📂 Repository Structure / Proje Klasör Yapısı

    src/main_fsm.vhd -> Central Control FSM (Merkezi Kontrolcü)

    src/spi_master.vhd -> DAC SPI Driver Module (DAC SPI Sürücü Modülü)

    src/xadc_module.vhd -> XADC Primitive Wrapper (XADC Çekirdek Sarmalayıcı)

    src/dbm_calc.vhd -> Q16.16 Fixed-Point LUT Logic (Sabit Noktalı Hesaplama Bloğu)

    src/uart_tx.vhd -> RS232 Communication Module (UART Veri Aktarım Modülü)

    constraints/constraints.xdc -> Nexys A7 Physical Pin Mappings (Fiziksel Pin Atamaları)

    README.md -> Project Documentation (Proje Dokümantasyonu)

📌 Pin Mapping / Fiziksel Pin Eşleşmeleri (constraints.xdc)

    Port Name: clk

        FPGA Pin: E3

        Board Label: CLK100MHZ

        Function: 100 MHz System Oscillator / Sistem Osilatörü

    Port Name: reset

        FPGA Pin: N17

        Board Label: BTNC (Center)

        Function: System Reset / Sistemi Sıfırlar

    Port Name: start_sweep_i

        FPGA Pin: M18

        Board Label: BTNU (Up)

        Function: Starts Frequency Sweep / Taramayı Başlatır

    Port Name: cs

        FPGA Pin: C17

        Board Label: PMOD JA - Pin 1

        Function: SPI Chip Select (DAC)

    Port Name: mosi

        FPGA Pin: D18

        Board Label: PMOD JA - Pin 2

        Function: SPI MOSI (Frequency Data)

    Port Name: sclk

        FPGA Pin: G17

        Board Label: PMOD JA - Pin 4

        Function: SPI Serial Clock / Seri Saat

    Port Name: vauxp3

        FPGA Pin: A13

        Board Label: JXADC - Pin 1

        Function: RF Detector Analog Input (+) / Canlı Giriş

    Port Name: vauxn3

        FPGA Pin: A14

        Board Label: JXADC - Pin 7

        Function: RF Detector Analog Ground (-) / Toprak

    Port Name: tx_pin

        FPGA Pin: D4

        Board Label: USB-UART Bridge

        Function: FPGA UART Transmission Line / PC Aktarım Hattı

🔬 Lab Guide / Kullanım Kılavuzu
1. Program the Board / Kartı Programlayın

Load the generated .bit file onto the Nexys A7 via Vivado Hardware Manager. Ensure that the DONE LED lights up on the board.

    Üretilen .bit dosyasını Vivado Hardware Manager üzerinden Nexys A7 kartınıza yükleyin. Kart üzerindeki DONE LED ışığının yandığını teyit edin.

2. Serial Connection / Seri Bağlantı

Open a serial terminal (e.g., Putty, RealTerm, Hercules) on your PC with a Baud Rate of 115200. Ensure data bits are set to 8, stop bits to 1, and parity to none.

    Bilgisayarınızda bir Seri Port izleme yazılımı (Putty, RealTerm vb.) aktif edin. Baud Rate değerini 115200 yapın. Veri bitlerini 8, stop bitini 1 ve parity kısmını none olarak seçip bağlantıyı açın.

3. Execution / Çalıştırma

Press BTNC (Center) to reset the SNA system, then press BTNU (Up) to initiate the scalar network analyzer sweep. The live power spectrum data will begin streaming onto your PC interface line by line.

    Kart üzerindeki BTNC (Orta Buton) ile sistemi resetleyin, ardından BTNU (Yukarı Buton) düğmesine bastığınız anda skaler tarama başlayacak ve ekranınıza RF güç spektrumu verisi satır satır akacaktır.
