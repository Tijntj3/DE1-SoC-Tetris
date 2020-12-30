library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity score_to_hex is
    port (
        LINE_CLEAR_CNT                      : in    std_logic_vector(23 downto 0);

        HEX0                                : out   std_logic_vector(6 downto 0);
        HEX1                                : out   std_logic_vector(6 downto 0);
        HEX2                                : out   std_logic_vector(6 downto 0);
        HEX3                                : out   std_logic_vector(6 downto 0);
        HEX4                                : out   std_logic_vector(6 downto 0);
        HEX5                                : out   std_logic_vector(6 downto 0)
    );
end entity;

architecture behaviour of score_to_hex is
    
    --4b to hex display
    function to_hex(setting                 :       std_logic_vector(3 downto 0)) return std_logic_vector is
        variable tmp                        :       std_logic_vector(6 downto 0);
        begin
            case to_integer(unsigned(setting)) is
                when 0 => tmp := "1000000";
                when 1 => tmp := "1111001";
                when 2 => tmp := "0100100";
                when 3 => tmp := "0110000";
                when 4 => tmp := "0011001";
                when 5 => tmp := "0010010";
                when 6 => tmp := "0000010";
                when 7 => tmp := "1111000";
                when 8 => tmp := "0000000";
                when 9 => tmp := "0010000";
                when 10 => tmp := "0001000";
                when 11 => tmp := "0000011";
                when 12 => tmp := "1000110";
                when 13 => tmp := "0100001";
                when 14 => tmp := "0000110";
                when 15 => tmp := "0001110";
                when others => tmp := "1111111";
            end case;
        return tmp;
    end function;

begin

    HEX0 <= to_hex(LINE_CLEAR_CNT(3 downto 0));
    HEX1 <= to_hex(LINE_CLEAR_CNT(7 downto 4));
    HEX2 <= to_hex(LINE_CLEAR_CNT(11 downto 8));
    HEX3 <= to_hex(LINE_CLEAR_CNT(15 downto 12));
    HEX4 <= to_hex(LINE_CLEAR_CNT(19 downto 16));
    HEX5 <= to_hex(LINE_CLEAR_CNT(23 downto 20));

end architecture;