--
-- ALU 32 bits
-- Francisco Köenig Berengua
--

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_SIGNED.ALL;

-- Entidad y Puertos
entity ALU is
     port(
          a : in STD_LOGIC_VECTOR (31 downto 0);
          b : in STD_LOGIC_VECTOR (31 downto 0);
          control : in STD_LOGIC_VECTOR (2 downto 0);
          result : out STD_LOGIC_VECTOR(31 downto 0);
          zero : out STD_LOGIC
          );
end ALU;

-- Arquitectura behavioral(comportamental)
architecture Behavioral of ALU is
    signal res : STD_LOGIC_VECTOR (31 downto 0);  -- Senial interna
    
 begin
    -- Seniales sensibles del proceso
    ALU: process(a, b, control)
    begin
        case (control) is
             when "000" => -- realiza un AND
                 res <= a and b;
             when "001" => -- realiza un OR
                 res <= a or b;
             when "010" => -- realiza una SUMA
                 res <= a + b;
             when "110" => -- realiza una RESTA
                 res <= a - b;
             when "100" => -- realiza un SHIFT LEFT
                 res <= b (15 downto 0) & x"0000";   
             when "111" => -- realiza una COMPARACION POR MENOR <
                    if(a < b) then
                        res <= x"00000001";
                    else
                        res <= x"00000000";
                    end if;   
             when others => -- Para cualquier OTRO CASO
                res <= x"00000000";
         end case;              
    end process;
    
    result <= res;

    process (res)
    begin 
        if (res = x"00000000") then
            zero <= '1';
        else 
            zero <= '0';
        end if;
    end process;
        
end Behavioral;
