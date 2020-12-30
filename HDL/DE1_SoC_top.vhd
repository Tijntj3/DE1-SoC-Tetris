library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity DE1_SoC_top is
    generic (
        DEBUG                               :       boolean                         := FALSE
    );
    port (
        --Clocks
        CLOCK_50                            : in    std_logic;
        CLOCK2_50                           : in    std_logic;
        CLOCK3_50                           : in    std_logic;
        CLOCK4_50                           : in    std_logic;

        --Push buttons
        KEY                                 : in    std_logic_vector(3 downto 0);

        --Slide switches
        SW                                  : in    std_logic_vector(9 downto 0);

        --Seven segment displays
        HEX0                                : out   std_logic_vector(6 downto 0);
        HEX1                                : out   std_logic_vector(6 downto 0);
        HEX2                                : out   std_logic_vector(6 downto 0);
        HEX3                                : out   std_logic_vector(6 downto 0);
        HEX4                                : out   std_logic_vector(6 downto 0);
        HEX5                                : out   std_logic_vector(6 downto 0);

        --Audio CODEC
        AUD_ADCLRCK                         : inout std_logic;
        AUD_ADCDAT                          : in    std_logic;
        AUD_DACLRCK                         : inout std_logic;
        AUD_DACDAT                          : out   std_logic;
        AUD_XCK                             : out   std_logic;
        AUD_BCLK                            : inout std_logic;

        --I2C Multiplexer
        FPGA_I2C_SCLK                       : inout std_logic;
        FPGA_I2C_SDAT                       : inout std_logic;

        --VGA
        VGA_R                               : out   std_logic_vector(7 downto 0);
        VGA_G                               : out   std_logic_vector(7 downto 0);
        VGA_B                               : out   std_logic_vector(7 downto 0);
        VGA_CLK                             : out   std_logic;
        VGA_BLANK_N                         : out   std_logic;
        VGA_HS                              : out   std_logic;
        VGA_VS                              : out   std_logic;
        VGA_SYNC_N                          : out   std_logic
    );
end entity;

architecture behavioural of DE1_SoC_top is

    constant const_50M                      :       std_logic_vector(25 downto 0)   := "10111110101111000001111111";

    --Clocking
    signal pll_reset                    :       std_logic                       := '0';
    signal pixel_clk                    :       std_logic                       := '0';
    signal vga_pixel_clk                :       std_logic                       := '0';
    signal svga_pixel_clk               :       std_logic                       := '0';
    signal xga_pixel_clk                :       std_logic                       := '0';
    signal clk_50_counter               :       unsigned(25 downto 0)           := (others => '0');

    --Rendering
    signal h_pxl_count                  :       std_logic_vector(10 downto 0)   := (others => '0');
    signal v_pxl_count                  :       std_logic_vector(10 downto 0)   := (others => '0');
    signal v_pxl_valid                  :       std_logic                       := '0';

    signal res_sel                      :       std_logic_vector(1 downto 0)    := (others => '0');
    signal render_addr                  :       std_logic_vector(4 downto 0)    := (others => '0');
    signal check_addr                   :       std_logic_vector(8 downto 0)    := (others => '0');
    signal board_addr                   :       std_logic_vector(5 downto 0)    := (others => '0');
    signal overlay_data                 :       std_logic_vector(31 downto 0)   := (others => '0');
    signal render_data_out              :       std_logic_vector(29 downto 0)   := (others => '0');

    --Storing
    signal mem_op                       :       std_logic_vector(1 downto 0)    := (others => '0');
    signal mem_row                      :       std_logic_vector(4 downto 0)    := (others => '0');

    signal logic_addr                   :       std_logic_vector(5 downto 0)    := (others => '0');
    signal logic_data_in                :       std_logic_vector(31 downto 0)   := (others => '0');
    signal logic_data_out               :       std_logic_vector(31 downto 0)   := (others => '0');
    signal logic_wren                   :       std_logic                       := '0';

    --User input
    signal inp_mode                     :       std_logic                       := '0';

    signal usr_lr                       :       std_logic_vector(1 downto 0)    := (others => '0');
    signal usr_lr_en                    :       std_logic                       := '0';
    signal usr_dwn                      :       std_logic                       := '0';
    signal usr_dwn_en                   :       std_logic                       := '0';
    signal usr_rot                      :       std_logic                       := '0';
    signal usr_rot_en                   :       std_logic                       := '0';

    signal dem_lr                       :       std_logic_vector(1 downto 0)    := (others => '0');
    signal dem_lr_en                    :       std_logic                       := '0';
    signal dem_dwn                      :       std_logic                       := '0';
    signal dem_dwn_en                   :       std_logic                       := '0';
    signal dem_rot                      :       std_logic                       := '0';
    signal dem_rot_en                   :       std_logic                       := '0';

    signal inp_lr                       :       std_logic_vector(1 downto 0)    := (others => '0');
    signal inp_lr_en                    :       std_logic                       := '0';
    signal inp_dwn                      :       std_logic                       := '0';
    signal inp_dwn_en                   :       std_logic                       := '0';
    signal inp_rot                      :       std_logic                       := '0';
    signal inp_rot_en                   :       std_logic                       := '0';

    --Logic
    signal game_tick                    :       std_logic                       := '0';
    signal game_state                   :       std_logic_vector(1 downto 0)    := (others => '0');
    signal game_new_piece               :       std_logic                       := '0';
    signal game_piece_type              :       std_logic_vector(2 downto 0)    := (others => '0');
    signal game_piece_type_next         :       std_logic_vector(2 downto 0)    := (others => '0');
    signal game_piece_h                 :       std_logic_vector(4 downto 0)    := (others => '0');
    signal game_piece_v                 :       std_logic_vector(4 downto 0)    := (others => '0');
    signal game_piece_r                 :       std_logic_vector(1 downto 0)    := (others => '0');
    signal game_row_full                :       std_logic                       := '0';
    signal game_overlap                 :       std_logic                       := '0';
    signal game_over                    :       std_logic                       := '0';

    --Score
    signal line_clear_count             :       std_logic_vector(23 downto 0)   := (others => '0');

    component pixel_clk_pll is
        port (
            refclk                      : in    std_logic                       := '0';
            rst                         : in    std_logic                       := '0';
            outclk_0                    : out   std_logic;
            outclk_1                    : out   std_logic;
            outclk_2                    : out   std_logic
        );
    end component pixel_clk_pll;
    
    component button_input is
        port (
            CLK                         : in    std_logic;
            KEYS                        : in    std_logic_vector(3 downto 0);

            USR_INPUT_LR                : out   std_logic_vector(1 downto 0);
            USR_INPUT_LR_EN             : out   std_logic;
            USR_INPUT_DWN               : out   std_logic;
            USR_INPUT_DWN_EN            : out   std_logic;
            USR_INPUT_ROT               : out   std_logic;
            USR_INPUT_ROT_EN            : out   std_logic
        );
    end component;

    component demo_mode is
        port (
            CLK                         : in    std_logic;
            GAME_TICK                   : in    std_logic;
            GAME_STATE                  : in    std_logic_vector(1 downto 0);

            DEMO_INPUT_LR               : out   std_logic_vector(1 downto 0);
            DEMO_INPUT_LR_EN            : out   std_logic;
            DEMO_INPUT_DWN              : out   std_logic;
            DEMO_INPUT_DWN_EN           : out   std_logic;
            DEMO_INPUT_ROT              : out   std_logic;
            DEMO_INPUT_ROT_EN           : out   std_logic
        );
    end component;

    component game_controller is
        port (
            CLK                         : in    std_logic;
            RENDER_BUSY                 : in    std_logic;

            USR_INPUT_LR                : in    std_logic_vector(1 downto 0);
            USR_INPUT_LR_EN             : in    std_logic;
            USR_INPUT_DWN               : in    std_logic;
            USR_INPUT_DWN_EN            : in    std_logic;
            USR_INPUT_ROT               : in    std_logic;
            USR_INPUT_ROT_EN            : in    std_logic;

            GAME_TICK                   : in    std_logic;
            GAME_PIECE_H                : out   std_logic_vector(4 downto 0);
            GAME_PIECE_V                : out   std_logic_vector(4 downto 0);
            GAME_PIECE_R                : out   std_logic_vector(1 downto 0);
            GAME_ROW_FULL               : in    std_logic;
            GAME_OVERLAP                : in    std_logic;
            GAME_OVER                   : in    std_logic;

            MEM_OP                      : out   std_logic_vector(1 downto 0);
            MEM_ROW                     : out   std_logic_vector(4 downto 0);

            CHECK_ADDR                  : out   std_logic_vector(8 downto 0);

            GAME_NEW_PIECE              : out   std_logic;
            GAME_STATE                  : out   std_logic_vector(1 downto 0);
            GAME_SCORE                  : out   std_logic_vector(23 downto 0)
        );
    end component;

    component piece_generator is
        port (
            CLK                                 : in    std_logic;
            GAME_STATE                          : in    std_logic_vector(1 downto 0);
            GAME_NEW_PIECE                      : in    std_logic;

            GAME_PIECE_TYPE                     : out   std_logic_vector(2 downto 0);
            GAME_PIECE_TYPE_NEXT                : out   std_logic_vector(2 downto 0)
        );
    end component;

    component board_ram is
        port (
            address_a                   : in    std_logic_vector(5 downto 0);
            address_b                   : in    std_logic_vector(5 downto 0);
            clock                       : in    std_logic                       := '1';
            data_a                      : in    std_logic_vector(31 downto 0);
            data_b                      : in    std_logic_vector(31 downto 0);
            wren_a                      : in    std_logic                       := '0';
            wren_b                      : in    std_logic                       := '0';
            q_a                         : out   std_logic_vector(31 downto 0);
            q_b                         : out   std_logic_vector(31 downto 0)
        );
    end component;

    component board_operator is
        port (
            CLK                         : in    std_logic;
            MEM_OP                      : in    std_logic_vector(1 downto 0);
            MEM_ROW                     : in    std_logic_vector(4 downto 0);

            CHECK_ADDR                  : in    std_logic_vector(8 downto 0);
            LOGIC_DATA_OUT              : out   std_logic_vector(31 downto 0);
            LOGIC_DATA_IN               : in    std_logic_vector(31 downto 0);
            LOGIC_WREN                  : out   std_logic;

            BOARD_DATA_IN               : in    std_logic_vector(31 downto 0)
        );
    end component;

    component piece_overlay is
        port (
            CLK                         : in    std_logic;
            ROW_IN                      : in    std_logic_vector(31 downto 0);
            ROW_ADDR                    : in    std_logic_vector(4 downto 0);
            ROW_OUT                     : out   std_logic_vector(29 downto 0);
            
            CHECK_ADDR                  : in    std_logic_vector(8 downto 0);
            CHECK_DATA                  : in    std_logic_vector(31 downto 0);

            GAME_STATE                  : in    std_logic_vector(1 downto 0);
            GAME_PIECE_TYPE             : in    std_logic_vector(2 downto 0);
            GAME_PIECE_H                : in    std_logic_vector(4 downto 0);
            GAME_PIECE_V                : in    std_logic_vector(4 downto 0);
            GAME_PIECE_R                : in    std_logic_vector(1 downto 0);
            GAME_ROW_FULL               : out   std_logic;
            GAME_OVERLAP                : out   std_logic;
            GAME_OVER                   : out   std_logic
        );
    end component;

    component board_renderer is
        port (
            PXL_CLK                     : in    std_logic;
            BOARD_ROW_INDEX             : out   std_logic_vector(4 downto 0);
            BOARD_ROW                   : in    std_logic_vector(29 downto 0);
            BOARD_RDY                   : out   std_logic;

            RES_SEL                     : in    std_logic_vector(1 downto 0);
            H_PXL_COUNT                 : in    std_logic_vector(10 downto 0);
            V_PXL_COUNT                 : in    std_logic_vector(10 downto 0);

            GAME_STATE                  : in    std_logic_vector(1 downto 0);
            NEXT_PIECE                  : in    std_logic_vector(2 downto 0);

            VGA_R                       : out   std_logic_vector(7 downto 0);
            VGA_G                       : out   std_logic_vector(7 downto 0);
            VGA_B                       : out   std_logic_vector(7 downto 0)
        );
    end component;

    component VGA_driver is
        port (
            PXL_CLK                     : in    std_logic;
            RES_SEL                     : in    std_logic_vector(1 downto 0);
            H_PXL_COUNT                 : out   std_logic_vector(10 downto 0);
            V_PXL_COUNT                 : out   std_logic_vector(10 downto 0);
            
            H_PXL_VALID                 : out   std_logic;
            V_PXL_VALID                 : out   std_logic;

            VGA_CLK_OUT                 : out   std_logic;
            VGA_BLANK_N_OUT             : out   std_logic;
            VGA_HS_OUT                  : out   std_logic;
            VGA_VS_OUT                  : out   std_logic;
            VGA_SYNC_N_OUT              : out   std_logic
        );
    end component;

    component score_to_hex is
        port (
            LINE_CLEAR_CNT              : in    std_logic_vector(23 downto 0);

            HEX0                        : out   std_logic_vector(6 downto 0);
            HEX1                        : out   std_logic_vector(6 downto 0);
            HEX2                        : out   std_logic_vector(6 downto 0);
            HEX3                        : out   std_logic_vector(6 downto 0);
            HEX4                        : out   std_logic_vector(6 downto 0);
            HEX5                        : out   std_logic_vector(6 downto 0)
        );
    end component;

begin

    pll_reset <= '0';
    board_addr <= game_state(0) & render_addr;

    pixel_clk_pll_inst : pixel_clk_pll
        port map(
            refclk                          => CLOCK4_50,
            rst                             => pll_reset,
            outclk_0                        => vga_pixel_clk,
            outclk_1                        => svga_pixel_clk,
            outclk_2                        => xga_pixel_clk
        );

    game_tick_inst : process(CLOCK_50)
        begin
            if rising_edge(CLOCK_50) then
                if game_new_piece = '1' then
                    game_tick <= '0';
                    clk_50_counter <= (others => '0');
                elsif clk_50_counter = (unsigned(const_50M) - (unsigned(line_clear_count(7 downto 0) & "000000000000000000"))) then
                    game_tick <= '1';
                    clk_50_counter <= (others => '0');
                else
                    game_tick <= '0';
                    clk_50_counter <= clk_50_counter + 1;
                end if;
            end if;
        end process;

    modes_sel_inst : process(CLOCK_50)
        begin
            if rising_edge(CLOCK_50) then
                if GAME_STATE /= "10" then
                    res_sel <= SW(9 downto 8);
                    inp_mode <= SW(0);
                end if;
            end if;
        end process;

    clock_mux_inst : process(res_sel, svga_pixel_clk, xga_pixel_clk, vga_pixel_clk)
        begin
            case res_sel is
                when "01" => 
                    pixel_clk <= svga_pixel_clk;
                when "10" => 
                    pixel_clk <= xga_pixel_clk;
                when others => 
                    pixel_clk <= vga_pixel_clk;
            end case;
        end process;

    input_mux_inst : process(inp_mode, usr_dwn, usr_dwn_en, usr_rot, usr_rot_en, usr_lr, usr_lr_en, dem_dwn, dem_dwn_en, dem_rot, dem_rot_en, dem_lr, dem_lr_en)
        begin
            if inp_mode = '1' then
                inp_dwn <= dem_dwn;
                inp_dwn_en <= dem_dwn_en;
                inp_rot <= dem_rot;
                inp_rot_en <= dem_rot_en;
                inp_lr <= dem_lr;
                inp_lr_en <= dem_lr_en;
            else
                inp_dwn <= usr_dwn;
                inp_dwn_en <= usr_dwn_en;
                inp_rot <= usr_rot;
                inp_rot_en <= usr_rot_en;
                inp_lr <= usr_lr;
                inp_lr_en <= usr_lr_en;
            end if;
        end process;

    button_input_inst : button_input
        port map (
            CLK                             => CLOCK_50, 
            KEYS                            => KEY, 

            USR_INPUT_LR                    => usr_lr, 
            USR_INPUT_LR_EN                 => usr_lr_en, 
            USR_INPUT_DWN                   => usr_dwn, 
            USR_INPUT_DWN_EN                => usr_dwn_en, 
            USR_INPUT_ROT                   => usr_rot, 
            USR_INPUT_ROT_EN                => usr_rot_en
        );

    demo_mode_inst : demo_mode
        port map(
            CLK                             => CLOCK_50,
            GAME_TICK                       => game_tick,        
            GAME_STATE                      => game_state,

            DEMO_INPUT_LR                   => dem_lr,
            DEMO_INPUT_LR_EN                => dem_lr_en, 
            DEMO_INPUT_DWN                  => dem_dwn, 
            DEMO_INPUT_DWN_EN               => dem_dwn_en, 
            DEMO_INPUT_ROT                  => dem_rot, 
            DEMO_INPUT_ROT_EN               => dem_rot_en 
        );
    
    game_controller_inst : game_controller
        port map(
            CLK                             => CLOCK_50, 
            RENDER_BUSY                     => v_pxl_valid, 

            USR_INPUT_LR                    => inp_lr, 
            USR_INPUT_LR_EN                 => inp_lr_en, 
            USR_INPUT_DWN                   => inp_dwn,   
            USR_INPUT_DWN_EN                => inp_dwn_en,  
            USR_INPUT_ROT                   => inp_rot, 
            USR_INPUT_ROT_EN                => inp_rot_en, 

            GAME_TICK                       => game_tick, 
            GAME_PIECE_H                    => game_piece_h, 
            GAME_PIECE_V                    => game_piece_v, 
            GAME_PIECE_R                    => game_piece_r, 
            GAME_ROW_FULL                   => game_row_full, 
            GAME_OVERLAP                    => game_overlap, 
            GAME_OVER                       => game_over,

            MEM_OP                          => mem_op, 
            MEM_ROW                         => mem_row, 

            CHECK_ADDR                      => check_addr, 

            GAME_NEW_PIECE                  => game_new_piece, 
            GAME_STATE                      => game_state, 
            GAME_SCORE                      => line_clear_count
        );

    piece_generator_inst : piece_generator
        port map(
            CLK                             => CLOCK_50,   
            GAME_STATE                      => game_state, 
            GAME_NEW_PIECE                  => game_new_piece, 

            GAME_PIECE_TYPE                 => game_piece_type, 
            GAME_PIECE_TYPE_NEXT            => game_piece_type_next 
        );
    
    board_ram_inst : board_ram
        port map(
            address_a                       => '0' & check_addr(7 downto 3), 
            address_b                       => board_addr, 
            clock                           => CLOCK_50, 
            data_a                          => logic_data_in, 
            data_b                          => (others => '0'), 
            wren_a                          => logic_wren, 
            wren_b                          => '0', 
            q_a                             => logic_data_out, 
            q_b                             => overlay_data 
        );

    board_operator_inst : board_operator
        port map(
            CLK                             => CLOCK_50,      
            MEM_OP                          => mem_op, 
            MEM_ROW                         => mem_row, 

            CHECK_ADDR                      => check_addr, 
            LOGIC_DATA_OUT                  => logic_data_in, 
            LOGIC_DATA_IN                   => logic_data_out, 
            LOGIC_WREN                      => logic_wren,

            BOARD_DATA_IN                   => "00" & render_data_out 
        );
    
    piece_overlay_inst : piece_overlay
        port map(
            CLK                             => CLOCK_50,          
            ROW_IN                          => overlay_data, 
            ROW_ADDR                        => render_addr,
            ROW_OUT                         => render_data_out, 
            
            CHECK_ADDR                      => check_addr, 
            CHECK_DATA                      => logic_data_out, 

            GAME_STATE                      => game_state, 
            GAME_PIECE_TYPE                 => game_piece_type, 
            GAME_PIECE_H                    => game_piece_h, 
            GAME_PIECE_V                    => game_piece_v, 
            GAME_PIECE_R                    => game_piece_r,
            GAME_ROW_FULL                   => game_row_full, 
            GAME_OVERLAP                    => game_overlap,
            GAME_OVER                       => game_over
        );
        
    boardrenderer_inst : board_renderer
        port map(
            PXL_CLK                         => pixel_clk, 
            BOARD_ROW_INDEX                 => render_addr(4 downto 0),
            BOARD_ROW                       => render_data_out,
            BOARD_RDY                       => v_pxl_valid, 

            RES_SEL                         => res_sel,
            H_PXL_COUNT                     => h_pxl_count,
            V_PXL_COUNT                     => v_pxl_count,

            GAME_STATE                      => game_state,
            NEXT_PIECE                      => game_piece_type_next,

            VGA_R                           => VGA_R,
            VGA_G                           => VGA_G,
            VGA_B                           => VGA_B
        );

    vga_driver_inst : VGA_driver
        port map(
            PXL_CLK                         => pixel_clk,
            RES_SEL                         => res_sel,
            H_PXL_COUNT                     => h_pxl_count,
            V_PXL_COUNT                     => v_pxl_count,

            H_PXL_VALID                     => open,
            V_PXL_VALID                     => open,
    
            VGA_CLK_OUT                     => VGA_CLK,
            VGA_BLANK_N_OUT                 => VGA_BLANK_N,
            VGA_HS_OUT                      => VGA_HS,
            VGA_VS_OUT                      => VGA_VS,
            VGA_SYNC_N_OUT                  => VGA_SYNC_N
        );

    score_to_hex_inst : score_to_hex
        port map(
            LINE_CLEAR_CNT                  => line_clear_count,

            HEX0                            => HEX0,
            HEX1                            => HEX1,
            HEX2                            => HEX2,
            HEX3                            => HEX3,
            HEX4                            => HEX4,
            HEX5                            => HEX5
        );

end architecture;