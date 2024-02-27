library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use STD.textio.all;
use ieee.std_logic_textio.all;
use ieee.math_real.all;

library work;
use work.type_definitions_pckg.all;
use work.function_pckg.all;


entity tb_true_vhdl is
  generic(
    gi_width          : integer range 5 to 8   := 8;
    gi_latency        : integer                := 2
  );
end tb_true_vhdl;

architecture behave of tb_true_vhdl is

  constant clk_period_ns              : time := 10 ns;
  --
  ------------------------------------------------------------------------------------------------
  -- Signal Area
  ------------------------------------------------------------------------------------------------
  signal sl_clk_in                    : std_logic := '0';
  signal sl_rst_in                    : std_logic := '1';
  --
  signal sl_tb_vld_in                 : std_logic;
  signal sl_tb_rdy_out                : std_logic;
  signal sv_tb_data_a_in              : std_logic_vector(4-1 downto 0);
  signal sv_tb_data_b_in              : std_logic_vector(4-1 downto 0);
  --
  signal sl_tb_vld_out                : std_logic;
  signal sl_tb_data_out               : std_logic_vector(14-1 downto 0);

begin
  -- Clock Process
  process
  begin
    sl_clk_in <= not(sl_clk_in);
    wait for clk_period_ns/2;
  end process;

  process
  begin

  -- reset stuff
  sl_rst_in                 <= '1';
  sl_tb_vld_in              <= '0';
  sv_tb_data_a_in           <= (others => '0');
  sv_tb_data_b_in           <= (others => '0');
  wait for 10 us;
  wait until (rising_edge(sl_clk_in));
  sl_rst_in                 <= '0';
  wait until (rising_edge(sl_clk_in));

  for m in 0 to 15 loop
    for n in 0 to 15 loop
      sl_tb_vld_in          <= '1';
      sv_tb_data_a_in       <= std_logic_vector(to_unsigned(m, sv_tb_data_a_in'length));
      sv_tb_data_b_in       <= std_logic_vector(to_unsigned(n, sv_tb_data_b_in'length));
      wait until (rising_edge(sl_clk_in));
      sl_tb_vld_in          <= '0';
      wait until (sl_tb_vld_out = '1');
    end loop;
  end loop;
  wait;
  end process;

-- Instance Area

  true_vhdl_inst : entity work.true_vhdl
  generic map(
    gi_width              => gi_width,
    gi_latency            => gi_latency
   )
   port map (
    clk_in                => sl_clk_in,
    rst_in                => sl_rst_in,
    --
    vld_in                => sl_tb_vld_in,
    rdy_out               => sl_tb_rdy_out,
    data_a_in             => sv_tb_data_a_in,
    data_b_in             => sv_tb_data_b_in,
    --
    vld_out               => sl_tb_vld_out,
    data_out              => sl_tb_data_out
  );

end architecture behave;
