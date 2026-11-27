library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ds18b20_reader is
    port (
        clock             : in    std_logic;
        reset             : in    std_logic;
        dq                : inout std_logic;
        temperatura_bruta : out   signed(15 downto 0);
        valido            : out   std_logic;
        erro              : out   std_logic
    );
end entity;

architecture rtl of ds18b20_reader is

    type tipo_estado is (
        VERIFICAR_BARRAMENTO,
        RESET_BAIXO,
        PRESENCA,
        FIM_RESET,
        INICIO_ESCRITA,
        ESCRITA_BAIXO,
        FIM_ESCRITA,
        AGUARDAR_CONVERSAO,
        INICIO_LEITURA,
        LEITURA_BAIXO,
        AMOSTRAR_LEITURA,
        FIM_LEITURA,
        FALHA
    );

    signal estado : tipo_estado;

    signal divisor      : integer range 0 to 49;
    signal temporizador : integer range 0 to 799999;

    signal forcar_nivel_baixo : std_logic;
    signal dq_metaestavel     : std_logic;
    signal dq_sincronizado    : std_logic;

    signal lendo_temperatura : std_logic;

    signal comandos : std_logic_vector(15 downto 0);
    signal dados    : std_logic_vector(15 downto 0);

    signal indice_bit : integer range 0 to 15;

begin

 
    dq <= '0' when forcar_nivel_baixo = '1' else 'Z';


    comandos <= x"BECC" when lendo_temperatura = '1'
                else x"44CC";

    process(clock)
    begin
        if rising_edge(clock) then
            if reset = '1' then
                dq_metaestavel  <= '1';
                dq_sincronizado <= '1';
            else
                dq_metaestavel  <= to_x01(dq);
                dq_sincronizado <= dq_metaestavel;
            end if;
        end if;
    end process;

    process(clock)
    begin
        if rising_edge(clock) then

            if reset = '1' then

                estado <= VERIFICAR_BARRAMENTO;

                divisor      <= 0;
                temporizador <= 999;

                forcar_nivel_baixo <= '0';
                lendo_temperatura  <= '0';

                indice_bit <= 0;
                dados      <= (others => '0');

                temperatura_bruta <= (others => '0');
                valido <= '0';
                erro   <= '0';

            elsif divisor < 49 then
                divisor <= divisor + 1;

            else
                divisor <= 0;

                -- Executa um passo a cada 1 us.
                if temporizador > 0 then
                    temporizador <= temporizador - 1;

                else

                    case estado is

                        when VERIFICAR_BARRAMENTO =>
                            if dq_sincronizado = '1' then
                                forcar_nivel_baixo <= '1';
                                temporizador <= 499;
                                estado <= RESET_BAIXO;
                            else
                                estado <= FALHA;
                            end if;

                        when RESET_BAIXO =>
                            forcar_nivel_baixo <= '0';
                            temporizador <= 69;
                            estado <= PRESENCA;

                        when PRESENCA =>
                            if dq_sincronizado = '0' then
                                temporizador <= 429;
                                estado <= FIM_RESET;
                            else
                                estado <= FALHA;
                            end if;

                        when FIM_RESET =>
                            if dq_sincronizado = '1' then
                                indice_bit <= 0;
                                estado <= INICIO_ESCRITA;
                            else
                                estado <= FALHA;
                            end if;

                        when INICIO_ESCRITA =>
                            forcar_nivel_baixo <= '1';

                            if comandos(indice_bit) = '0' then
                                temporizador <= 64;
                            else
                                temporizador <= 5;
                            end if;

                            estado <= ESCRITA_BAIXO;

                        when ESCRITA_BAIXO =>
                            forcar_nivel_baixo <= '0';

                            if comandos(indice_bit) = '0' then
                                temporizador <= 4;
                            else
                                temporizador <= 63;
                            end if;

                            estado <= FIM_ESCRITA;

                        when FIM_ESCRITA =>

                            if indice_bit < 15 then
                                indice_bit <= indice_bit + 1;
                                estado <= INICIO_ESCRITA;

                            elsif lendo_temperatura = '0' then
                                -- Aguarda a conversao por 800 ms.
                                temporizador <= 799999;
                                estado <= AGUARDAR_CONVERSAO;

                            else
                                -- Inicia a leitura dos 16 bits.
                                indice_bit <= 0;
                                dados <= (others => '0');
                                estado <= INICIO_LEITURA;
                            end if;

                        when AGUARDAR_CONVERSAO =>
                            lendo_temperatura <= '1';
                            estado <= VERIFICAR_BARRAMENTO;

                        when INICIO_LEITURA =>
                            forcar_nivel_baixo <= '1';
                            temporizador <= 2;
                            estado <= LEITURA_BAIXO;

                        when LEITURA_BAIXO =>
                            forcar_nivel_baixo <= '0';
                            temporizador <= 9;
                            estado <= AMOSTRAR_LEITURA;

                        when AMOSTRAR_LEITURA =>
                            dados(indice_bit) <= dq_sincronizado;

                            temporizador <= 56;
                            estado <= FIM_LEITURA;

                        when FIM_LEITURA =>

                            if dq_sincronizado /= '1' then
                                estado <= FALHA;

                            elsif indice_bit < 15 then
                                indice_bit <= indice_bit + 1;
                                estado <= INICIO_LEITURA;

                            elsif signed(dados) >= to_signed(-880, 16)
                              and signed(dados) <= to_signed(2000, 16)
                            then

                                temperatura_bruta <= signed(dados);

                                valido <= '1';
                                erro   <= '0';

                                lendo_temperatura <= '0';

                                -- Pausa de 200 ms.
                                temporizador <= 199999;
                                estado <= VERIFICAR_BARRAMENTO;

                            else
                                estado <= FALHA;
                            end if;

                        when FALHA =>
                            forcar_nivel_baixo <= '0';

                            valido <= '0';
                            erro   <= '1';

                            lendo_temperatura <= '0';

                            temporizador <= 199999;
                            estado <= VERIFICAR_BARRAMENTO;

                    end case;
                end if;
            end if;
        end if;
    end process;

end architecture;