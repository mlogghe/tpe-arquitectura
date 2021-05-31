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
    signal if_pc_out: reg;      --Salida PC
    signal if_pc_in: reg;       --Entrada PC
    
    signal DataOut: reg;        --Salida instruction memory
    signal Adress: reg;         --Entrada instruction memory (PC)
    
    signal if_sig: reg;         --Salida Add
    
    signal mem_branch: reg;     --Salto proveniente de etapa mem
    
    signal sel_mux: std_logic;  --Selector mux
    signal out_mux: reg;        --Salida mux
    
    signal if_id_pc_4_in: reg;  --Entrada registro segmentacion para Adder
    signal if_id_inst_in: reg;  --Entrada registro segmentacion para Instrucc mem
    
begin 

	--Primera Etapa
	--PC
    Reg_pc: process(Clk, Reset)
    begin
    	if (Reset = '1') then
    	   if_pc_out <= (others => '0');    --Salida del PC en 0
        elsif rising_edge(Clk) then
           if_pc_out <= if_pc_in;           --Salida del PC = entrada del PC
        end if;
    end process;
    
    --Adder
    If_Add: process(Clk)
    begin
        if rising_edge(Clk) then
            if_sig <= (if_pc_out + x"00000004");  --PREGUNTAR PORQUE ERROR
        else
            if_sig <= if_pc_out;
        end if;
    end process;
    
    --Mux
    If_Mux: process (sel_mux, if_sig, mem_branch)
    begin      
        if (sel_mux = '0') then
            out_mux <= if_sig;              --Salida mux = PC + 4
        elsif (sel_mux = '1') then
            out_mux <= mem_branch;          --Salida mux = salto proveniente de etapa mem
      end if;   
    end process;
    
    if_id_pc_4_in <= if_sig;                --Entrada reg seg Adder = salida Adder
    
    if_id_inst_in <= DataOut;               --Entrada reg seg Intrucc mem = salida Intrucc mem
   
    --Reg seg Adder
--    IF_ID_pc_4: process (Clk, Reset)
--    begin
--        if (Reset = '1') then
--    	   if <= (others => '0');    --Salida del PC en 0
--        elsif rising_edge(Clk) then
--           if_pc_out <= if_pc_in;           --Salida del PC = entrada del PC
--        end if;
--    end process;        	
        
 
end processor_arq;
