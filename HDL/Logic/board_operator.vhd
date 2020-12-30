library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity board_operator is
    port (
        CLK                                 : in    std_logic;
        MEM_OP                              : in    std_logic_vector(1 downto 0);
        MEM_ROW                             : in    std_logic_vector(4 downto 0);

        CHECK_ADDR                          : in    std_logic_vector(8 downto 0);
        LOGIC_DATA_OUT                      : out   std_logic_vector(31 downto 0);
        LOGIC_DATA_IN                       : in    std_logic_vector(31 downto 0);
        LOGIC_WREN                          : out   std_logic;

        BOARD_DATA_IN                       : in    std_logic_vector(31 downto 0)
    );
end entity;

architecture behaviour of board_operator is
    
    signal state                            :       std_logic_vector(1 downto 0)    := (others => '0');
    signal row_buffer                       :       std_logic_vector(4 downto 0)    := (others => '0');
    signal line_buffer                      :       std_logic_vector(31 downto 0)   := (others => '0');

    signal logic_data_out_s                 :       std_logic_vector(31 downto 0)   := (others => '0');
    signal logic_wren_s                     :       std_logic                       := '0';

begin

    LOGIC_DATA_OUT <= logic_data_out_s;
    LOGIC_WREN <= logic_wren_s;

    sequencer_inst : process(CLK)
        begin
            if rising_edge(CLK) then
                if (MEM_OP(0) or MEM_OP(1)) = '1' then
                    state <= MEM_OP;
                    row_buffer <= MEM_ROW;
                    line_buffer <= (others => '0');
                    logic_data_out_s <= (others => '0');
                    logic_wren_s <= '0';
                else
                    if CHECK_ADDR = "000000001" then
                        state <= "00";
                    end if;
                    if CHECK_ADDR(8) = '0' then
                        case state is
                            when "01" => -- Write current piece into board
                                case (CHECK_ADDR(2 downto 0)) is
                                    when "001" =>
                                        logic_wren_s <= '1';
                                        logic_data_out_s <= BOARD_DATA_IN;
                                    when others =>
                                        logic_wren_s <= '0';
                                        logic_data_out_s <= (others => '0');
                                end case;
                            when "10" => -- Delete a row from the board
                                if CHECK_ADDR(7 downto 3) >= row_buffer then
                                    case (CHECK_ADDR(2 downto 0)) is
                                        when "001" =>
                                            logic_wren_s <= '1';
                                            logic_data_out_s <= line_buffer;
                                            line_buffer <= LOGIC_DATA_IN;
                                        when others =>
                                            logic_wren_s <= '0';
                                            logic_data_out_s <= (others => '0');
                                    end case;
                                else
                                    logic_wren_s <= '0';
                                    logic_data_out_s <= (others => '0');
                                end if;
                            when "11" => -- Clear the entire board
                                logic_data_out_s <= (others => '0');
                                logic_wren_s <= '1';
                            when others =>
                                logic_data_out_s <= (others => '0');
                                logic_wren_s <= '0';
                        end case;
                    end if;
                end if;
            end if;
        end process;

end architecture;