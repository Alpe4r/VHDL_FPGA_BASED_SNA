library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity main_fsm is
    port (
        clk             : in  std_logic; -- Sistem saat girişi
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
    -- Ana kontrol ünitesinin tüm çalışma adımları
    type state_type is (IDLE, SEND_SPI, WAIT_SPI, READ_XADC, WAIT_XADC, WAIT_CALC, 
                        SEND_HEADER, SEND_ID, SEND_D3, SEND_D2, SEND_D1, SEND_D0, 
                        SEND_CSUM, SEND_FOOTER, WAIT_TX_DONE, NEXT_STEP);
    signal state      : state_type := IDLE;
    signal next_state : state_type := IDLE; -- UART durumunun döneceği hedef adımı tutan sinyal
    signal dbm_reg      : std_logic_vector(31 downto 0); -- Saklanan güç verisi yazmacı
    signal checksum     : unsigned(7 downto 0); -- UART paket doğrulama toplamı sinyali
    signal dac_cnt      : unsigned(11 downto 0) := (others => '0'); -- Ramp voltajı üreten sayaç sinyali
    constant ID_DBM     : std_logic_vector(7 downto 0) := x"02"; -- Paket veri tipi tanımlama kimliği
begin
    dac_data <= std_logic_vector(dac_cnt); -- Sayaç değerini çıkış portuna bağlar

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
                when IDLE => -- Sistem bekleme durumu, tarama komutu gözlenir
                    sweep_active <= '0';
                    dac_cnt      <= (others => '0');
                    tx_start     <= '0';
                    spi_start    <= '0';
                    start_adc    <= '0';
                    if start_sweep = '1' then
                        state <= SEND_SPI;
                    end if;

                when SEND_SPI => -- Voltaj verisinin DAC birimine gönderim aşaması
                    sweep_active <= '1';
                    spi_start    <= '1';
                    state        <= WAIT_SPI;

                when WAIT_SPI => -- DAC modülünün veri aktarımını bitirmesini bekleme durumu
                    spi_start <= '0';
                    if spi_busy = '0' then
                        state <= READ_XADC;
                    end if;

                when READ_XADC => -- XADC dönüşüm sürecini başlatan tek çevrimlik tetikleme durumu
                    start_adc <= '1'; 
                    state     <= WAIT_XADC;

                when WAIT_XADC => -- XADC biriminin analog örneklemeyi tamamlamasını bekleme durumu
                    start_adc <= '0'; 
                    if data_ready = '1' then
                        state <= WAIT_CALC;
                    end if;

                when WAIT_CALC => -- Çevrilen analog verinin matematiksel hesaplama bitişini bekleme durumu
                    if calc_ready = '1' then
                        dbm_reg <= dbm_data_i;
                        state   <= SEND_HEADER;
                    end if;

                -- UART veri paketinin ardışık olarak bilgisayara iletildiği durumlar
                when SEND_HEADER => -- Paket başlangıç byte verisinin yüklendiği durum
                    uart_data_o <= x"AA";
                    tx_start    <= '1';
                    next_state  <= SEND_ID;
                    state       <= WAIT_TX_DONE;

                when SEND_ID => -- Paket kimlik veri byte içeriğinin yüklendiği durum
                    uart_data_o <= ID_DBM;
                    checksum    <= unsigned(ID_DBM);
                    tx_start    <= '1';
                    next_state  <= SEND_D3;
                    state       <= WAIT_TX_DONE;

                when SEND_D3 => -- 32-bitlik güç verisinin en yüksek anlamlı veri byte aşaması
                    uart_data_o <= dbm_reg(31 downto 24);
                    checksum    <= checksum + unsigned(dbm_reg(31 downto 24));
                    tx_start    <= '1';
                    next_state  <= SEND_D2;
                    state       <= WAIT_TX_DONE;

                when SEND_D2 => -- 32-bitlik güç verisinin üçüncü veri byte aşaması
                    uart_data_o <= dbm_reg(23 downto 16);
                    checksum    <= checksum + unsigned(dbm_reg(23 downto 16));
                    tx_start    <= '1';
                    next_state  <= SEND_D1;
                    state       <= WAIT_TX_DONE;

                when SEND_D1 => -- 32-bitlik güç verisinin ikinci veri byte aşaması
                    uart_data_o <= dbm_reg(15 downto 8);
                    checksum    <= checksum + unsigned(dbm_reg(15 downto 8));
                    tx_start    <= '1';
                    next_state  <= SEND_D0;
                    state       <= WAIT_TX_DONE;

                when SEND_D0 => -- 32-bitlik güç verisinin en düşük anlamlı veri byte aşaması
                    uart_data_o <= dbm_reg(7 downto 0);
                    checksum    <= checksum + unsigned(dbm_reg(7 downto 0));
                    tx_start    <= '1';
                    next_state  <= SEND_CSUM;
                    state       <= WAIT_TX_DONE;

                when SEND_CSUM => -- Hesaplanan hata kontrol byte verisinin yüklendiği durum
                    uart_data_o <= std_logic_vector(checksum);
                    tx_start    <= '1';
                    next_state  <= SEND_FOOTER;
                    state       <= WAIT_TX_DONE;

                when SEND_FOOTER => -- Paket bitiş byte verisinin yüklendiği durum
                    uart_data_o <= x"55";
                    tx_start    <= '1';
                    next_state  <= NEXT_STEP;
                    state       <= WAIT_TX_DONE;

                when WAIT_TX_DONE => -- Aktarılan byte verisinin fiziksel iletim bitişini bekleme durumu
                    tx_start <= '0'; 
                    if tx_busy = '0' then
                        state <= next_state;
                    end if;

                when NEXT_STEP => -- Tarama döngüsünün kontrol edildiği ve voltaj sayaç adımının güncellendiği durum
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
