library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity piece_generator is
    port (
        CLK                                 : in    std_logic;
        GAME_STATE                          : in    std_logic_vector(1 downto 0);
        GAME_NEW_PIECE                      : in    std_logic;

        GAME_PIECE_TYPE                     : out   std_logic_vector(2 downto 0);
        GAME_PIECE_TYPE_NEXT                : out   std_logic_vector(2 downto 0)
    );
end entity;

architecture behaviour of piece_generator is

    constant seed                           :       std_logic_vector(7 downto 0)    := "01101001";

    signal piece_type                       :       std_logic_vector(2 downto 0)    := (others => '0');
    signal piece_type_next                  :       std_logic_vector(2 downto 0)    := (others => '0');
    
    signal prng_lfsr                        :       std_logic_vector(7 downto 0)    := seed;

begin

    GAME_PIECE_TYPE <= piece_type;

    enable_next_piece : process(GAME_STATE, piece_type_next)
        begin
            if game_state = "10" then
                if piece_type_next = "000" then
                    GAME_PIECE_TYPE_NEXT <= "001";
                else
                    GAME_PIECE_TYPE_NEXT <= piece_type_next;
                end if;
            else
                GAME_PIECE_TYPE_NEXT <= "000";
            end if;
        end process;

    load_next_piece : process(CLK)
        begin
            if rising_edge(CLK) then
                if GAME_NEW_PIECE = '1' then
                    if piece_type_next = "000" then
                        piece_type <= "001";
                    else
                        piece_type <= piece_type_next;
                    end if;
                    if prng_lfsr(7 downto 5) = "000" then
                        piece_type_next <= prng_lfsr(4 downto 2);
                    else
                        piece_type_next <= prng_lfsr(7 downto 5);
                    end if;
                elsif game_state /= "10" then
                    piece_type <= (others => '0');
                    piece_type_next <= (others => '0');
                end if;
            end if;
        end process;

    calc_new_random : process(CLK)
        begin
            if rising_edge(CLK) then
                if GAME_NEW_PIECE = '1' then
                    prng_lfsr <= (prng_lfsr(4) xor prng_lfsr(3) xor prng_lfsr(2) xor prng_lfsr(0)) & prng_lfsr(7 downto 1);
                elsif game_state /= "10" then
                    prng_lfsr <= seed;
                end if;
            end if;
        end process;

end architecture;