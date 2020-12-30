library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity piece_overlay is
    port (
        CLK                                 : in    std_logic;
        ROW_IN                              : in    std_logic_vector(31 downto 0);
        ROW_ADDR                            : in    std_logic_vector(4 downto 0);
        ROW_OUT                             : out   std_logic_vector(29 downto 0);

        CHECK_ADDR                          : in    std_logic_vector(8 downto 0);
        CHECK_DATA                          : in    std_logic_vector(31 downto 0);
        
        GAME_STATE                          : in    std_logic_vector(1 downto 0);
        GAME_PIECE_TYPE                     : in    std_logic_vector(2 downto 0);
        GAME_PIECE_H                        : in    std_logic_vector(4 downto 0);
        GAME_PIECE_V                        : in    std_logic_vector(4 downto 0);
        GAME_PIECE_R                        : in    std_logic_vector(1 downto 0);
        GAME_ROW_FULL                       : out   std_logic;
        GAME_OVERLAP                        : out   std_logic;
        GAME_OVER                           : out   std_logic
    );
end entity;

architecture behaviour of piece_overlay is

    signal row_in_s                         :       std_logic_vector(31 downto 0)   := (others => '0');
    signal row_addr_s                       :       std_logic_vector(4 downto 0)    := (others => '0');
    signal rom_address                      :       std_logic_vector(6 downto 0)    := (others => '0');
    signal rom_data                         :       std_logic_vector(15 downto 0)   := (others => '0');

    signal insert_row                       :       signed(5 downto 0)              := (others => '0');

    signal rom_alpha                        :       std_logic_vector(3 downto 0)    := (others => '0');
    signal row_alpha                        :       std_logic_vector(10 downto 0)   := (others => '0');

    signal alpha_result                     :       std_logic_vector(10 downto 0)   := (others => '0');
    signal alpha_full                       :       std_logic                       := '0';
    signal alpha_overlap                    :       std_logic                       := '0';
    signal alpha_over                       :       std_logic                       := '0';

    signal row_out_s                        :       std_logic_vector(29 downto 0)   := (others => '0');

    component piece_rom is 
        port (
            address		                    : in    std_logic_vector (6 downto 0);
            clock		                    : in    std_logic                       := '1';
            q		                        : out   std_logic_vector (15 downto 0)
        );
    end component;
    
begin

    GAME_ROW_FULL <= alpha_full;
    GAME_OVERLAP <= alpha_overlap;
    GAME_OVER <= alpha_over;
    ROW_OUT <= row_out_s;

    piece_rom_inst : piece_rom
        port map(
            address		                    => rom_address,
            clock		                    => CLK,
            q		                        => rom_data
        );

    extract_alpha_row : process(row_in_s)
        begin
            row_alpha(0) <= '1';
            row_alpha(1) <= row_in_s(2) or row_in_s(1) or row_in_s(0);
            row_alpha(2) <= row_in_s(5) or row_in_s(4) or row_in_s(3);
            row_alpha(3) <= row_in_s(8) or row_in_s(7) or row_in_s(6);
            row_alpha(4) <= row_in_s(11) or row_in_s(10) or row_in_s(9);
            row_alpha(5) <= row_in_s(14) or row_in_s(13) or row_in_s(12);
            row_alpha(6) <= row_in_s(17) or row_in_s(16) or row_in_s(15);
            row_alpha(7) <= row_in_s(20) or row_in_s(19) or row_in_s(18);
            row_alpha(8) <= row_in_s(23) or row_in_s(22) or row_in_s(21);
            row_alpha(9) <= row_in_s(26) or row_in_s(25) or row_in_s(24);
            row_alpha(10) <= row_in_s(29) or row_in_s(28) or row_in_s(27);
        end process;

    extract_alpha_rom : process(rom_data)
        begin
            rom_alpha(3) <= rom_data(15);
            rom_alpha(2) <= rom_data(11);
            rom_alpha(1) <= rom_data(7);
            rom_alpha(0) <= rom_data(3);
        end process;

    row_in_select : process(CHECK_ADDR, CHECK_DATA, ROW_IN, ROW_ADDR)
        begin
            if (CHECK_ADDR(8 downto 0) = "000000000") then
                row_in_s <= ROW_IN;
                row_addr_s <= ROW_ADDR;
            else
                row_in_s <= CHECK_DATA;
                row_addr_s <= CHECK_ADDR(7 downto 3);
            end if;
        end process;

    calc_insert_row : process(row_addr_s, GAME_PIECE_V)
        begin
            insert_row <= signed('0' & row_addr_s) - signed ('0' & GAME_PIECE_V);
        end process;
    
    rom_address_inst : process(GAME_PIECE_TYPE, GAME_PIECE_R, insert_row)
        begin
            rom_address <= GAME_PIECE_TYPE & GAME_PIECE_R & std_logic_vector(insert_row(1 downto 0));
        end process;

    alpha_full_inst : process(CHECK_ADDR, row_alpha)
        begin
            alpha_full <= CHECK_ADDR(8) and (row_alpha(10) and row_alpha(9) and row_alpha(8) and row_alpha(7) and row_alpha(6) and row_alpha(5) and row_alpha(4) and row_alpha(3) and row_alpha(2) and row_alpha(1) and row_alpha(0));
        end process;
    
    alpha_overlap_inst : process(CHECK_ADDR, alpha_result)
        begin
            alpha_overlap <= CHECK_ADDR(8) and (alpha_result(10) or alpha_result(9) or alpha_result(8) or alpha_result(7) or alpha_result(6) or alpha_result(5) or alpha_result(4) or alpha_result(3) or alpha_result(2) or alpha_result(1) or alpha_result(0));
        end process;

    game_over_inst : process(CHECK_ADDR(7 downto 3), alpha_overlap)
        begin
            if CHECK_ADDR(7 downto 3) = "10100" then
                alpha_over <= alpha_overlap;
            else
                alpha_over <= '0';
            end if;
        end process;

    insert_piece_inst : process(GAME_STATE, CHECK_ADDR, insert_row, row_in_s, rom_data, GAME_PIECE_H, row_alpha, rom_alpha)
        begin
            if GAME_STATE = "10" then
                if CHECK_ADDR(7 downto 3) <= "10100" then
                    case to_integer(insert_row) is
                        when 0 to 3 =>
                            case to_integer(unsigned(GAME_PIECE_H)) is
                                when 0 =>
                                    row_out_s(29 downto 27) <= row_in_s(29 downto 27) or rom_data(14 downto 12);
                                    row_out_s(26 downto 24) <= row_in_s(26 downto 24) or rom_data(10 downto 8);
                                    row_out_s(23 downto 21) <= row_in_s(23 downto 21) or rom_data(6 downto 4);
                                    row_out_s(20 downto 18) <= row_in_s(20 downto 18) or rom_data(2 downto 0);
                                    row_out_s(17 downto 0) <= row_in_s(17 downto 0);
                                    alpha_result <= (row_alpha(10 downto 7) and rom_alpha) & "0000000";
                                when 1 =>
                                    row_out_s(29 downto 27) <= row_in_s(29 downto 27);
                                    row_out_s(26 downto 24) <= row_in_s(26 downto 24) or rom_data(14 downto 12);
                                    row_out_s(23 downto 21) <= row_in_s(23 downto 21) or rom_data(10 downto 8);
                                    row_out_s(20 downto 18) <= row_in_s(20 downto 18) or rom_data(6 downto 4);
                                    row_out_s(17 downto 15) <= row_in_s(17 downto 15) or rom_data(2 downto 0);
                                    row_out_s(14 downto 0) <= row_in_s(14 downto 0);
                                    alpha_result <= "0" & (row_alpha(9 downto 6) and rom_alpha) & "000000";
                                when 2 =>
                                    row_out_s(29 downto 24) <= row_in_s(29 downto 24);
                                    row_out_s(23 downto 21) <= row_in_s(23 downto 21) or rom_data(14 downto 12);
                                    row_out_s(20 downto 18) <= row_in_s(20 downto 18) or rom_data(10 downto 8);
                                    row_out_s(17 downto 15) <= row_in_s(17 downto 15) or rom_data(6 downto 4);
                                    row_out_s(14 downto 12) <= row_in_s(14 downto 12) or rom_data(2 downto 0);
                                    row_out_s(11 downto 0) <= row_in_s(11 downto 0);
                                    alpha_result <= "00" & (row_alpha(8 downto 5) and rom_alpha) & "00000";
                                when 3 =>
                                    row_out_s(29 downto 21) <= row_in_s(29 downto 21);
                                    row_out_s(20 downto 18) <= row_in_s(20 downto 18) or rom_data(14 downto 12);
                                    row_out_s(17 downto 15) <= row_in_s(17 downto 15) or rom_data(10 downto 8);
                                    row_out_s(14 downto 12) <= row_in_s(14 downto 12) or rom_data(6 downto 4);
                                    row_out_s(11 downto 9) <= row_in_s(11 downto 9) or rom_data(2 downto 0);
                                    row_out_s(8 downto 0) <= row_in_s(8 downto 0);
                                    alpha_result <= "000" & (row_alpha(7 downto 4) and rom_alpha) & "0000"; 
                                when 4 =>
                                    row_out_s(29 downto 18) <= row_in_s(29 downto 18);
                                    row_out_s(17 downto 15) <= row_in_s(17 downto 15) or rom_data(14 downto 12);
                                    row_out_s(14 downto 12) <= row_in_s(14 downto 12) or rom_data(10 downto 8);
                                    row_out_s(11 downto 9) <= row_in_s(11 downto 9) or rom_data(6 downto 4);
                                    row_out_s(8 downto 6) <= row_in_s(8 downto 6) or rom_data(2 downto 0);
                                    row_out_s(5 downto 0) <= row_in_s(5 downto 0);
                                    alpha_result <= "0000" & (row_alpha(6 downto 3) and rom_alpha) & "000";
                                when 5 =>
                                    row_out_s(29 downto 15) <= row_in_s(29 downto 15);
                                    row_out_s(14 downto 12) <= row_in_s(14 downto 12) or rom_data(14 downto 12);
                                    row_out_s(11 downto 9) <= row_in_s(11 downto 9) or rom_data(10 downto 8);
                                    row_out_s(8 downto 6) <= row_in_s(8 downto 6) or rom_data(6 downto 4);
                                    row_out_s(5 downto 3) <= row_in_s(5 downto 3) or rom_data(2 downto 0);
                                    row_out_s(2 downto 0) <= row_in_s(2 downto 0);
                                    alpha_result <= "00000" & (row_alpha(5 downto 2) and rom_alpha) & "00";
                                when 6 =>
                                    row_out_s(29 downto 12) <= row_in_s(29 downto 12);
                                    row_out_s(11 downto 9) <= row_in_s(11 downto 9) or rom_data(14 downto 12);
                                    row_out_s(8 downto 6) <= row_in_s(8 downto 6) or rom_data(10 downto 8);
                                    row_out_s(5 downto 3) <= row_in_s(5 downto 3) or rom_data(6 downto 4);
                                    row_out_s(2 downto 0) <= row_in_s(2 downto 0) or rom_data(2 downto 0);
                                    alpha_result <= "000000" & (row_alpha(4 downto 1) and rom_alpha) & "0";
                                when 7 =>
                                    row_out_s(29 downto 9) <= row_in_s(29 downto 9);
                                    row_out_s(8 downto 6) <= row_in_s(8 downto 6) or rom_data(14 downto 12);
                                    row_out_s(5 downto 3) <= row_in_s(5 downto 3) or rom_data(10 downto 8);
                                    row_out_s(2 downto 0) <= row_in_s(2 downto 0) or rom_data(6 downto 4);
                                    alpha_result <= "0000000" & (row_alpha(3 downto 0) and rom_alpha);
                                when 8 =>
                                    row_out_s(29 downto 6) <= row_in_s(29 downto 6);
                                    row_out_s(5 downto 3) <= row_in_s(5 downto 3) or rom_data(14 downto 12);
                                    row_out_s(2 downto 0) <= row_in_s(2 downto 0) or rom_data(10 downto 8);
                                    alpha_result <= "00000000" & (row_alpha(2 downto 0) and rom_alpha(3 downto 1));
                                when 9 =>
                                    row_out_s(29 downto 3) <= row_in_s(29 downto 3);
                                    row_out_s(2 downto 0) <= row_in_s(2 downto 0) or rom_data(14 downto 12);
                                    alpha_result <= "000000000" & (row_alpha(1 downto 0) and rom_alpha(3 downto 2));
                                when others =>
                                    row_out_s <= row_in_s(29 downto 0);
                                    alpha_result <= (others => '0');
                            end case;
                        when others =>
                            row_out_s <= row_in_s(29 downto 0);
                            alpha_result <= (others => '0');
                    end case;
                else
                    row_out_s <= row_in_s(29 downto 0);
                    alpha_result <= (others => '0');
                end if;
            else 
                row_out_s <= row_in_s(29 downto 0);
                alpha_result <= (others => '0');
            end if;
        end process;

end architecture;