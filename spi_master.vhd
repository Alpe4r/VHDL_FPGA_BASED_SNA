library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;

entity spi_master is
    generic(
        clk_freq        : integer := 100000000;
        spi_freq         : integer := 10000000;
        data_width         : integer := 16
    );
    
    port (
        ------ Giris Portlari
        clk            : in std_logic; -- 100Mhz saat sinyali
        reset        : in std_logic; -- aktif reset
        spi_start    : in std_logic;    
        dac_data    : in std_logic_vector(11 downto 0);
        ------ Cikis portlari
        sclk        : out std_logic;
        cs            : out std_logic;
        mosi        : out std_logic;
        spi_busy    : out std_logic
    );
end entity;

architecture Behavioral of spi_master is
    -- sabitler
    constant cmd_bits    : std_logic_vector(3 downto 0)    := "0011";
    constant spi_conf    : integer                        := 16; 
    constant sclk_limit  : integer := clk_freq / (spi_freq * 2); 
    ---- sinyaller
    type state_type is (IDLE,LOAD,TRANSMIT,DONE);
    signal state                : state_type        := IDLE;
    signal shift_reg            : std_logic_vector(15 downto 0);
    signal bit_counter             : integer range 0 to 15 := 15; 
    signal sclk_counter         : integer range 0 to sclk_limit := 0; 
    signal sclk_internal        : std_logic := '0'; 
    
begin
    sclk <= sclk_internal;
    
    process(clk,reset)
    begin
        if reset = '1' then
            shift_reg         <= (others => '0');
            state            <= IDLE;
            cs                <= '1';
            mosi            <= '0';
            spi_busy            <= '0';
            sclk_internal    <= '0';
            sclk_counter      <= 0;
            bit_counter       <= 15;

        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    spi_busy        <= '0';
                    cs                <= '1';
                    sclk_internal    <= '0';
                    sclk_counter      <= 0;
                    mosi              <= '0';
                    if spi_start = '1' then
                        state <= LOAD;
                    end if;
                    
                when LOAD =>
                    spi_busy        <= '1';
                    shift_reg       <= cmd_bits & dac_data;
                    bit_counter     <= 15;
                    state           <= TRANSMIT;
                    
                when TRANSMIT =>
                    cs                <= '0';
                    -- En guncel biti her zaman MOSI hattina suruyoruz
                    mosi            <= shift_reg(15); 
                    
                    if sclk_counter < sclk_limit - 1 then
                        sclk_counter    <= sclk_counter + 1;
                    else
                        sclk_counter    <= 0;
                        sclk_internal     <= not sclk_internal;
                        
                       
                        if sclk_internal = '0' then
                            if bit_counter > 0 then
                                bit_counter    <= bit_counter - 1;
                                shift_reg    <= shift_reg(14 downto 0) & '0';
                            else 
                                state         <= DONE;
                            end if;
                        end if;
                    end if;
                    
                when DONE =>
                    cs        <= '1';
                    mosi      <= '0'; -- Is bittiginde hatti temizle
                    sclk_internal <= '0';
                    if sclk_counter < sclk_limit - 1 then
                        sclk_counter    <=    sclk_counter + 1;
                    else 
                        spi_busy        <='0';
                        state            <= IDLE;
                    end if;
            end case;
        end if;
    end process;
end Behavioral;
