library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity board_renderer is
    port (
        PXL_CLK                             : in    std_logic;
        BOARD_ROW_INDEX                     : out   std_logic_vector(4 downto 0);
        BOARD_ROW                           : in    std_logic_vector(29 downto 0);
        BOARD_RDY                           : out   std_logic;

        RES_SEL                             : in    std_logic_vector(1 downto 0);
        H_PXL_COUNT                         : in    std_logic_vector(10 downto 0);
        V_PXL_COUNT                         : in    std_logic_vector(10 downto 0);

        GAME_STATE                          : in    std_logic_vector(1 downto 0);
        NEXT_PIECE                          : in    std_logic_vector(2 downto 0);

        VGA_R                               : out   std_logic_vector(7 downto 0);
        VGA_G                               : out   std_logic_vector(7 downto 0);
        VGA_B                               : out   std_logic_vector(7 downto 0)
    );
end entity;

architecture behavioural of board_renderer is

    type grid is array (3 downto 0, 1 downto 0) of std_logic;

    --Pixel lookup
    --VGA  res:640x480 grid:19x19 tot:190x380
    constant VGA_hgrid_start                :       std_logic_vector(10 downto 0)   := "00011100000";
    constant VGA_hgrid_end                  :       std_logic_vector(10 downto 0)   := "00110011110";
    constant VGA_vgrid_start                :       std_logic_vector(10 downto 0)   := "00000001011";
    constant VGA_vgrid_end                  :       std_logic_vector(10 downto 0)   := "00110101101";
    constant VGA_ngrid_start                :       std_logic_vector(10 downto 0)   := "00111000100";
    constant VGA_ngrid_end                  :       std_logic_vector(10 downto 0)   := "00111101010";
    constant VGA_grid_size                  :       unsigned(4 downto 0)            := "10010";

    --SVGA res:800x600 grid:24x24 tot:240x480
    constant SVGA_hgrid_start               :       std_logic_vector(10 downto 0)   := "00100010111";
    constant SVGA_hgrid_end                 :       std_logic_vector(10 downto 0)   := "01000001001";
    constant SVGA_vgrid_start               :       std_logic_vector(10 downto 0)   := "00000001011";
    constant SVGA_vgrid_end                 :       std_logic_vector(10 downto 0)   := "01000011101";
    constant SVGA_ngrid_start               :       std_logic_vector(10 downto 0)   := "01000111001";
    constant SVGA_ngrid_end                 :       std_logic_vector(10 downto 0)   := "01001101001";
    constant SVGA_grid_size                 :       unsigned(4 downto 0)            := "10111";

    --XGA res:1024x768 grid:30x30 tot:300x600
    constant XGA_hgrid_start                :       std_logic_vector(10 downto 0)   := "00101101001";
    constant XGA_hgrid_end                  :       std_logic_vector(10 downto 0)   := "01010010111";
    constant XGA_vgrid_start                :       std_logic_vector(10 downto 0)   := "00000010111";
    constant XGA_vgrid_end                  :       std_logic_vector(10 downto 0)   := "01010101101";
    constant XGA_ngrid_start                :       std_logic_vector(10 downto 0)   := "01011010011";
    constant XGA_ngrid_end                  :       std_logic_vector(10 downto 0)   := "01100001111";
    constant XGA_grid_size                  :       unsigned(4 downto 0)            := "11101";

    signal hgrid_start                      :       std_logic_vector(10 downto 0)   := (others => '0');
    signal hgrid_end                        :       std_logic_vector(10 downto 0)   := (others => '0');
    signal vgrid_start                      :       std_logic_vector(10 downto 0)   := (others => '0');
    signal vgrid_end                        :       std_logic_vector(10 downto 0)   := (others => '0');
    signal ngrid_start                      :       std_logic_vector(10 downto 0)   := (others => '0');
    signal ngrid_end                        :       std_logic_vector(10 downto 0)   := (others => '0');
    signal grid_size                        :       unsigned(4 downto 0)            := (others => '0');

    signal hgrid_en                         :       std_logic                       := '0';
    signal vgrid_en                         :       std_logic                       := '0';
    signal ngrid_en                         :       std_logic                       := '0';

    signal h_cnt                            :       unsigned(4 downto 0)            := (others => '0');
    signal v_cnt                            :       unsigned(4 downto 0)            := (others => '0');
    signal h_valid_reg                      :       std_logic                       := '0';
    signal h_falling                        :       std_logic                       := '0';
    signal n_valid_reg                      :       std_logic                       := '0';
    signal n_falling                        :       std_logic                       := '0';

    signal hgrid_cnt                        :       unsigned(4 downto 0)            := (others => '0');
    signal vgrid_cnt                        :       unsigned(4 downto 0)            := (others => '0');

    signal piece_type                       :       std_logic_vector(2 downto 0)    := (others => '0');
    signal npiece_en                        :       std_logic                       := '0';
    signal npiece_grid                      :       grid;
    signal colour                           :       std_logic_vector(23 downto 0)   := (others => '0');

    --Piece type to rgb value
    function piece_to_colour(piece          :       std_logic_vector(2 downto 0)) return std_logic_vector is
        variable tmp                        :       std_logic_vector(23 downto 0);
        begin
            case to_integer(unsigned(piece)) is
                when 1 => tmp := "000000001111111111111111"; --I
                when 2 => tmp := "111111111111111100000000"; --O
                when 3 => tmp := "100000000000000011111111"; --T
                when 4 => tmp := "000000001111111100000000"; --S
                when 5 => tmp := "111111110000000000000000"; --Z
                when 6 => tmp := "000000000000000011111111"; --J
                when 7 => tmp := "111111111000000000000000"; --L
                when others => tmp := "000111100001111000011110";
            end case;
        return tmp;
    end function;

begin

    BOARD_ROW_INDEX <= std_logic_vector(vgrid_cnt);
    BOARD_RDY <= vgrid_en;
    VGA_R <= colour(23 downto 16);
    VGA_G <= colour(15 downto 8);
    VGA_B <= colour(7 downto 0);

    npiece_en <= npiece_grid(to_integer(not(vgrid_cnt(1 downto 0))), to_integer(hgrid_cnt(0 downto 0)));

    timings_mux_inst : process(PXL_CLK)
        begin
            if rising_edge(PXL_CLK) then
                if GAME_STATE /= "10" then
                    case RES_SEL is
                        when "01" =>
                            hgrid_start <= SVGA_hgrid_start;
                            hgrid_end <= SVGA_hgrid_end;
                            vgrid_start <= SVGA_vgrid_start;
                            vgrid_end <= SVGA_vgrid_end;
                            ngrid_start <= SVGA_ngrid_start;
                            ngrid_end <= SVGA_ngrid_end;
                            grid_size <= SVGA_grid_size;
                        when "10" =>
                            hgrid_start <= XGA_hgrid_start;
                            hgrid_end <= XGA_hgrid_end;
                            vgrid_start <= XGA_vgrid_start;
                            vgrid_end <= XGA_vgrid_end;
                            ngrid_start <= XGA_ngrid_start;
                            ngrid_end <= XGA_ngrid_end;
                            grid_size <= XGA_grid_size;
                        when others =>
                            hgrid_start <= VGA_hgrid_start;
                            hgrid_end <= VGA_hgrid_end;
                            vgrid_start <= VGA_vgrid_start;
                            vgrid_end <= VGA_vgrid_end;
                            ngrid_start <= VGA_ngrid_start;
                            ngrid_end <= VGA_ngrid_end;
                            grid_size <= VGA_grid_size;
                    end case;
                end if;
            end if;
        end process;
    
    h_valid_edge_inst : process(hgrid_en, h_valid_reg)
        begin
            h_falling <= not(hgrid_en) and h_valid_reg;
        end process;

    n_valid_edge_inst : process(ngrid_en, n_valid_reg)
        begin
            n_falling <= not(ngrid_en) and n_valid_reg;
        end process;

    vgrid_enable_inst : process(PXL_CLK)
        begin
            if rising_edge(PXL_CLK) then
                if (V_PXL_COUNT > vgrid_start) and (V_PXL_COUNT < vgrid_end) then
                    vgrid_en <= '1';
                else
                    vgrid_en <= '0';
                end if;
            end if;
        end process;

    hgrid_enable_inst : process(H_PXL_COUNT, hgrid_start, hgrid_end)
        begin
            if (H_PXL_COUNT > hgrid_start) and (H_PXL_COUNT < hgrid_end) then
                hgrid_en <= '1';
            else
                hgrid_en <= '0';
            end if;
        end process;
    
    ngrid_enable_inst : process(H_PXL_COUNT, ngrid_start, ngrid_end) 
        begin
            if (H_PXL_COUNT > ngrid_start) and (H_PXL_COUNT < ngrid_end) then
                ngrid_en <= '1';
            else
                ngrid_en <= '0';
            end if;
        end process;

    grid_count_inst : process(PXL_CLK)
        begin
            if rising_edge(PXL_CLK) then
                h_valid_reg <= hgrid_en;
                n_valid_reg <= ngrid_en;
                if vgrid_en = '1' then
                    if h_falling = '1' then
                        if v_cnt = grid_size then
                            vgrid_cnt <= vgrid_cnt - 1;
                            v_cnt <= (others => '0');
                        else
                            v_cnt <= v_cnt + 1;
                        end if;
                        h_cnt <= (others => '0');
                        hgrid_cnt <= (others => '0');
                    elsif n_falling = '1' then
                        h_cnt <= (others => '0');
                        hgrid_cnt <= (others => '0');
                    elsif (hgrid_en or ngrid_en) = '1' then
                        if h_cnt = grid_size then
                            hgrid_cnt <= hgrid_cnt + 1;
                            h_cnt <= (others => '0');
                        else
                            h_cnt <= h_cnt + 1;
                        end if;
                    end if;
                else
                    v_cnt <= (others => '0');
                    h_cnt <= (others => '0');
                    vgrid_cnt <= "10101";
                    hgrid_cnt <= (others => '0');
                end if;
            end if;
        end process;
    
    row_decode_inst : process(hgrid_cnt, BOARD_ROW)
        begin
            case (to_integer(hgrid_cnt)) is
                when 0 => piece_type <= BOARD_ROW(29 downto 27); 
                when 1 => piece_type <= BOARD_ROW(26 downto 24); 
                when 2 => piece_type <= BOARD_ROW(23 downto 21); 
                when 3 => piece_type <= BOARD_ROW(20 downto 18); 
                when 4 => piece_type <= BOARD_ROW(17 downto 15); 
                when 5 => piece_type <= BOARD_ROW(14 downto 12); 
                when 6 => piece_type <= BOARD_ROW(11 downto 9); 
                when 7 => piece_type <= BOARD_ROW(8 downto 6); 
                when 8 => piece_type <= BOARD_ROW(5 downto 3); 
                when 9 => piece_type <= BOARD_ROW(2 downto 0); 
                when others => piece_type <= (others => '0');
            end case;
        end process;

    print_inst : process(PXL_CLK)
        begin
            if rising_edge(PXL_CLK) then
                if vgrid_cnt <= 19 then
                    if hgrid_en = '1' then
                        colour <= piece_to_colour(piece_type);
                    elsif ngrid_en = '1' then
                        if vgrid_cnt >= 16 then
                            if npiece_en = '1' then
                                colour <= piece_to_colour(NEXT_PIECE);
                            else
                                colour <= (others => '0');
                            end if;
                        end if;
                    else
                        colour <= (others => '0');
                    end if;
                else
                    colour <= (others => '0');
                end if;
            end if;
        end process;
    
    next_piece_decode : process(NEXT_PIECE)
        begin
            case to_integer(unsigned(NEXT_PIECE)) is
                when 1 => 
                    npiece_grid(0,0) <= '1';
                    npiece_grid(0,1) <= '0';
                    npiece_grid(1,0) <= '1';
                    npiece_grid(1,1) <= '0';
                    npiece_grid(2,0) <= '1';
                    npiece_grid(2,1) <= '0';
                    npiece_grid(3,0) <= '1';
                    npiece_grid(3,1) <= '0';
                when 2 => 
                    npiece_grid(0,0) <= '0';
                    npiece_grid(0,1) <= '0';
                    npiece_grid(1,0) <= '0';
                    npiece_grid(1,1) <= '0';
                    npiece_grid(2,0) <= '1';
                    npiece_grid(2,1) <= '1';
                    npiece_grid(3,0) <= '1';
                    npiece_grid(3,1) <= '1';
                when 3 => 
                    npiece_grid(0,0) <= '0';
                    npiece_grid(0,1) <= '0';
                    npiece_grid(1,0) <= '1';
                    npiece_grid(1,1) <= '0';
                    npiece_grid(2,0) <= '1';
                    npiece_grid(2,1) <= '1';
                    npiece_grid(3,0) <= '1';
                    npiece_grid(3,1) <= '0';
                when 4 => 
                    npiece_grid(0,0) <= '0';
                    npiece_grid(0,1) <= '0';
                    npiece_grid(1,0) <= '1';
                    npiece_grid(1,1) <= '0';
                    npiece_grid(2,0) <= '1';
                    npiece_grid(2,1) <= '1';
                    npiece_grid(3,0) <= '0';
                    npiece_grid(3,1) <= '1';
                when 5 => 
                    npiece_grid(0,0) <= '0';
                    npiece_grid(0,1) <= '0';
                    npiece_grid(1,0) <= '0';
                    npiece_grid(1,1) <= '1';
                    npiece_grid(2,0) <= '1';
                    npiece_grid(2,1) <= '1';
                    npiece_grid(3,0) <= '1';
                    npiece_grid(3,1) <= '0';
                when 6 => 
                    npiece_grid(0,0) <= '0';
                    npiece_grid(0,1) <= '0';
                    npiece_grid(1,0) <= '0';
                    npiece_grid(1,1) <= '1';
                    npiece_grid(2,0) <= '0';
                    npiece_grid(2,1) <= '1';
                    npiece_grid(3,0) <= '1';
                    npiece_grid(3,1) <= '1';
                when 7 => 
                    npiece_grid(0,0) <= '0';
                    npiece_grid(0,1) <= '0';
                    npiece_grid(1,0) <= '1';
                    npiece_grid(1,1) <= '0';
                    npiece_grid(2,0) <= '1';
                    npiece_grid(2,1) <= '0';
                    npiece_grid(3,0) <= '1';
                    npiece_grid(3,1) <= '1';
                when others => 
                    npiece_grid(0,0) <= '0';
                    npiece_grid(0,1) <= '0';
                    npiece_grid(1,0) <= '0';
                    npiece_grid(1,1) <= '0';
                    npiece_grid(2,0) <= '0';
                    npiece_grid(2,1) <= '0';
                    npiece_grid(3,0) <= '0';
                    npiece_grid(3,1) <= '0';
            end case;
        end process;

end architecture;