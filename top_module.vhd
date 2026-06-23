library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity top_module is
    Port (
        clk             : in  std_logic;
        reset           : in  std_logic;
        start_sweep_i   : in  std_logic;
        
        sclk            : out std_logic;
        cs              : out std_logic;
        mosi            : out std_logic;
        
        vauxp3          : in  std_logic;
        vauxn3          : in  std_logic;
        
        tx_pin          : out std_logic
    );
end top_module;

architecture Behavioral of top_module is

    signal spi_start_s    : std_logic;
    signal spi_busy_s     : std_logic;
    signal dac_data_s     : std_logic_vector(11 downto 0);
    
    signal start_adc_s    : std_logic;
    signal data_ready_s   : std_logic;
    signal adc_raw_s      : std_logic_vector(11 downto 0);
    
    signal dbm_val_s      : std_logic_vector(31 downto 0);
    signal calc_ready_s   : std_logic;
    
    signal uart_data_s    : std_logic_vector(7 downto 0);
    signal tx_start_s     : std_logic;
    signal tx_busy_s      : std_logic;

begin

    i_main_fsm : entity work.main_fsm
    port map (
        clk          => clk,
        reset        => reset,
        start_sweep  => start_sweep_i,
        spi_start    => spi_start_s,
        dac_data     => dac_data_s,
        spi_busy     => spi_busy_s,
        start_adc    => start_adc_s,
        data_ready   => data_ready_s,
        dbm_data_i   => dbm_val_s,
        calc_ready   => calc_ready_s,
        uart_data_o  => uart_data_s,
        tx_start     => tx_start_s,
        tx_busy      => tx_busy_s,
        sweep_active => open
    );

    i_spi_master : entity work.spi_master
    port map (
        clk       => clk,
        reset     => reset,
        spi_start => spi_start_s,
        dac_data  => dac_data_s,
        sclk      => sclk,
        cs        => cs,
        mosi      => mosi,
        spi_busy  => spi_busy_s
    );

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

    i_dbm_calc : entity work.dbm_calc
    port map (
        clk        => clk,
        reset      => reset,
        xadc_data  => adc_raw_s,
        xadc_ready => data_ready_s,
        dbm_val    => dbm_val_s,
        dbm_ready  => calc_ready_s
    );

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
