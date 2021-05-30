library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.STD_LOGIC_UNSIGNED.all;

entity processor is
port(
	Clk         : in  std_logic;
	Reset       : in  std_logic;
	-- Instruction memory
	I_Addr      : out std_logic_vector(31 downto 0);
	I_RdStb     : out std_logic;
	I_WrStb     : out std_logic;
	I_DataOut   : out std_logic_vector(31 downto 0);
	I_DataIn    : in  std_logic_vector(31 downto 0);
	-- Data memory
	D_Addr      : out std_logic_vector(31 downto 0);
	D_RdStb     : out std_logic;
	D_WrStb     : out std_logic;
	D_DataOut   : out std_logic_vector(31 downto 0);
	D_DataIn    : in  std_logic_vector(31 downto 0)
);
end processor;

architecture processor_arq of processor is 
	
    type reg is array(31 downto 0) of STD_LOGIC;
    signal reg_pc: reg;
    signal if_id_pc_4: reg;
    signal if_id_inst: reg;
  
begin 

	--Primera Etapa
    seg_if_id: process(clk)
    begin
    	if rising_edge(clk) then
        	--pasa a la siguiente etapa
        else
        	--se escribe en el registro
        end if;
    end process;
    
    pc: process(clk)
    begin
    	if rising_edge(clk) then
        	if sel_mux = '1' then
        		--la señal que viene de mem se escribe en el reg_pc
            else
            	--escribo el pc + 4
        	end if;
        end if;
    end process;
        	
        
 
end processor_arq;
