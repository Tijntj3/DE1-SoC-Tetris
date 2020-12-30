library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity demo_mode is
    port (
        CLK                                 : in    std_logic;
        GAME_TICK                           : in    std_logic;
        GAME_STATE                          : in    std_logic_vector(1 downto 0);

        DEMO_INPUT_LR                       : out   std_logic_vector(1 downto 0);
        DEMO_INPUT_LR_EN                    : out   std_logic;
        DEMO_INPUT_DWN                      : out   std_logic;
        DEMO_INPUT_DWN_EN                   : out   std_logic;
        DEMO_INPUT_ROT                      : out   std_logic;
        DEMO_INPUT_ROT_EN                   : out   std_logic
    );
end entity;

architecture behaviour of demo_mode is
    
    signal tick_counter                     :       unsigned(5 downto 0)            := (others => '0');
    signal rom_data                         :       std_logic_vector(3 downto 0)    := (others => '0');

    signal input_data                       :       std_logic_vector(3 downto 0)    := (others => '0');

    component demo_rom is
        port(
            address                         : in    std_logic_vector(5 downto 0);
            clock                           : in    std_logic                       := '1';
            q                               : out   std_logic_vector(3 downto 0)
        );
    end component;
    
begin

    DEMO_INPUT_LR <= input_data(3 downto 2);
    DEMO_INPUT_LR_EN <= input_data(3) or input_data(2);
    DEMO_INPUT_ROT <= input_data(1);
    DEMO_INPUT_ROT_EN <= input_data(1);
    DEMO_INPUT_DWN <= input_data(0);
    DEMO_INPUT_DWN_EN <= input_data(0);

    demo_rom_inst : demo_rom
        port map(
            address                         => std_logic_vector(tick_counter),
            clock                           => CLK,
            q                               => rom_data
        );

    rom_inc : process(CLK)
        begin
            if rising_edge(CLK) then
                if GAME_STATE = "10" then
                    if GAME_TICK = '1' then
                        tick_counter <= tick_counter + 1;
                    end if;
                else 
                    tick_counter <= (others => '0');
                end if;
            end if;
        end process;

    rom_to_input : process(GAME_STATE, GAME_TICK, rom_data)
        begin
            case GAME_STATE is 
                when "01" =>
                    input_data <= (others => '1');
                when "10" =>
                    if GAME_TICK = '1' then
                        input_data <= rom_data;
                    else
                        input_data <= (others => '0');
                    end if;
                when others =>
                    input_data <= (others => '0');
            end case;
        end process;

end architecture;