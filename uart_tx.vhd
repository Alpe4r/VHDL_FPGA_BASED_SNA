library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;


entity uart_tx is

	generic (
		baud_limit	: integer := 868; --100Mhz / 115200 baud = 868 
		bit_width	: integer := 8
	);
	
	port (
		------ Giriş Portları
		clk			: in std_logic; -- 100Mhz saat sinyali
		reset		: in std_logic; -- aktif reset
		tx_start	: in std_logic;	-- dBm'den Uarta gelecek sinyal
		data_in		: in std_logic_vector(7 downto 0); -- dBm hesaplayan modülden gelecek data sinyali
		------- Output Portları
		tx_pin		: out std_logic; -- FPGA'den PC'ye iletilecek datayi tutan sinyal
		tx_busy		: out std_logic
	);

end entity uart_tx;

architecture Behavioral of uart_tx is

	type state_type is (IDLE,START_BIT,DATA_BITS,STOP_BIT,CLEAN);
	signal current_state		: state_type := IDLE;	
	signal baud_counter			: integer range 0 to baud_limit;
	signal bit_counter			: integer;
	signal data_latch			: std_logic_vector(7 downto 0);
	signal tx_start_d1			: std_logic;
	
begin
	
	process (reset,clk)
	begin
	
	if reset = '1' then
	
		tx_pin				<= '1';
		tx_busy				<= '0';
		baud_counter		<= 0;
		bit_counter			<= 0;
		data_latch			<= (others => '0');
		tx_start_d1			<= '0';
		current_state		<= IDLE;
	
	elsif rising_edge(clk) then
		
		tx_start_d1			<= tx_start;
		case current_state is
			
			when IDLE =>
			
				tx_pin				<= '1';
				tx_busy				<= '0';
				baud_counter		<= 0;
				bit_counter			<= 0;
				data_latch			<= (others => '0');
				
				if tx_start = '1' and tx_start_d1 = '0' then
					current_state	<= START_BIT;
					data_latch		<= data_in;
					tx_busy			<= '1';
				end if;
					
			when START_BIT =>
				tx_pin					<= '0';
				if baud_counter < baud_limit - 1 then
					baud_counter		<= baud_counter + 1;
				elsif baud_counter = baud_limit -1 then
					baud_counter		<= 0;
					current_state		<= DATA_BITS;
				end if;
			
			when DATA_BITS =>
				tx_pin					<= data_latch(bit_counter);
				if bit_counter < bit_width - 1 then
					if baud_counter < baud_limit - 1 then
						baud_counter	<= baud_counter + 1;
					elsif baud_counter	= baud_limit - 1 then
						baud_counter	<= 0;
						bit_counter		<= bit_counter + 1;
					end if;
				elsif bit_counter = bit_width - 1  then	
					if baud_counter < baud_limit - 1 then
						baud_counter	<= baud_counter + 1;
					elsif baud_counter =  baud_limit - 1 then
						current_state	<= STOP_BIT;
						baud_counter		<= 0;
						bit_counter			<= 0;
					end if;	
				end if;
			
			when STOP_BIT =>
				tx_pin					<= '1';
				if baud_counter < baud_limit - 1 then
						baud_counter	<= baud_counter + 1;
				elsif baud_counter	= baud_limit - 1 then
					current_state		<= CLEAN;
					baud_counter		<= 0;
				end if;
			
			when CLEAN =>
				tx_busy 			<= '0';
				baud_counter		<= 0;
				bit_counter			<= 0;				
				data_latch			<= (others => '0');
				current_state <= IDLE;
			end case;
		end if;
	end process;
end Behavioral;