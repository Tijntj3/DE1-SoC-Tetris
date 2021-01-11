library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity game_controller is
    port (
        CLK                                 : in    std_logic;
        RENDER_BUSY                         : in    std_logic;

        USR_INPUT_LR                        : in    std_logic_vector(1 downto 0);
        USR_INPUT_LR_EN                     : in    std_logic;
        USR_INPUT_DWN                       : in    std_logic;
        USR_INPUT_DWN_EN                    : in    std_logic;
        USR_INPUT_ROT                       : in    std_logic;
        USR_INPUT_ROT_EN                    : in    std_logic;

        GAME_TICK                           : in    std_logic;
        GAME_PIECE_H                        : out   std_logic_vector(4 downto 0);
        GAME_PIECE_V                        : out   std_logic_vector(4 downto 0);
        GAME_PIECE_R                        : out   std_logic_vector(1 downto 0);
        GAME_ROW_FULL                       : in    std_logic;
        GAME_OVERLAP                        : in    std_logic;
        GAME_OVER                           : in    std_logic;

        MEM_OP                              : out   std_logic_vector(1 downto 0);
        MEM_ROW                             : out   std_logic_vector(4 downto 0);

        CHECK_ADDR                          : out   std_logic_vector(8 downto 0);

        GAME_NEW_PIECE                      : out   std_logic;
        GAME_STATE                          : out   std_logic_vector(1 downto 0);
        GAME_SCORE                          : out   std_logic_vector(23 downto 0)
    );
end entity;

architecture behaviour of game_controller is
    
    signal state_s                          :       std_logic_vector(1 downto 0)    := (others => '0');
    signal state_counter                    :       unsigned(7 downto 0)            := (others => '0');

    signal render_busy_reg                  :       std_logic_vector(3 downto 0)    := (others => '0');
    signal render_busy_falling              :       std_logic                       := '0';

    signal check_en                         :       std_logic                       := '0';
    signal check_counter                    :       unsigned(8 downto 0)            := (others => '0');

    signal input_buffer                     :       std_logic_vector(2 downto 0)    := (others => '0');
    signal event_buffer                     :       std_logic_vector(1 downto 0)    := (others => '0');
    signal input_down_buffer                :       std_logic_vector(1 downto 0)    := (others => '0');
    signal full_row_buffer                  :       std_logic_vector(5 downto 0)    := (others => '0');

    signal piece_h                          :       unsigned(4 downto 0)            := (others => '0');
    signal piece_h_b                        :       unsigned(4 downto 0)            := (others => '0');
    signal piece_r                          :       unsigned(1 downto 0)            := (others => '0');
    signal piece_r_b                        :       unsigned(1 downto 0)            := (others => '0');
    signal piece_hr_reset                   :       std_logic                       := '0';

    signal piece_v                          :       unsigned(4 downto 0)            := (others => '0');
    signal piece_v_b                        :       unsigned(4 downto 0)            := (others => '0');

    signal mem_op_s                         :       std_logic_vector(1 downto 0)    := (others => '0');
    signal mem_row_s                        :       std_logic_vector(4 downto 0)    := (others => '0');
    signal mem_clear                        :       std_logic                       := '0';

    signal score                            :       unsigned(23 downto 0)           := (others => '0');
    signal score_clear                      :       std_logic                       := '0';
    signal score_inc                        :       std_logic                       := '0';

begin

    GAME_STATE <= state_s;
    GAME_PIECE_H <= std_logic_vector(piece_h);
    GAME_PIECE_V <= std_logic_vector(piece_v);
    GAME_PIECE_R <= std_logic_vector(piece_r);
    CHECK_ADDR <= std_logic_vector(check_counter);
    MEM_OP <= mem_op_s;
    MEM_ROW <= mem_row_s;
    GAME_NEW_PIECE <= piece_hr_reset;
    GAME_SCORE <= std_logic_vector(score);

    sample_render_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                render_busy_reg <= render_busy_reg(2 downto 0) & RENDER_BUSY;
            end if;
        end process;
    
    render_busy_edge_inst : process(render_busy_reg)
        begin
            render_busy_falling <= render_busy_reg(3) and not(render_busy_reg(2));
        end process;

    input_buffer_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                if render_busy_falling = '1' then
                    if event_buffer(0) /= '1' then
                        input_buffer <= (others => '0');
                    end if;
                else
                    if USR_INPUT_LR_EN = '1' then
                        input_buffer(2 downto 1) <= USR_INPUT_LR;
                    end if;
                    if USR_INPUT_ROT_EN = '1' then
                        input_buffer(0) <= USR_INPUT_ROT;
                    end if;
                end if;
            end if;
        end process;

    event_buffer_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                if render_busy_falling = '1' then
                    event_buffer <= (others => '0');
                else
                    if GAME_TICK = '1' then
                        event_buffer(0) <= '1';
                    end if;
                    if (GAME_OVER = '1') and (check_en = '1') then
                        event_buffer(1) <= '1';
                    end if;
                end if;
            end if;
        end process;

    check_enable_inst : process(check_counter(2 downto 0))
        begin
            if check_counter(2 downto 0) = "001" then
                check_en <= '1';
            else
                check_en <= '0';
            end if;
        end process;

    input_rollback_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                if piece_hr_reset = '1' then
                    piece_h <= "00100";
                    piece_h_b <= "00100";
                    piece_r <= "00";
                    piece_r_b <= "00";
                else
                    if render_busy_falling = '1' then
                        piece_h_b <= piece_h;
                        piece_r_b <= piece_r;
                        if (event_buffer(0) = '0') and (input_down_buffer(0) = '0') and (piece_v_b /= "10100") then
                            case input_buffer(2 downto 1) is
                                when "10" => 
                                    if piece_h /= "00000" then
                                        piece_h <= piece_h - 1;
                                    end if;
                                when "01" =>
                                    if piece_h /= "01001" then
                                        piece_h <= piece_h + 1;
                                    end if;
                                when others =>
                            end case;
                            if input_buffer(0) = '1' then
                                piece_r <= piece_r + 1;
                            end if;
                        end if;
                    end if;
                    if check_en = '1' then
                        if GAME_OVERLAP = '1' then
                            if piece_h /= piece_h_b then
                                piece_h <= piece_h_b;
                            end if;
                            if piece_r /= piece_r_b then
                                piece_r <= piece_r_b;
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end process;

    vertical_rollback_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                if piece_hr_reset = '1' then
                    piece_v <= "10100";
                    piece_v_b <= "10100";
                    input_down_buffer <= (others => '0');
                else
                    if render_busy_falling = '1' then
                        piece_v_b <= piece_v;
                        if (event_buffer(0) = '1') or (input_down_buffer(0) = '1') then
                            if piece_v /= "00000" then
                                piece_v <= piece_v - 1;
                            else
                                input_down_buffer(1) <= '1';
                            end if;
                        end if;
                    end if;
                    if USR_INPUT_DWN_EN = '1' then
                        input_down_buffer(0) <= USR_INPUT_DWN;
                    end if;
                    if check_en = '1' then
                        if GAME_OVERLAP = '1' then
                            if piece_v /= piece_v_b then
                                piece_v <= piece_v_b;
                                input_down_buffer(1) <= '1';
                            end if;
                        end if;
                    end if;
                end if;
            end if;
        end process;
    
    row_full_checker : process(CLK)
        begin
            if rising_edge(CLK) then
                if render_busy_falling = '1' then
                    full_row_buffer <= (others => '0');
                elsif check_counter(2 downto 0) = "001" then
                    if GAME_ROW_FULL = '1' then
                        full_row_buffer <= '1' & std_logic_vector(check_counter(7 downto 3));
                    end if;
                end if;
            end if;
        end process;

    game_control_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                if render_busy_falling = '1' then
                    case state_s is
                        when "00" =>
                            if state_counter = "11110000" then
                                state_counter <= (others => '0');
                                state_s <= "01";
                            else
                                state_counter <= state_counter + 1;
                            end if;
                        when "01" =>
                            if state_counter = "00000001" then
                                state_counter <= (others => '0');
                                state_s <= "10";
                            else
                                if input_buffer /= "000" then
                                    state_counter <= state_counter + 1;
                                end if;
                            end if;
                        when "10" =>
                            if event_buffer(1) = '1' then
                                state_s <= "01";
                            end if;
                        when others =>
                            state_s <= "01";
                    end case;
                end if;
            end if;
        end process;

    game_decoder_inst : process(state_s, check_counter, render_busy_falling, input_buffer, input_down_buffer)
        begin
            case state_s is
                when "00" =>
                    mem_clear <= '0';
                    score_clear <= '0';
                    piece_hr_reset <= '0';
                when "01" =>
                    mem_clear <= '1';
                    if render_busy_falling = '1' then
                        if input_down_buffer /= "00" then
                            score_clear <= '1';
                        else
                            score_clear <= '0';
                        end if;
                        piece_hr_reset <= '1';
                    else
                        piece_hr_reset <= '0';
                        score_clear <= '0';
                    end if;
                when "10" =>
                    mem_clear <= '0';
                    score_clear <= '0';
                    if (check_counter = "000000001") and (input_down_buffer(1) = '1') then
                        piece_hr_reset <= '1';
                    else
                        piece_hr_reset <= '0';
                    end if;
                when others =>
                    mem_clear <= '0';
                    score_clear <= '0';
                    piece_hr_reset <= '0';
            end case;
        end process;

    recheck_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                if state_s /= "00" then
                    if render_busy_falling = '1' then
                        check_counter <= (others => '1');
                    else
                        if check_counter /= "000000000" then
                            check_counter <= check_counter - 1;
                        end if;
                    end if;
                    if (check_counter = "100000000") then
                        if mem_clear = '1' then
                            mem_op_s <= "11";
                            mem_row_s <= (others => '0');
                            score_inc <= '0';
                        elsif input_down_buffer(1) = '1' then
                            mem_op_s <= "01";
                            mem_row_s <= (others => '0');
                            score_inc <= '0';
                        elsif full_row_buffer(5) = '1' then
                            mem_op_s <= "10";
                            mem_row_s <= full_row_buffer(4 downto 0);
                            score_inc <= '1';
                        else
                            mem_op_s <= "00";
                            mem_row_s <= (others => '0');
                            score_inc <= '0';
                        end if;
                    else
                        mem_op_s <= "00";
                        mem_op_s <= (others => '0');
                        score_inc <= '0';
                    end if;
                end if;
            end if;
        end process;

    score_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                if score_clear = '1' then
                    score <= (others => '0');
                elsif score_inc = '1' then
                    score <= score + 1;
                end if;
            end if;
        end process;

end architecture;