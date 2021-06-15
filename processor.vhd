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

    component Registers
    port(
        reg1_rd, reg2_rd, reg_wr : in STD_LOGIC_VECTOR(4 downto 0);
        data_wr : in STD_LOGIC_VECTOR (31 downto 0);
        clk, reset, wr : in STD_LOGIC;
        data1_rd, data2_rd : out STD_LOGIC_VECTOR (31 downto 0)
        );
    end component;
    
    --Seniales del banco de registro de ID
    signal id_breg_data_wr: std_logic_vector(31 downto 0);
    signal id_breg_data1_rd, id_breg_data2_rd: std_logic_vector(31 downto 0);
	--Fin seniales del banco de registro
	
	
    signal if_pc_out: std_logic_vector(31 downto 0);        --Salida PC
    
    signal if_pc_4: std_logic_vector(31 downto 0);          --Salida Adder
    
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
    signal AluOp: std_logic_vector(2 downto 0);
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
    signal id_ex_ctrl_AluOp: std_logic_vector(2 downto 0);
    
    signal id_ex_pc_4: std_logic_vector(31 downto 0);
    signal id_ex_regA: std_logic_vector(31 downto 0);
    signal id_ex_regB: std_logic_vector(31 downto 0);
    signal id_ex_dataInm: std_logic_vector(31 downto 0);
    signal id_ex_regD_lw: std_logic_vector(4 downto 0);
    signal id_ex_regD_tr: std_logic_vector(4 downto 0);
    --Fin Reg segmentacion
    
    --EX/MEM Reg segmentacion
    signal ex_mem_ctrl_RegWrite: std_logic;
    signal ex_mem_ctrl_MemRead: std_logic;
    signal ex_mem_ctrl_MemWrite: std_logic;
    signal ex_mem_ctrl_Branch: std_logic;   
    signal ex_mem_ctrl_Zero: std_logic;
    signal ex_mem_ctrl_MemToReg: std_logic;
    
    signal ex_mem_branch, ex_mem_alu_out, ex_mem_wr_data: std_logic_vector(31 downto 0);
    signal ex_mem_wr_reg: std_logic_vector(4 downto 0);
    --Fin Reg segmentacion
    
    
    --Seniales Tercera Etapa    
    component ALU
    port(
        a : in STD_LOGIC_VECTOR (31 downto 0);
        b : in STD_LOGIC_VECTOR (31 downto 0);
        control : in STD_LOGIC_VECTOR (2 downto 0);
        result : out STD_LOGIC_VECTOR(31 downto 0);
        zero : out STD_LOGIC
        );
    end component;
	
	--Seniales de la ALU
	signal ex_ALU_result : std_logic_vector(31 downto 0);
	signal ex_ALU_control : std_logic_vector(2 downto 0);
	signal ex_ALU_zero : std_logic;
	--Fin seniales de la ALU
    --Add branch
    signal ex_add_branch: std_Logic_vector(31 downto 0);
    signal ex_mux_reg_out: std_logic_vector(4 downto 0);
    --Fin add branch
    
    --Mux ALU
    signal ex_mux_alu_out: std_logic_vector(31 downto 0);
    --Fin Mux ALU
    
    
    --Seniales Cuarta Etapa
    
    --MEM/WB Reg Seg
    signal mem_wb_ctrl_RegWrite: std_logic;
    signal mem_wb_ctrl_MemToReg: std_logic;
    
    signal mem_wb_data_out: std_logic_vector(31 downto 0);
    signal mem_wb_alu_out: std_logic_vector(31 downto 0);
    signal mem_wb_wr_reg: std_logic_vector(4 downto 0);
    
begin
    --Instanciacion banco de registros
    banco_registros_inst : Registers
    port map(
            reg1_rd => if_id_inst_out(25 downto 21),    --Asigna direcc a leer registro 1
            reg2_rd => if_id_inst_out(20 downto 16),    --Asigna direcc a leer registro 2
            reg_wr => mem_wb_wr_reg,             
            data_wr => id_breg_data_wr,                 
            clk => Clk,
            reset => Reset,
            wr => mem_wb_ctrl_RegWrite,
            data1_rd => id_breg_data1_rd,
            data2_rd => id_breg_data2_rd
            );
     --Fin instanciacion banco registros
     
     
     --Instanciacion ALU
    ALU_inst : ALU
    port map(
            a => id_ex_regA,            --Operando A = salida reg segmentación
            b => ex_mux_alu_out,        --Operando B = salida mux alu
            control => ex_ALU_control,
            result => ex_ALU_result,
            zero => ex_ALU_zero
            );
     --Fin instanciacion ALU


	--Primera Etapa
    
    I_Addr <= if_pc_out;
    I_RdStb <= '1';
    
	
	--PC
    Reg_pc: process(Clk, Reset)
    begin
    	if (Reset = '1') then
    	   if_pc_out <= (others => '0');       --Salida del PC en 0
           --I_RdStb <= '1';
        elsif rising_edge(Clk) then
           if_pc_out <= if_mux_out;            --Salida del PC = entrada del PC
        end if;
    end process;
    
    --Adder
    if_pc_4 <= (if_pc_out + x"00000004");      --Salida Adder = PC + 4
    
    --Mux
    If_Mux: process (if_sel_mux, if_pc_4, ex_mem_branch)
    begin      
        if (if_sel_mux = '0') then
            if_mux_out <= if_pc_4;            --Salida mux = PC + 4
        elsif (if_sel_mux = '1') then
            if_mux_out <= ex_mem_branch;      --Salida mux = salto proveniente de etapa mem
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
                 AluOp <= "010";
            when "100011" => --Operacion lw
                 RegDst <= '0';
                 ALUSrc <= '1';
                 MemtoReg <= '1';
                 RegWrite <= '1';
                 MemRead <= '1';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "000";
            when "101011" => --Operacion sw
                 RegDst <= 'X';
                 ALUSrc <= '1';
                 MemtoReg <= 'X';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '1';
                 Branch <= '0';
                 AluOp <= "000";
            when "000100" => --Operacion beq
                 RegDst <= 'X';
                 ALUSrc <= '0';
                 MemtoReg <= 'X';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '1';
                 AluOp <= "001";
            when "001000" => --Operacion addi
                 RegDst <= '0';
                 ALUSrc <= '1';
                 MemtoReg <= '0';
                 RegWrite <= '1';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "011";  --Chequear desp
            when "001100" => --Operacion andi
                 RegDst <= '0';
                 ALUSrc <= '1';
                 MemtoReg <= '0';
                 RegWrite <= '1';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "100"; --Chequear desp
            when "001101" => --Operacion ori
                 RegDst <= '0';
                 ALUSrc <= '1';
                 MemtoReg <= '0';
                 RegWrite <= '1';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "101"; --Chequear desp
            when "001111" => --Operacion lui
                 RegDst <= '0';
                 ALUSrc <= '1';
                 MemtoReg <= '0';
                 RegWrite <= '1';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "110"; --Chequear desp
            when others => --Para cualquier otro caso, todo en 0
                 RegDst <= '0';
                 ALUSrc <= '0';
                 MemtoReg <= '0';
                 RegWrite <= '0';
                 MemRead <= '0';
                 MemWrite <= '0';
                 Branch <= '0';
                 AluOp <= "000";
       end case;
    end process;
    
    --Extension de Signo
    ID_sign_extended: process(if_id_inst_out)
    begin
        if (if_id_inst_out(15) = '0') then      --Si es positivo
            id_sign_ext_out <= x"0000" & if_id_inst_out(15 downto 0);   --Extiende con 0 al inicio
        elsif (if_id_inst_out(15) = '1') then   --Si es negativo
            id_sign_ext_out <= x"1111" & if_id_inst_out(15 downto 0);   --Extiende con 1 al inicio
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
            id_ex_ctrl_AluOp <= "000";
    
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
    
    
    --Fin Segunda Etapa
    
    
    --Tercera Etapa
    
    --ALU Control
    EX_Alu_ctrl: process (id_ex_ctrl_AluOp, id_ex_dataInm)
    begin
        case(id_ex_ctrl_AluOp) is
            when "010" => --Operación tipo R
            
                case(id_ex_dataInm(5 downto 0)) is
                    when "100000" => --ADD
                        ex_ALU_control <= "010";
                    when "100010" => --SUB
                        ex_ALU_control <= "110";
                    when "100100" => --AND
                        ex_ALU_control <= "000";
                    when "100101" => --OR
                        ex_ALU_control <= "001";
                    when "101010" => --SLT
                        ex_ALU_control <= "111";
                    when others =>
                    	ex_ALU_control <= "011";
                end case;
            
            when "000" => --Operación LW y SW
                ex_ALU_control <= "010";
            
            when "001" => --Operación BEQ
                ex_ALU_control <= "110";
            
            when "011" => --Operación ADDI
                ex_ALU_control <= "010";
            
            when "100" => --Operación ANDI
                ex_ALU_control <= "000";
                
            when "101" => --Operación ORI
                ex_ALU_control <= "001";
                
            when "110" => --Operación LUI
                ex_ALU_control <= "100";
            when others =>
                    	ex_ALU_control <= "011";
        end case;
    end process;
    
    --Mux ALU
    EX_Mux_alu: process (id_ex_ctrl_ALUSrc, id_ex_regB, id_ex_dataInm)
    begin
        if(id_ex_ctrl_ALUSrc = '0') then                   --Si selector = 0
            ex_mux_alu_out <= id_ex_regB;            --toma el valor de RegB de Banco de Registros
        elsif(id_ex_ctrl_ALUSrc = '1') then                --Si selector = 1
            ex_mux_alu_out <= id_ex_dataInm;         --toma el valor del inmediato
        end if;
    end process;    
    
    --Adder dirección de salto
    EX_Adder_branch: process (id_ex_pc_4, id_ex_dataInm)
    begin
        ex_add_branch <= (id_ex_dataInm(29 downto 0) & "00") + id_ex_pc_4; --Shift left y suma (PC+4)
    end process;
    
    --Mux Write Register
    EX_Mux_wr_register: process (id_ex_ctrl_RegDst, id_ex_regD_lw, id_ex_regD_tr)
    begin
        if(id_ex_ctrl_RegDst = '0') then                   --Si selector = 0
            ex_mux_reg_out <= id_ex_regD_lw;            --toma el valor de instrucc(20 to 16)
        elsif(id_ex_ctrl_RegDst = '1') then                --Si selector = 1
            ex_mux_reg_out <= id_ex_regD_tr;            --toma el valor de instrucc(15 to 11)
        end if;
    end process;
    
    --EX/MEM Registro segmentacion
    EX_MEM_Seg: process (Clk, Reset)
    begin
        if (Reset = '1') then
            ex_mem_ctrl_RegWrite <= '0';
            ex_mem_ctrl_MemRead <= '0';
            ex_mem_ctrl_MemWrite <= '0';
            ex_mem_ctrl_Branch <= '0';  
            ex_mem_ctrl_Zero <= '0';
            ex_mem_ctrl_MemToReg <= '0';
    
            ex_mem_branch <= (others => '0');
            ex_mem_alu_out <= (others => '0');
            ex_mem_wr_data <= (others => '0');
            ex_mem_wr_reg <= (others => '0');
            
        elsif rising_edge(Clk) then
            ex_mem_ctrl_RegWrite <= id_ex_ctrl_RegWrite;
            ex_mem_ctrl_MemRead <= id_ex_ctrl_MemRead;
            ex_mem_ctrl_MemWrite <= id_ex_ctrl_MemWrite;
            ex_mem_ctrl_Branch <= id_ex_ctrl_Branch;  
            ex_mem_ctrl_Zero <= ex_ALU_zero;
            ex_mem_ctrl_MemToReg <= id_ex_ctrl_MemToReg;
    
            ex_mem_branch <= ex_add_branch;
            ex_mem_alu_out <= ex_ALU_result;
            ex_mem_wr_data <= id_ex_regB;
            ex_mem_wr_reg <= ex_mux_reg_out;
        end if;
    end process;
    
    --Fin Tercera Etapa
    
    
    --Cuarta Etapa
    
    --AND para selector de Mux de 1ra Etapa
    if_sel_mux <= ex_mem_ctrl_Branch and ex_mem_ctrl_Zero;
    
    --Dirección de la mem
    D_Addr <= ex_mem_alu_out;
    
    --Senial de escritura de la mem
    D_WrStb <= ex_mem_ctrl_MemWrite;
    
    --Senial de lectura de la mem
    D_RdStb <= ex_mem_ctrl_MemRead;
    
    --WriteData de la mem
    D_DataOut <= ex_mem_wr_data;
    
    
    --MEM/WB Registro segmentacion
    MEM_WB_Seg: process (Clk, Reset)
    begin
        if (Reset = '1') then
            mem_wb_ctrl_RegWrite <= '0';
            mem_wb_ctrl_MemToReg <= '0';
    
            mem_wb_data_out <= (others => '0');
            mem_wb_alu_out <= (others => '0');
            mem_wb_wr_reg <= (others => '0');
                        
        elsif rising_edge(Clk) then
            mem_wb_ctrl_RegWrite <= ex_mem_ctrl_RegWrite;
            mem_wb_ctrl_MemToReg <= ex_mem_ctrl_MemToReg;
    
            mem_wb_data_out <= D_DataIn;
            mem_wb_alu_out <= ex_mem_alu_out;
            mem_wb_wr_reg <= ex_mem_wr_reg;
        end if;
    end process;
    
    --Fin Cuarta Etapa
    
    
    --Quinta Etapa
    
    --Mux
    WB_Mux: process (mem_wb_ctrl_MemToReg, mem_wb_alu_out, mem_wb_data_out)
    begin
        if(mem_wb_ctrl_MemToReg = '0') then               --Si selector = 0
            id_breg_data_wr <= mem_wb_alu_out;                   --toma el valor de salida de ALU
        elsif(mem_wb_ctrl_MemToReg = '1') then            --Si selector = 1
            id_breg_data_wr <= mem_wb_data_out;                  --toma el valor de memoria
        end if;
    end process;
    
    --Fin Quinta Etapa
    
end processor_arq;
