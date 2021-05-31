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

    component banco_registros
    port(
        reg1_rd, reg2_rd, reg_wr : STD_LOGIC_VECTOR(4 downto 0);
        data_wr : in STD_LOGIC_VECTOR (31 downto 0);
        clk, reset, wr : in STD_LOGIC;
        data1_rd, data2_rd : out STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;
    
    --Seniales del banco de registro de ID
    signal id_breg_reg1_rd, id_breg_reg2_rd, id_breg_reg_wr: std_logic_vector(4 downto 0);
    signal id_breg_data_wr: std_logic_vector(31 downto 0);
    signal id_breg_wr_enable: std_logic;
    signal id_breg_data1_rd, id_breg_data2_rd: std_logic_vector(31 downto 0);
	--Fin seniales del banco de registro
	
    signal if_pc_out: std_logic_vector(31 downto 0);        --Salida PC
    
    signal if_pc_4: std_logic_vector(31 downto 0);          --Salida Adder
    
    --Auxiliares
    signal mem_branch: std_logic_vector(31 downto 0);       --Salto proveniente de etapa mem
    signal id_wr_data: std_logic_vector(31 downto 0);
    signal id_wr_register: std_logic_vector(4 downto 0);
    
    signal if_sel_mux: std_logic;                           --Selector mux
    signal if_mux_out: std_logic_vector(31 downto 0);       --Salida mux
    
    signal if_id_pc_4_out: std_logic_vector(31 downto 0);   --Salida registro segmentacion para Adder
    signal if_id_inst_out: std_logic_vector(31 downto 0);   --Salida registro segmentacion para Instrucc mem
    
    --Seniales Unidad de Control
    signal RegDst: std_logic;
    signal ALUSrc: std_logic;
    signal MemtoReg: std_logic;
    signal RegWrite: std_logic;
    signal MemRead: std_logic;
    signal MemWrite: std_logic;
    signal Branch: std_logic;
    signal AluOp: std_logic_vector(1 downto 0);
    --Fin seniales Unidad de Control
    
    --Seniales Sign Extended
    signal id_sign_ext_out: std_logic_vector(31 downto 0);
    --Fin seniales Sign Extended
    
    --ID/EX Reg segmentacion
    signal id_ex_ctrl_RegDst: std_logic;
    signal id_ex_ctrl_ALUSrc: std_logic;
    signal id_ex_ctrl_MemtoReg: std_logic;
    signal id_ex_ctrl_RegWrite: std_logic;
    signal id_ex_ctrl_MemRead: std_logic;
    signal id_ex_ctrl_MemWrite: std_logic;
    signal id_ex_ctrl_Branch: std_logic;
    signal id_ex_ctrl_AluOp: std_logic_vector(1 downto 0);
    
    signal id_ex_pc_4: std_logic_vector(31 downto 0);
    signal id_ex_regA: std_logic_vector(31 downto 0);
    signal id_ex_regB: std_logic_vector(31 downto 0);
    signal id_ex_dataInm: std_logic_vector(31 downto 0);
    signal id_ex_regD_lw: std_logic_vector(4 downto 0);
    signal id_ex_regD_tr: std_logic_vector(4 downto 0);
    --Fin Reg segmentacion
    
begin
    --Instanciacion banco de registros
    banco_registros_inst : banco_registros
    port map(
            reg1_rd => id_breg_reg1_rd,
            reg2_rd => id_breg_reg2_rd,
            reg_wr => id_breg_reg_wr,
            data_wr => id_breg_data_wr,
            clk => Clk,
            reset => Reset,
            wr => id_breg_wr_enable,
            data1_rd => id_breg_data1_rd,
            data2_rd => id_breg_data2_rd
            );
     --Fin instanciacion banco registros

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
    IF_ID_Seg: process (Clk, Reset)
    begin
        if (Reset = '1') then
    	   if_id_pc_4_out <= (others => '0');        --Salida del seg en 0
    	   if_id_inst_out <= (others => '0');        --Salida del seg en 0
        elsif rising_edge(Clk) then
           if_id_pc_4_out <= if_pc_4;                --Salida reg seg = PC + 4
           if_id_inst_out <= I_DataIn;               --Salida reg seg = Instrucc mem
        end if;
    end process;
    
    --Fin Primera Etapa
    
    
    --Segunda Etapa
    
    --Banco Registros
    ID_banco_registros: process (if_id_inst_out, id_wr_register, id_wr_data) 
    begin
        id_breg_reg1_rd <= if_id_inst_out(25 downto 21);    --Asigna direcc a leer registro 1
        id_breg_reg2_rd <= if_id_inst_out(20 downto 16);    --Asigna direcc a leer registro 2
        id_breg_reg_wr <= id_wr_register;                   --(Aux)Asigna direcc registro escribir
        id_breg_data_wr <= id_wr_data;                      --(Aux)Asigna dato escribir
    end process;
    
    --Unidad de Control
    ID_unidad_control: process (if_id_inst_out)
    begin
        case (if_id_inst_out(31 downto 26)) is
            when "000000" => --Operacion tipo R
                 RegDst <= '1';
                 ALUSrc <= '0';
                 MemtoReg <= '0';
                 RegWrite <= '1';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "10";
            when "100011" => --Operacion lw
                 RegDst <= '0';
                 ALUSrc <= '1';
                 MemtoReg <= '1';
                 RegWrite <= '1';
                 MemRead <= '1';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "00";
            when "101011" => --Operacion sw
                 RegDst <= 'X';
                 ALUSrc <= '1';
                 MemtoReg <= 'X';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '1';
                 Branch <= '0';
                 AluOp <= "00";
            when "000100" => --Operacion beq
                 RegDst <= 'X';
                 ALUSrc <= '0';
                 MemtoReg <= 'X';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '1';
                 AluOp <= "01";
            when "001000" => --Operacion addi
                 RegDst <= '0';
                 ALUSrc <= '0';
                 MemtoReg <= '0';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "00";
            when "001100" => --Operacion andi
                 RegDst <= '0';
                 ALUSrc <= '0';
                 MemtoReg <= '0';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "00";
            when "001101" => --Operacion ori
                 RegDst <= '0';
                 ALUSrc <= '0';
                 MemtoReg <= '0';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "00";
            when "001111" => --Operacion lui
                 RegDst <= '0';
                 ALUSrc <= '0';
                 MemtoReg <= '0';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "00";
            when "000101" => --Operacion bne  CONSULTAR PORQUE EN ENUNCIADO NO FIGURA
                 RegDst <= '0';
                 ALUSrc <= '0';
                 MemtoReg <= '0';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "00";
            when others => --Para cualquier otro caso, todo en 0
                 RegDst <= '0';
                 ALUSrc <= '0';
                 MemtoReg <= '0';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "00";
       end case;
    end process;
    
    --Extension de Signo
    ID_sign_extended: process(if_id_inst_out)
    begin
        if (if_id_inst_out(15) = '0') then      --Si es positivo
            id_sign_ext_out <= x"00000000" & if_id_inst_out(15 downto 0);   --Extiende con 0 al inicio
        elsif (if_id_inst_out(15) = '1') then   --Si es negativo
            id_sign_ext_out <= x"11111111" & if_id_inst_out(15 downto 0);   --Extiende con 1 al inicio
        end if;
    end process;
    
    --ID/EX Registro segmentacion
    ID_EX_Seg: process (Clk, Reset)
    begin
        if (Reset = '1') then
            id_ex_ctrl_RegDst <= '0';
            id_ex_ctrl_ALUSrc <= '0';
            id_ex_ctrl_MemtoReg <= '0';
            id_ex_ctrl_RegWrite <= '0';
            id_ex_ctrl_MemRead <= '0';
            id_ex_ctrl_MemWrite <= '0';
            id_ex_ctrl_Branch <= '0';
            id_ex_ctrl_AluOp <= "00";
    
            id_ex_pc_4 <= (others => '0');
            id_ex_regA <= (others => '0');
            id_ex_regB <= (others => '0');
            id_ex_dataInm <= (others => '0');
            id_ex_regD_lw <= (others => '0');
            id_ex_regD_tr <= (others => '0');
            
        elsif rising_edge(Clk) then
            id_ex_ctrl_RegDst <= RegDst;
            id_ex_ctrl_ALUSrc <= ALUSrc;
            id_ex_ctrl_MemtoReg <= MemtoReg;
            id_ex_ctrl_RegWrite <= RegWrite;
            id_ex_ctrl_MemRead <= MemRead;
            id_ex_ctrl_MemWrite <= MemWrite;
            id_ex_ctrl_Branch <= Branch;
            id_ex_ctrl_AluOp <= AluOp;
    
            id_ex_pc_4 <= if_id_pc_4_out;
            id_ex_regA <= id_breg_data1_rd;
            id_ex_regB <= id_breg_data2_rd;
            id_ex_dataInm <= id_sign_ext_out;
            id_ex_regD_lw <= if_id_inst_out(20 downto 16);
            id_ex_regD_tr <= if_id_inst_out(15 downto 11);
        end if;
    end process;
 
end processor_arq;
