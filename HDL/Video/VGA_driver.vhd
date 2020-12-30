library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity VGA_driver is
    port (
        PXL_CLK                             : in    std_logic;
        RES_SEL                             : in    std_logic_vector(1 downto 0);
        H_PXL_COUNT                         : out   std_logic_vector(10 downto 0);
        V_PXL_COUNT                         : out   std_logic_vector(10 downto 0);

        H_PXL_VALID                         : out   std_logic;
        V_PXL_VALID                         : out   std_logic;

        VGA_CLK_OUT                         : out   std_logic;
        VGA_BLANK_N_OUT                     : out   std_logic;
        VGA_HS_OUT                          : out   std_logic;
        VGA_VS_OUT                          : out   std_logic;
        VGA_SYNC_N_OUT                      : out   std_logic
    );
end entity;

architecture behavioural of VGA_driver is

    --Mode timings lookup
    --VGA (640x480 @ 60hz)
    constant VGA_h_frontporch_start         :       unsigned(10 downto 0)                 := "01001111111";
    constant VGA_h_sync_start               :       unsigned(10 downto 0)                 := "01010001111";
    constant VGA_h_backporch_start          :       unsigned(10 downto 0)                 := "01011101111";
    constant VGA_h_total                    :       unsigned(10 downto 0)                 := "01100011111";

    constant VGA_v_frontporch_start         :       unsigned(10 downto 0)                 := "00111011111";
    constant VGA_v_sync_start               :       unsigned(10 downto 0)                 := "00111101001";
    constant VGA_v_backporch_start          :       unsigned(10 downto 0)                 := "00111101011";
    constant VGA_v_total                    :       unsigned(10 downto 0)                 := "01000001100";

    --SVGA (800x600 @ 60hz)
    constant SVGA_h_frontporch_start        :       unsigned(10 downto 0)                 := "01100011111";
    constant SVGA_h_sync_start              :       unsigned(10 downto 0)                 := "01101000111";
    constant SVGA_h_backporch_start         :       unsigned(10 downto 0)                 := "01111000111";
    constant SVGA_h_total                   :       unsigned(10 downto 0)                 := "10000011111";

    constant SVGA_v_frontporch_start        :       unsigned(10 downto 0)                 := "01001010111";
    constant SVGA_v_sync_start              :       unsigned(10 downto 0)                 := "01001011000";
    constant SVGA_v_backporch_start         :       unsigned(10 downto 0)                 := "01001011100";
    constant SVGA_v_total                   :       unsigned(10 downto 0)                 := "01001110011";

    --XGA (1024x768 @ 60hz)
    constant XGA_h_frontporch_start         :       unsigned(10 downto 0)                 := "01111111111";
    constant XGA_h_sync_start               :       unsigned(10 downto 0)                 := "10000010111";
    constant XGA_h_backporch_start          :       unsigned(10 downto 0)                 := "10010011111";
    constant XGA_h_total                    :       unsigned(10 downto 0)                 := "10100111111";

    constant XGA_v_frontporch_start         :       unsigned(10 downto 0)                 := "01011111111";
    constant XGA_v_sync_start               :       unsigned(10 downto 0)                 := "01100000010";
    constant XGA_v_backporch_start          :       unsigned(10 downto 0)                 := "01100001000";
    constant XGA_v_total                    :       unsigned(10 downto 0)                 := "01100100101";

    --Signals
    signal h_frontporch_start               :       unsigned(10 downto 0)                 := "10000000000";
    signal h_sync_start                     :       unsigned(10 downto 0)                 := "10000011000";
    signal h_backporch_start                :       unsigned(10 downto 0)                 := "10010100000";
    signal h_total                          :       unsigned(10 downto 0)                 := "10101000000";

    signal v_frontporch_start               :       unsigned(10 downto 0)                 := "01100000000";
    signal v_sync_start                     :       unsigned(10 downto 0)                 := "01100000011";
    signal v_backporch_start                :       unsigned(10 downto 0)                 := "01100001001";
    signal v_total                          :       unsigned(10 downto 0)                 := "01100100110";

    signal v_count                          :       unsigned(10 downto 0)                 := (others => '0');
    signal h_count                          :       unsigned(10 downto 0)                 := (others => '0');

    signal h_valid                          :       std_logic                             := '0';
    signal h_syncPulse                      :       std_logic                             := '0';

    signal v_valid                          :       std_logic                             := '0';
    signal v_syncPulse                      :       std_logic                             := '0';

begin

    VGA_CLK_OUT <= PXL_CLK;
    VGA_HS_OUT <= h_syncPulse;
    VGA_VS_OUT <= v_syncPulse;
    VGA_BLANK_N_OUT <= h_valid and v_valid;
    VGA_SYNC_N_OUT <= '0';

    H_PXL_COUNT <= std_logic_vector(h_count);
    V_PXL_COUNT <= std_logic_vector(v_count);

    H_PXL_VALID <= h_valid;
    V_PXL_VALID <= v_valid;

    timings_mux_inst : process(RES_SEL)
        begin
            case RES_SEL is
                when "01" =>
                    h_frontporch_start <= SVGA_h_frontporch_start;
                    h_sync_start <= SVGA_h_sync_start;
                    h_backporch_start <= SVGA_h_backporch_start;
                    h_total <= SVGA_h_total;
                    v_frontporch_start <= SVGA_v_frontporch_start;
                    v_sync_start <= SVGA_v_sync_start;
                    v_backporch_start <= SVGA_v_backporch_start;
                    v_total <= SVGA_v_total;
                when "10" =>
                    h_frontporch_start <= XGA_h_frontporch_start;
                    h_sync_start <= XGA_h_sync_start;
                    h_backporch_start <= XGA_h_backporch_start;
                    h_total <= XGA_h_total;
                    v_frontporch_start <= XGA_v_frontporch_start;
                    v_sync_start <= XGA_v_sync_start;
                    v_backporch_start <= XGA_v_backporch_start;
                    v_total <= XGA_v_total;
                when others =>
                    h_frontporch_start <= VGA_h_frontporch_start;
                    h_sync_start <= VGA_h_sync_start;
                    h_backporch_start <= VGA_h_backporch_start;
                    h_total <= VGA_h_total;
                    v_frontporch_start <= VGA_v_frontporch_start;
                    v_sync_start <= VGA_v_sync_start;
                    v_backporch_start <= VGA_v_backporch_start;
                    v_total <= VGA_v_total;
            end case;
        end process;

    pxl_clk_counter_inst : process(PXL_CLK)
        begin
            if rising_edge(PXL_CLK) then
                if h_count = h_total then
                    h_count <= (others => '0');
                    if v_count = v_total then
                        v_count <= (others => '0');
                    else
                        v_count <= v_count + 1;
                    end if;
                else
                    h_count <= h_count + 1;
                end if;
            
                if h_count <= h_frontporch_start then
                    h_valid <= '1';
                    h_syncPulse <= '1';
                elsif h_count <= h_sync_start then
                    h_valid <= '0';
                    h_syncPulse <= '1';
                elsif h_count <= h_backporch_start then
                    h_valid <= '0';
                    h_syncPulse <= '0';
                elsif h_count <= h_total then
                    h_valid <= '0';
                    h_syncPulse <= '1';
                else
                    h_valid <= '0';
                    h_syncPulse <= '1';
                end if;

                if v_count <= v_frontporch_start then
                    v_valid <= '1';
                    v_syncPulse <= '1';
                elsif v_count <= v_sync_start then
                    v_valid <= '0';
                    v_syncPulse <= '1';
                elsif v_count <= v_backporch_start then
                    v_valid <= '0';
                    v_syncPulse <= '0';
                else
                    v_valid <= '0';
                    v_syncPulse <= '1';
                end if;
            end if;
        end process;

end architecture;