library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main_fsm is
    port (
        clk             : in  std_logic; -- Sistem saat girişi (100Mhz)
        reset           : in  std_logic; -- Sistem sıfırlama girişi
        start_sweep     : in  std_logic; -- Frekans taramasını başlatan buton girişi
        spi_start       : out std_logic; -- SPI modülünü başlatan tetikleme çıkışı
        dac_data        : out std_logic_vector(11 downto 0); -- DAC modülüne iletilen voltaj verisi
        spi_busy        : in  std_logic; -- SPI modülünün çalışma durum bilgisi
        start_adc       : out std_logic; -- XADC modülünü başlatan tetikleme çıkışı
        data_ready      : in  std_logic; -- XADC modülünden gelen veri hazır bilgisi
        dbm_data_i      : in  std_logic_vector(31 downto 0); -- Hesaplanan dBm verisi giriş hattı
        calc_ready      : in  std_logic; -- dBm hesaplamasının bittiğini bildiren giriş hattı
        uart_data_o     : out std_logic_vector(7 downto 0); -- UART birimine iletilen byte verisi
        tx_start        : out std_logic; -- UART iletimini başlatan tetikleme çıkışı
        tx_busy         : in  std_logic; -- UART modülünün meşguliyet durum bilgisi
        sweep_active    : out std_logic  -- Sistemde taramanın sürdüğünü bildiren çıkış
    );
end entity main_fsm;

architecture Behavioral of main_fsm is
    type state_type is (IDLE, SEND_SPI, WAIT_SPI, READ_XADC, WAIT_XADC, WAIT_CALC, 
                        SEND_HEADER, SEND_ID, SEND_D3, SEND_D2, SEND_D1, SEND_D0, 
                        SEND_CSUM, SEND_FOOTER, WAIT_TX_START, WAIT_TX_DONE, NEXT_STEP);
    signal state      : state_type := IDLE;
    signal next_state : state_type := IDLE; 
    signal dbm_reg      : std_logic_vector(31 downto 0); 
    signal checksum     : unsigned(7 downto 0); 
    signal dac_cnt      : unsigned(11 downto 0) := (others => '0'); 
    constant ID_DBM     : std_logic_vector(7 downto 0) := x"02"; 
begin
    dac_data <= std_logic_vector(dac_cnt); 

    process(clk, reset)
    begin
        if reset = '1' then
            state        <= IDLE;
            next_state   <= IDLE;
            tx_start     <= '0';
            spi_start    <= '0';
            start_adc    <= '0';
            sweep_active <= '0';
            uart_data_o  <= (others => '0');
            checksum     <= (others => '0');
            dac_cnt      <= (others => '0');
            dbm_reg      <= (others => '0');
        elsif rising_edge(clk) then
            case state is
                when IDLE => 
                    sweep_active <= '0';
                    dac_cnt      <= (others => '0');
                    tx_start     <= '0';
                    spi_start    <= '0';
                    start_adc    <= '0';
                    if start_sweep = '1' then
                        state <= SEND_SPI;
                    end if;

                when SEND_SPI => 
                    sweep_active <= '1';
                    spi_start    <= '1';
                    state        <= WAIT_SPI;

                when WAIT_SPI => 
                    spi_start <= '0';
                    if spi_busy = '0' then
                        state <= READ_XADC;
                    end if;

                when READ_XADC => 
                    start_adc <= '1'; 
                    state     <= WAIT_XADC;

                when WAIT_XADC => 
                    start_adc <= '0'; 
                    if data_ready = '1' then
                        state <= WAIT_CALC;
                    end if;

                when WAIT_CALC => 
                    if calc_ready = '1' then
                        dbm_reg <= dbm_data_i;
                        state   <= SEND_HEADER;
                    end if;

                when SEND_HEADER => 
                    uart_data_o <= x"AA";
                    tx_start    <= '1';
                    next_state  <= SEND_ID;
                    state       <= WAIT_TX_START;

                when SEND_ID => 
                    uart_data_o <= ID_DBM;
                    checksum    <= unsigned(ID_DBM);
                    tx_start    <= '1';
                    next_state  <= SEND_D3;
                    state       <= WAIT_TX_START;

                when SEND_D3 => 
                    uart_data_o <= dbm_reg(31 downto 24);
                    checksum    <= checksum + unsigned(dbm_reg(31 downto 24));
                    tx_start    <= '1';
                    next_state  <= SEND_D2;
                    state       <= WAIT_TX_START;

                when SEND_D2 => 
                    uart_data_o <= dbm_reg(23 downto 16);
                    checksum    <= checksum + unsigned(dbm_reg(23 downto 16));
                    tx_start    <= '1';
                    next_state  <= SEND_D1;
                    state       <= WAIT_TX_START;

                when SEND_D1 => 
                    uart_data_o <= dbm_reg(15 downto 8);
                    checksum    <= checksum + unsigned(dbm_reg(15 downto 8));
                    tx_start    <= '1';
                    next_state  <= SEND_D0;
                    state       <= WAIT_TX_START;

                when SEND_D0 => 
                    uart_data_o <= dbm_reg(7 downto 0);
                    checksum    <= checksum + unsigned(dbm_reg(7 downto 0));
                    tx_start    <= '1';
                    next_state  <= SEND_CSUM;
                    state       <= WAIT_TX_START;

                when SEND_CSUM => 
                    uart_data_o <= std_logic_vector(checksum);
                    tx_start    <= '1';
                    next_state  <= SEND_FOOTER;
                    state       <= WAIT_TX_START;

                when SEND_FOOTER => 
                    uart_data_o <= x"55";
                    tx_start    <= '1';
                    next_state  <= NEXT_STEP;
                    state       <= WAIT_TX_START;

                when WAIT_TX_START => 
                    -- UART modülü emri alıp tx_busy='1' yapana kadar tetiği çekili tutar
                    if tx_busy = '1' then
                        tx_start <= '0'; 
                        state    <= WAIT_TX_DONE;
                    end if;

                when WAIT_TX_DONE => 
                    tx_start <= '0'; 
                    -- UART modülü byte'ı hattan tamamen bitirip tx_busy='0' yapınca yeni adıma geçer
                    if tx_busy = '0' then
                        state <= next_state;
                    end if;

                when NEXT_STEP => 
                    if dac_cnt < 4095 then
                        dac_cnt <= dac_cnt + 1;
                        state   <= SEND_SPI;
                    else
                        state   <= IDLE;
                    end if;
                when others => state <= IDLE;
            end case;
        end if;
    end process;
end Behavioral;
