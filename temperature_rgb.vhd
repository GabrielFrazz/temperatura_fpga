library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity temperature_rgb is
    generic (
        ANODO_COMUM : boolean := false
    );
    port (
        clock             : in  std_logic;
        reset             : in  std_logic;
        temperatura_bruta : in  signed(15 downto 0);
        valido            : in  std_logic;
        rgb_r             : out std_logic;
        rgb_g             : out std_logic;
        rgb_b             : out std_logic
    );
end entity;

architecture rtl of temperature_rgb is

    constant LIMITE_FRIO : integer := 15 * 16;
    constant LIMITE_QUENTE : integer := 35 * 16;

    signal divisor   : integer range 0 to 194;
    signal rampa_pwm : integer range 0 to 255;

    signal intensidade_vermelho : integer range 0 to 256;
    signal intensidade_azul     : integer range 0 to 256;

    signal vermelho_ativo : std_logic;
    signal azul_ativo     : std_logic;

begin

    process(temperatura_bruta)
        variable temperatura : integer range -32768 to 32767;
        variable intensidade : integer range 0 to 256;
    begin
        temperatura := to_integer(temperatura_bruta);

        if temperatura <= LIMITE_FRIO then
            intensidade := 0;

        elsif temperatura >= LIMITE_QUENTE then
            intensidade := 256;

        else
            intensidade :=
                ((temperatura - LIMITE_FRIO) * 256)
                / (LIMITE_QUENTE - LIMITE_FRIO);
        end if;

        intensidade_vermelho <= intensidade;
        intensidade_azul     <= 256 - intensidade;
    end process;

    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                divisor   <= 0;
                rampa_pwm <= 0;

            elsif divisor = 194 then
                divisor <= 0;

                if rampa_pwm = 255 then
                    rampa_pwm <= 0;
                else
                    rampa_pwm <= rampa_pwm + 1;
                end if;

            else
                divisor <= divisor + 1;
            end if;
        end if;
    end process;

    vermelho_ativo <= '1'
        when reset = '0' and valido = '1'
             and rampa_pwm < intensidade_vermelho
        else '0';

    azul_ativo <= '1'
        when reset = '0' and valido = '1'
             and rampa_pwm < intensidade_azul
        else '0';

    rgb_r <= not vermelho_ativo
        when ANODO_COMUM else vermelho_ativo;

    rgb_b <= not azul_ativo
        when ANODO_COMUM else azul_ativo;

    rgb_g <= '1' when ANODO_COMUM else '0';

end architecture;