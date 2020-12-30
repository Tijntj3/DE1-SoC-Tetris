library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity button_input is
    port (
        CLK                                 : in    std_logic;
        KEYS                                : in    std_logic_vector(3 downto 0);

        USR_INPUT_LR                        : out   std_logic_vector(1 downto 0);
        USR_INPUT_LR_EN                     : out   std_logic;
        USR_INPUT_DWN                       : out   std_logic;
        USR_INPUT_DWN_EN                    : out   std_logic;
        USR_INPUT_ROT                       : out   std_logic;
        USR_INPUT_ROT_EN                    : out   std_logic
    );
end entity;

architecture behaviour of button_input is
    
    signal key0_reg                         :       std_logic_vector(1 downto 0)    := (others => '0');
    signal key1_reg                         :       std_logic_vector(1 downto 0)    := (others => '0');
    signal key2_reg                         :       std_logic_vector(1 downto 0)    := (others => '0');
    signal key3_reg                         :       std_logic_vector(1 downto 0)    := (others => '0');

    signal key0_rising                      :       std_logic                       := '0';
    signal key1_rising                      :       std_logic                       := '0';
    signal key2_rising                      :       std_logic                       := '0';
    signal key3_rising                      :       std_logic                       := '0';

    signal usr_rot                          :       std_logic                       := '0';
    signal usr_rot_en                       :       std_logic                       := '0';
    signal usr_dwn                          :       std_logic                       := '0';
    signal usr_dwn_en                       :       std_logic                       := '0';
    signal usr_lr                           :       std_logic_vector(1 downto 0)    := (others => '0');
    signal usr_lr_en                        :       std_logic                       := '0';

begin

    USR_INPUT_ROT <= usr_rot;
    USR_INPUT_ROT_EN <= usr_rot_en;
    USR_INPUT_DWN <= usr_dwn;
    USR_INPUT_DWN_EN <= usr_dwn_en;
    USR_INPUT_LR <= usr_lr;
    USR_INPUT_LR_EN <= usr_lr_en;

    sample_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                key0_reg <= key0_reg(0) & KEYS(0);
                key1_reg <= key1_reg(0) & KEYS(1);
                key2_reg <= key2_reg(0) & KEYS(2);
                key3_reg <= key3_reg(0) & KEYS(3);

                usr_rot <= key0_rising;
                usr_rot_en <= key0_rising;
                usr_dwn <= key2_rising;
                usr_dwn_en <= key2_rising;
                usr_lr <= key3_rising & key1_rising;
                usr_lr_en <= key3_rising or key1_rising;
            end if;
        end process;
    
    key0_edge_inst : process(key0_reg)
        begin
            key0_rising <= key0_reg(1) and not(key0_reg(0));
        end process;

    key1_edge_inst : process(key1_reg)
        begin
            key1_rising <= key1_reg(1) and not(key1_reg(0));
        end process;

    key2_edge_inst : process(key2_reg)
        begin
            key2_rising <= key2_reg(1) and not(key2_reg(0));
        end process;
    
    key3_edge_inst : process(key3_reg)
        begin
            key3_rising <= key3_reg(1) and not(key3_reg(0));
        end process;

end architecture;