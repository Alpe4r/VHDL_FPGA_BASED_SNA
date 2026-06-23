library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master is
    generic(
        clk_freq        : integer := 100000000; -- FPGA ana calisma frekansi (100 MHz)
        spi_freq        : integer := 10000000;  -- Hedeflenen SPI saat frekansi (10 MHz)
        data_width      : integer := 16;        -- Toplam iletilecek paket genisligi
        dac_settling_us : integer := 10         -- Mikro saniye cinsinden DAC/VCO yerlesme gecikmesi
    );
    port (
        clk         : in  std_logic; -- Sistem saat girisi
        reset       : in  std_logic; -- Eszamansiz sistem sifirlama girisi
        spi_start   : in  std_logic; -- SPI iletimini baslatan tetikleme girisi
        dac_data    : in  std_logic_vector(11 downto 0); -- DAC entegresine gonderilecek voltaj verisi
        sclk        : out std_logic; -- Harici birime giden SPI seri saat cikisi
        cs          : out std_logic; -- Harici birimi secen aktif-dusuk secme cikisi
        mosi        : out std_logic; -- Harici birime veri aktaran seri veri cikisi
        spi_busy    : out std_logic  -- SPI modulunun mesgul oldugunu bildiren durum cikisi
    );
end entity spi_master;

architecture Behavioral of spi_master is
    constant cmd_bits     : std_logic_vector(3 downto 0) := "0011"; -- DAC entegresi yazma komut bitleri
    constant sclk_limit   : integer := clk_freq / (spi_freq * 2); -- SPI saati yarim periyot sayac siniri
    
    -- Gecikme icin gerekli clock cevrimi (Orn: 50 us * 100 = 5000 clock cycle)
    constant delay_limit  : integer := (clk_freq / 1000000) * dac_settling_us;
    signal delay_counter  : integer range 0 to delay_limit := 0;

    -- Artik tum durumlar tamamen parametrik ve guvenli
    type state_type is (IDLE, LOAD, TRANSMIT, DELAY_STATE, DONE); -- Gecikme durumu eklendi
    signal state          : state_type := IDLE;
    
    signal shift_reg      : std_logic_vector(data_width-1 downto 0) := (others => '0'); -- Genislik parametreye baglandi
    signal bit_counter    : integer range 0 to data_width-1 := data_width-1;            -- Sayac parametreye baglandi
    signal sclk_counter   : integer range 0 to sclk_limit := 0; -- Frekans bolucu sayac sinyali
    signal sclk_internal  : std_logic := '0'; -- SPI saati icin dahili zamanlama sinyali
begin
    sclk <= sclk_internal; -- Dahili saati fiziksel cikis pinine yonlendirir
    
    process(clk, reset)
    begin
        if reset = '1' then
            shift_reg      <= (others => '0');
            state          <= IDLE;
            cs             <= '1';
            mosi           <= '0';
            spi_busy       <= '0';
            sclk_internal  <= '0';
            sclk_counter   <= 0;
            bit_counter    <= data_width-1;
            delay_counter  <= 0;
        elsif rising_edge(clk) then
            case state is
                when IDLE => -- Baslangic durumu, tetikleme sinyali beklenir
                    spi_busy       <= '0';
                    cs             <= '1';
                    sclk_internal  <= '0';
                    sclk_counter   <= 0;
                    mosi           <= '0';
                    delay_counter  <= 0;
                    if spi_start = '1' then
                        state    <= LOAD;
                        spi_busy <= '1';
                    end if;
                    
                when LOAD => -- Komut ve veri bitlerinin kaydirma yazmacina yuklendigi durum
                    shift_reg   <= cmd_bits & dac_data;
                    bit_counter <= data_width-1;
                    cs          <= '0'; -- Seri veri aktarimi icin harici cip aktif edilir
                    state       <= TRANSMIT;
                    
                when TRANSMIT => -- Verinin bit bit harici hatta suruldugu durum
                    mosi <= shift_reg(data_width-1); -- En yuksek bit parametrik olarak hattan surulur
                    
                    if sclk_counter < sclk_limit - 1 then
                        sclk_counter <= sclk_counter + 1;
                    else
                        sclk_counter  <= 0;
                        sclk_internal <= not sclk_internal; -- SPI saati lojik seviye degistirir
                        
                        -- SPI saatinin dusen kenarinda harici birim veri kararliligi saglanir
                        if sclk_internal = '1' then 
                            if bit_counter > 0 then
                                bit_counter <= bit_counter - 1;
                                shift_reg   <= shift_reg(data_width-2 downto 0) & '0'; -- Dinamik sola kaydirma
                            else 
                                state       <= DELAY_STATE; -- Iletim bitti, dogrudan guvenli beklemeye gecis
                            end if;
                        end if;
                    end if;

                when DELAY_STATE => -- DAC voltajinin oturmasi ve VCO kilitlenmesi icin beklenen an
                    if delay_counter < delay_limit - 1 then
                        delay_counter <= delay_counter + 1;
                    else
                        state         <= DONE; -- Donanim oturdu, simdi kapanisa gidelim
                    end if;
                    
                when DONE => -- Veri iletiminin bitti olmasi ve kapanis zamanlamasinin yapildigi durum
                    if sclk_counter < sclk_limit - 1 then
                        sclk_counter <= sclk_counter + 1;
                    else
                        cs            <= '1'; -- Harici cip secimi kapatilir
                        mosi          <= '0';
                        sclk_internal <= '0';
                        spi_busy      <= '0'; -- Master artik yeni emirlere hazir
                        state         <= IDLE;
                    end if;
                when others => state <= IDLE;
            end case;
        end if;
    end process;
end Behavioral;
