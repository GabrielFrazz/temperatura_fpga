library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity temperatura is
    generic (
        ANODO_COMUM : boolean := false
    );
    port (
        CLOCK_50  : in    std_logic;
        RESET_N   : in    std_logic;
        SENSOR_DQ : inout std_logic;

        RGB_R     : out   std_logic;
        RGB_G     : out   std_logic;
        RGB_B     : out   std_logic;

        HEX0      : out   std_logic_vector(6 downto 0);
        HEX1      : out   std_logic_vector(6 downto 0)
    );
	  attribute chip_pin : string;

    attribute chip_pin of CLOCK_50 : signal is "Y2";
    attribute chip_pin of RESET_N  : signal is "M23";

    attribute chip_pin of SENSOR_DQ : signal is "AB22";

    attribute chip_pin of RGB_R : signal is "AC15";
    attribute chip_pin of RGB_G : signal is "AB21";
    attribute chip_pin of RGB_B : signal is "Y17";

    attribute chip_pin of HEX0 : signal is
        "H22, J22, L25, L26, E17, F22, G18";

    attribute chip_pin of HEX1 : signal is
        "U24, U23, W25, W22, W21, Y22, M24";
end entity;

architecture rtl of temperatura is
    signal sincronizador_reset : std_logic_vector(1 downto 0) := "11";
    signal reset, valido, erro : std_logic;
    signal temperatura_bruta : signed(15 downto 0);

begin
    process(CLOCK_50, RESET_N)
    begin
        if RESET_N = '0' then
            sincronizador_reset <= "11";

        elsif rising_edge(CLOCK_50) then
            sincronizador_reset <= sincronizador_reset(0) & '0';
        end if;
    end process;

    reset <= sincronizador_reset(1);

    leitor : entity work.ds18b20_reader
        port map (
            clock             => CLOCK_50,
            reset             => reset,
            dq                => SENSOR_DQ,
            temperatura_bruta => temperatura_bruta,
            valido            => valido,
            erro              => erro
        );

    display : entity work.temperature_display
        port map (
            temperatura_bruta => temperatura_bruta,
            valido            => valido,
            erro              => erro,
            hex0              => HEX0,
            hex1              => HEX1
        );

    controlador_rgb : entity work.temperature_rgb
        generic map (
            ANODO_COMUM => ANODO_COMUM
        )
        port map (
            clock             => CLOCK_50,
            reset             => reset,
            temperatura_bruta => temperatura_bruta,
            valido            => valido,
            rgb_r             => RGB_R,
            rgb_g             => RGB_G,
            rgb_b             => RGB_B
        );
end architecture;