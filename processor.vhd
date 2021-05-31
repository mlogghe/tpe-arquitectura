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
	
    signal if_pc_out: std_logic_vector(31 downto 0);        --Salida PC
    
    signal if_pc_4: std_logic_vector(31 downto 0);          --Salida Adder
    
    signal mem_branch: std_logic_vector(31 downto 0);       --Salto proveniente de etapa mem
    
    signal if_sel_mux: std_logic;                           --Selector mux
    signal if_mux_out: std_logic_vector(31 downto 0);       --Salida mux
    
    signal if_id_pc_4_out: std_logic_vector(31 downto 0);   --Salida registro segmentacion para Adder
    signal if_id_inst_out: std_logic_vector(31 downto 0);   --Salida registro segmentacion para Instrucc mem
    
begin 

	--Primera Etapa
	
	--PC
    Reg_pc: process(Clk, Reset)
    begin
    	if (Reset = '1') then
    	   if_pc_out <= (others => '0');       --Salida del PC en 0
        elsif rising_edge(Clk) then
           if_pc_out <= if_mux_out;            --Salida del PC = entrada del PC
        end if;
    end process;
    
    --Adder
    if_pc_4 <= (if_pc_out + x"00000004");      --Salida Adder = PC + 4
    
    --Mux
    If_Mux: process (if_sel_mux, if_pc_4, mem_branch)
    begin      
        if (if_sel_mux = '0') then
            if_mux_out <= if_pc_4;            --Salida mux = PC + 4
        elsif (if_sel_mux = '1') then
            if_mux_out <= mem_branch;         --Salida mux = salto proveniente de etapa mem
      end if;   
    end process;
   
    --Reg seg IF/ID
    Seg_IF_ID: process (Clk, Reset)
    begin
        if (Reset = '1') then
    	   if_id_pc_4_out <= (others => '0');        --Salida del seg en 0
    	   if_id_inst_out <= (others => '0');        --Salida del seg en 0
        elsif rising_edge(Clk) then
           if_id_pc_4_out <= if_pc_4;                --Salida reg seg = PC + 4
           if_id_inst_out <= I_DataIn;               --Salida reg seg = Instrucc mem
        end if;
    end process;        	
        
 
end processor_arq;
