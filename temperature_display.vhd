library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity temperature_display is
    port (
        temperatura_bruta : in  signed(15 downto 0);
        valido            : in  std_logic;
        erro              : in  std_logic;
        hex0              : out std_logic_vector(6 downto 0);
        hex1              : out std_logic_vector(6 downto 0)
    );
end entity;

architecture rtl of temperature_display is

    function digito(numero : integer) return std_logic_vector is
    begin
        case numero is
            when 0 => return "1000000";
            when 1 => return "1111001";
            when 2 => return "0100100";
            when 3 => return "0110000";
            when 4 => return "0011001";
            when 5 => return "0010010";
            when 6 => return "0000010";
            when 7 => return "1111000";
            when 8 => return "0000000";
            when 9 => return "0010000";
            when others => return "1111111";
        end case;
    end function;

begin
process(temperatura_bruta, valido, erro)
    variable temperatura : integer;
begin
    temperatura := (to_integer(temperatura_bruta) + 8) / 16;

    if erro = '1' then
        hex1 <= "0000110";
        hex0 <= "0101111";

    elsif valido = '0'
        or temperatura_bruta < to_signed(0, 16)
        or temperatura > 99 then

        hex1 <= "0111111";
        hex0 <= "0111111";

    else
        hex1 <= digito(temperatura / 10);
        hex0 <= digito(temperatura mod 10);
    end if;
end process;
end architecture;