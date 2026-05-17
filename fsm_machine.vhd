library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main_fsm is
    port (
        clk             : in  std_logic; -- 100 MHz
        reset           : in  std_logic; -- Aktif yuksek asenkron reset
        start_sweep     : in  std_logic; -- Tarama baslatma butonu
        
        -- SPI (DAC) Kontrol
        spi_start       : out std_logic;
        dac_data        : out std_logic_vector(11 downto 0);
        spi_busy        : in  std_logic;
        
        -- XADC Kontrol
        start_adc       : out std_logic;
        data_ready      : in  std_logic;
        
        -- DBM_CALC Kontrol  
        dbm_data_i      : in  std_logic_vector(31 downto 0);
        calc_ready      : in  std_logic;
        
        -- UART Kontrol 
        uart_data_o     : out std_logic_vector(7 downto 0);
        tx_start        : out std_logic;
        tx_busy         : in  std_logic;
        
        -- Sistem Durumu
        sweep_active    : out std_logic
    );
end entity main_fsm;

architecture Behavioral of main_fsm is

    -- State tanimlarina WAIT_TX_START eklendi
    type state_type is (IDLE, SEND_SPI, WAIT_SPI, READ_XADC, WAIT_CALC, 
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
            tx_start     <= '0';
            spi_start    <= '0';
            start_adc    <= '0';
            sweep_active <= '0';
            uart_data_o  <= (others => '0');
            checksum     <= (others => '0');
            dac_cnt      <= (others => '0');
            
        elsif rising_edge(clk) then
            
            case state is
                
                when IDLE =>
                    sweep_active <= '0';
                    dac_cnt      <= (others => '0');
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
                    if data_ready = '1' then
                        start_adc <= '0';
                        state     <= WAIT_CALC;
                    end if;

                when WAIT_CALC =>
                    if calc_ready = '1' then
                        dbm_reg <= dbm_data_i;
                        state   <= SEND_HEADER;
                    end if;

                -------------------------------------------------------
                -- UART PAKETLEME DONGUSU (YONLENDIRMELER DEGIS TI)
                -------------------------------------------------------
                
                when SEND_HEADER =>
                    uart_data_o <= x"AA";
                    tx_start    <= '1';
                    next_state  <= SEND_ID;
                    state       <= WAIT_TX_START; -- Once baslamasini bekle

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

                -- YENI ARA STATE: UART'in tetiklendigini dogrular
                when WAIT_TX_START =>
                    if tx_busy = '1' then
                        tx_start <= '0';      -- UART basladi, tetiklemeyi cekebiliriz
                        state    <= WAIT_TX_DONE; -- Simdi bitmesini beklemeye gec
                    end if;

                -- UART'in isimizi tamamen bitirmesini bekleyen state
                when WAIT_TX_DONE =>
                    if tx_busy = '0' then
                        state <= next_state; -- Bir sonraki byte'a guvenle gec
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