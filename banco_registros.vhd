----------------------------------------------------------------------------------
--
-- Banco de registros, 32 registros de 32 bits
-- Francisco Köenig Berengua
--
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_logic_unsigned.ALL;

-- Entidad y Puertos
entity Registers is
     port(
          reg1_rd, reg2_rd, reg_wr : in STD_LOGIC_VECTOR (4 downto 0);  -- direcc de los registros
          data_wr : in STD_LOGIC_VECTOR (31 downto 0);                  -- entrada con dato de escritura
          clk, reset, wr : in STD_LOGIC;
          data1_rd, data2_rd : out STD_LOGIC_VECTOR (31 downto 0)       -- salida de los registros de lectura
          );
end Registers;

architecture Behavioral of Registers is

    type mem is array(31 downto 0) of STD_LOGIC_VECTOR (31 downto 0);
    signal regs: mem; -- la senial regs es del tipo mem, declarado arriba

begin

    -- Proceso de escritura sensible al clk
    process (clk, reset)
    begin
        -- Si reset = 1 --> setea las salidas data en 0
        if(reset = '1') then
            data1_rd <= x"00000000";
            data2_rd <= x"00000000";
            
        -- Si reset = 0, hay flanco bajada, la senial de escritura está habilitada y le direcc. no es '0' (pq la 1ra pos siempre está a 0)
        -- se escribe el dato
        elsif(falling_edge(clk) and (wr = '1') and not (reg_wr = "00000")) then
            -- CONV_INTEGER convierte el dato a entero
            regs(CONV_INTEGER(reg_wr)) <= data_wr;
        end if;
    end process;
    
    data1_rd <= regs(CONV_INTEGER(reg1_rd));
    data2_rd <= regs(CONV_INTEGER(reg2_rd));
    
    
    -- Proceso de lectura combinacional
    process (reg1_rd, reg2_rd, regs)
    begin
        data1_rd <= regs(CONV_INTEGER(reg1_rd));
        data2_rd <= regs(CONV_INTEGER(reg2_rd));
    end process;

end Behavioral;