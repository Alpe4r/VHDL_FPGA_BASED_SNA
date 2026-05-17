library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top_module is
    Port (
        clk             : in  std_logic; -- FPGA üzerindeki 100 MHz saat pinine baglanacak
        reset           : in  std_logic; -- Reset butonuna baglanacak
        start_sweep_i   : in  std_logic; -- Tarama baslatma butonuna baglanacak
        
        -- SPI Portlari (DAC Baglantisi için fiziksel pinler)
        sclk            : out std_logic;
        cs              : out std_logic;
        mosi            : out std_logic;
        
        -- XADC Portlari (Analog Giris pinleri)
        vauxp3          : in  std_logic;
        vauxn3          : in  std_logic;
        
        -- UART Port (PC Baglantisi için TX pini)
        tx_pin          : out std_logic
    );
end top_module;

architecture Behavioral of top_module is

    -- 1. MODULLER ARASI BAGLANTI SINYALLERI (Kablolama)
    
    -- SPI Hatlari
    signal spi_start_s    : std_logic;
    signal spi_busy_s     : std_logic;
    signal dac_data_s     : std_logic_vector(11 downto 0);
    
    -- XADC Hatlari
    signal start_adc_s    : std_logic;
    signal data_ready_s   : std_logic;
    signal adc_raw_s      : std_logic_vector(11 downto 0);
    
    -- DBM_CALC Hatlari
    signal dbm_val_s      : std_logic_vector(31 downto 0);
    signal calc_ready_s   : std_logic;
    
    -- UART Hatlari
    signal uart_data_s    : std_logic_vector(7 downto 0);
    signal tx_start_s     : std_logic;
    signal tx_busy_s      : std_logic;

begin

    -- 2. MODULLERIN YERLESTIRILMESI (Instantiation)

    -- ANA KONTROL MERKEZI (FSM)
    -- Butun trafigi bu arkadas yonetiyor.
    i_main_fsm : entity work.main_fsm
    port map (
        clk          => clk,
        reset        => reset,
        start_sweep  => start_sweep_i,
        -- SPI (DAC) Baglantilari
        spi_start    => spi_start_s,
        dac_data     => dac_data_s,
        spi_busy     => spi_busy_s,
        -- XADC Baglantilari
        start_adc    => start_adc_s,
        data_ready   => data_ready_s,
        -- dBm_calc Baglantilari
        dbm_data_i   => dbm_val_s,
        calc_ready   => calc_ready_s,
        -- UART Baglantilari
        uart_data_o  => uart_data_s,
        tx_start     => tx_start_s,
        tx_busy      => tx_busy_s,
        sweep_active => open -- Kullanilmiyor
    );

    -- SPI MASTER (DAC Kontrol)
    i_spi_master : entity work.spi_master
    port map (
        clk      => clk,
        reset    => reset,
        spi_start=> spi_start_s,
        dac_data => dac_data_s,
        sclk     => sclk,
        cs       => cs,
        mosi     => mosi,
        spi_busy => spi_busy_s
    );

    -- XADC MODULU (Analog Okuma)
    i_xadc_module : entity work.xadc_module
    port map (
        clk          => clk,
        reset        => reset,
        start_adc    => start_adc_s,
        data_ready   => data_ready_s,
        adc_data_out => adc_raw_s,
        vauxp3       => vauxp3,
        vauxn3       => vauxn3
    );

    -- DBM_CALC (LUT tablosu ile dbm donusumu)
    i_dbm_calc : entity work.dbm_calc
    port map (
        clk          => clk,
        reset        => reset,
        xadc_data    => adc_raw_s,
        xadc_ready   => data_ready_s,
        dbm_val      => dbm_val_s,
        dbm_ready    => calc_ready_s
    );

    -- UART TX (Verileri PC'ye seri hattan gonderir)
    i_uart_tx : entity work.uart_tx
    port map (
        clk      => clk,
        reset    => reset,
        tx_start => tx_start_s,
        data_in  => uart_data_s,
        tx_pin   => tx_pin,
        tx_busy  => tx_busy_s
    );

end Behavioral;