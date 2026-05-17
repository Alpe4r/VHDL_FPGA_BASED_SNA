library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity xadc_module is
    Port ( 
        clk           : in  STD_LOGIC;
        reset         : in  STD_LOGIC;
        start_adc     : in  STD_LOGIC; 
        data_ready    : out STD_LOGIC; 
        adc_data_out  : out STD_LOGIC_VECTOR(11 downto 0); 
        vauxp3        : in  STD_LOGIC; 
        vauxn3        : in  STD_LOGIC  
    );
end xadc_module;

architecture Behavioral of xadc_module is

    COMPONENT xadc_wiz
      PORT (
        di_in       : IN  STD_LOGIC_VECTOR(15 DOWNTO 0);
        daddr_in    : IN  STD_LOGIC_VECTOR(6 DOWNTO 0);
        den_in      : IN  STD_LOGIC;
        dwe_in      : IN  STD_LOGIC;
        drdy_out    : OUT STD_LOGIC;
        do_out      : OUT STD_LOGIC_VECTOR(15 DOWNTO 0);
        dclk_in     : IN  STD_LOGIC;
        reset_in    : IN  STD_LOGIC;
        vp_in       : IN  STD_LOGIC;
        vn_in       : IN  STD_LOGIC;
        vauxp3      : IN  STD_LOGIC;
        vauxn3      : IN  STD_LOGIC;
        channel_out : OUT STD_LOGIC_VECTOR(4 DOWNTO 0);
        eoc_out     : OUT STD_LOGIC;
        alarm_out   : OUT STD_LOGIC;
        eos_out     : OUT STD_LOGIC;
        busy_out    : OUT STD_LOGIC 
      );
    END COMPONENT;

    signal xadc_raw_out : std_logic_vector(15 downto 0);
    signal drdy_int     : std_logic;
    
    -- Güvenli DRP tetiklemesi için yeni sinyaller
    signal start_adc_d1 : std_logic := '0';
    signal den_pulse    : std_logic := '0';

begin

    -- DEGISIKLIK: FSM'den gelen start_adc sinyalinin sadece yükselen kenarında 1 clock'luk darbe üretir
    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                start_adc_d1 <= '0';
                den_pulse    <= '0';
            else
                start_adc_d1 <= start_adc;
                if start_adc = '1' and start_adc_d1 = '0' then
                    den_pulse <= '1'; -- Sadece 1 clock cycle '1' kalır
                else
                    den_pulse <= '0';
                end if;
            end if;
        end if;
    end process;

    XADC_CORE : xadc_wiz
      PORT MAP (
        di_in       => (others => '0'), 
        daddr_in    => "0010011",       -- 0x13 Adresi (VAUX3)
        den_in      => den_pulse,       -- GÜNCELLENDI: Artik kilitlenme yapmaz
        dwe_in      => '0',             
        drdy_out    => drdy_int,        
        do_out      => xadc_raw_out,    
        dclk_in     => clk,             
        reset_in    => reset,           
        vp_in       => '0',             
        vn_in       => '0',             
        vauxp3      => vauxp3,          
        vauxn3      => vauxn3,          
        channel_out => open,
        eoc_out     => open,
        alarm_out   => open,
        eos_out     => open,
        busy_out    => open 
      );

    process(clk)
    begin
        if rising_edge(clk) then
            if reset = '1' then
                adc_data_out <= (others => '0');
                data_ready   <= '0';
            else
                if drdy_int = '1' then
                    adc_data_out <= xadc_raw_out(15 downto 4);
                    data_ready   <= '1';
                else
                    data_ready   <= '0';
                end if;
            end if;
        end if;
    end process;

end Behavioral;