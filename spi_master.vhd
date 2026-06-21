library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity spi_master is
    generic(
        clk_freq    : integer := 100000000; -- FPGA ana çalışma frekansı
        spi_freq    : integer := 10000000;  -- Hedeflenen SPI saat frekansı
        data_width  : integer := 16         -- Toplam iletilecek paket genişliği
    );
    port (
        clk         : in  std_logic; -- Sistem saat girişi
        reset       : in  std_logic; -- Eşzamansız sistem sıfırlama girişi
        spi_start   : in  std_logic; -- SPI iletimini başlatan tetikleme girişi
        dac_data    : in  std_logic_vector(11 downto 0); -- DAC entegresine gönderilecek voltaj verisi
        sclk        : out std_logic; -- Harici birime giden SPI seri saat çıkışı
        cs          : out std_logic; -- Harici birimi seçen aktif-düşük seçme çıkışı
        mosi        : out std_logic; -- Harici birime veri aktaran seri veri çıkışı
        spi_busy    : out std_logic  -- SPI modülünün meşgul olduğunu bildiren durum çıkışı
    );
end entity spi_master;

architecture Behavioral of spi_master is
    constant cmd_bits     : std_logic_vector(3 downto 0) := "0011"; -- DAC entegresi yazma komut bitleri
    constant sclk_limit   : integer := clk_freq / (spi_freq * 2); -- SPI saati yarım periyot sayaç sınırı
    
    type state_type is (IDLE, LOAD, TRANSMIT, DONE); -- SPI durum makinesi adımları
    signal state          : state_type := IDLE;
    
    signal shift_reg      : std_logic_vector(15 downto 0) := (others => '0'); -- Verinin seri kaydırıldığı yazmaç
    signal bit_counter    : integer range 0 to 15 := 15; -- Gönderilen bit adedini takip eden sayaç
    signal sclk_counter   : integer range 0 to sclk_limit := 0; -- Frekans bölücü sayaç sinyali
    signal sclk_internal  : std_logic := '0'; -- SPI saati için dahili zamanlama sinyali
begin
    sclk <= sclk_internal; --Dahili saati fiziksel çıkış pinine yönlendirir
    
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
            bit_counter    <= 15;
        elsif rising_edge(clk) then
            case state is
                when IDLE => -- Başlangıç durumu, tetikleme sinyali beklenir
                    spi_busy       <= '0';
                    cs             <= '1';
                    sclk_internal  <= '0';
                    sclk_counter   <= 0;
                    mosi           <= '0';
                    if spi_start = '1' then
                        state    <= LOAD;
                        spi_busy <= '1';
                    end if;
                    
                when LOAD => -- Komut ve veri bitlerinin kaydırma yazmacına yüklendiği durum
                    shift_reg   <= cmd_bits & dac_data;
                    bit_counter <= 15;
                    cs          <= '0'; -- Seri veri aktarımı için harici çip aktif edilir
                    state       <= TRANSMIT;
                    
                when TRANSMIT => -- Verinin bit bit harici hatta sürüldüğü durum
                    mosi <= shift_reg(15); -- Yazmacın en yüksek biti veri hattına aktarılır
                    
                    if sclk_counter < sclk_limit - 1 then
                        sclk_counter <= sclk_counter + 1;
                    else
                        sclk_counter  <= 0;
                        sclk_internal <= not sclk_internal; -- SPI saati lojik seviye değiştirir
                        
                        -- SPI saatinin düşen kenarında harici birim veri kararlılığı sağlanır
                        if sclk_internal = '1' then 
                            if bit_counter > 0 then
                                bit_counter <= bit_counter - 1;
                                shift_reg   <= shift_reg(14 downto 0) & '0'; -- Yazmaç sola kaydırılır
                            else 
                                state       <= DONE;
                            end if;
                        end if;
                    end if;
                    
                when DONE => -- Veri iletiminin bittiği ve kapanış zamanlamasının yapıldığı durum
                    if sclk_counter < sclk_limit - 1 then
                        sclk_counter <= sclk_counter + 1;
                    else
                        cs            <= '1'; -- Harici çip seçimi kapatılır
                        mosi          <= '0';
                        sclk_internal <= '0';
                        spi_busy      <= '0';
                        state         <= IDLE;
                    end if;
                when others => state <= IDLE;
            end case;
        end if;
    end process;
end Behavioral;
