-- -----------------------------------------------------------------------------------------------
--  Title      : true_vhdl_paralellism
--  Project    : Library
--  File       : true_vhdl.vhd
-- -----------------------------------------------------------------------------------------------

-- -----------------------------------------------------------------------------------------------
-- Description:
-- -----------------------------------------------------------------------------------------------
-- This file does 5 actions. -> 3 addition and 2 multiplications

library ieee;
use ieee.std_logic_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;
use ieee.math_real.all;

library work;
use work.type_definitions_pckg.all;
use work.function_pckg.all;

Library UNISIM;
use UNISIM.vcomponents.all;

Library UNIMACRO;
use UNIMACRO.vcomponents.all;


entity true_vhdl is
  generic(
    gi_width          : integer range 5 to 8   := 8;
    gi_latency        : integer                := 2
  );
  port(
    -- Common Interface
    clk_in                  : in  std_logic;
    rst_in                  : in  std_logic;
    --
    vld_in                  : in std_logic;
    rdy_out                 : out std_logic;
    data_a_in               : in std_logic_vector(4-1 downto 0);
    data_b_in               : in std_logic_vector(4-1 downto 0);
    --
    vld_out                 : out std_logic;
    data_out                : out std_logic_vector(14-1 downto 0)

  );
end entity true_vhdl;

architecture rtl of true_vhdl is

  constant ci_byte        : integer := 8;

  ------------------------------------------------------------------------------------------------
  -- Signal Area
  ------------------------------------------------------------------------------------------------

  --signal data_a_in            : std_logic_vector(ci_byte-1 downto 0);
  --signal data_b_in            : std_logic_vector(ci_byte-1 downto 0);
  signal v                    : std_logic_vector(5-1 downto 0);
  signal v_vld_out            : std_logic;
  signal w                    : std_logic_vector(6-1 downto 0);
  signal w_vld_out            : std_logic;
  signal y                    : std_logic_vector(7-1 downto 0);
  signal y_vld_out            : std_logic;
  signal x                    : std_logic_vector(7-1 downto 0);
  signal x_vld_out            : std_logic;
  signal z                    : std_logic_vector(14-1 downto 0);
  signal z_vld_out            : std_logic;
  -------
  signal sl_addsub1_vld_in    : std_logic;
  signal sv_addsub1_data_A_in : std_logic_vector(4-1 downto 0);
  signal sv_addsub1_data_B_in : std_logic_vector(4-1 downto 0);
  signal sl_addsub1_vld_out   : std_logic;
  signal sv_addsub1_data_out  : std_logic_vector(5-1 downto 0);
  --
  signal sl_addsub2_vld_in    : std_logic;
  signal sv_addsub2_data_A_in : std_logic_vector(6-1 downto 0);
  signal sv_addsub2_data_B_in : std_logic_vector(6-1 downto 0);
  signal sl_addsub2_vld_out   : std_logic;
  signal sv_addsub2_data_out  : std_logic_vector(7-1 downto 0);
  --
  signal sl_addsub3_vld_in    : std_logic;
  signal sv_addsub3_data_A_in : std_logic_vector(6-1 downto 0);
  signal sv_addsub3_data_B_in : std_logic_vector(6-1 downto 0);
  signal sl_addsub3_vld_out   : std_logic;
  signal sv_addsub3_data_out  : std_logic_vector(7-1 downto 0);
  ------
  signal sl_mult1_vld_in      : std_logic;
  signal sl_mult1_rdy_out     : std_logic;
  signal sv_mult1_data_A_in   : std_logic_vector(2-1 downto 0);
  signal sv_mult1_data_B_in   : std_logic_vector(4-1 downto 0);
  signal sl_mult1_vld_out     : std_logic;
  signal sv_mult1_data_out    : std_logic_vector(6-1 downto 0);
  --
  signal sl_mult2_vld_in      : std_logic;
  signal sl_mult2_rdy_out     : std_logic;
  signal sv_mult2_data_A_in   : std_logic_vector(7-1 downto 0);
  signal sv_mult2_data_B_in   : std_logic_vector(7-1 downto 0);
  signal sl_mult2_vld_out     : std_logic;
  signal sv_mult2_data_out    : std_logic_vector(14-1 downto 0);
  ------
  signal sv_vldout_to_vldin1  : std_logic_vector(2-1 downto 0);
  signal sv_vldout_to_vldin2  : std_logic_vector(2-1 downto 0);
  signal sv_vldout_to_vldin3  : std_logic_vector(2-1 downto 0);

begin
  ------------------------------------------------------------------------------------------------
  -- Wiring Area
  ------------------------------------------------------------------------------------------------

  -- first addition step --         v <= a + b;
  sl_addsub1_vld_in     <= vld_in;
  sv_addsub1_data_A_in  <= data_a_in;
  sv_addsub1_data_B_in  <= data_b_in;
  v                     <= sv_addsub1_data_out;
  v_vld_out             <= sl_addsub1_vld_out;

  -- second step: multiplication    w <= b * 2;
  sl_mult1_vld_in       <= vld_in;
  sv_mult1_data_A_in    <= "10";
  sv_mult1_data_B_in    <= data_b_in;
  w                     <= sv_mult1_data_out;
  w_vld_out             <= sl_mult1_vld_out;

  -- third step: subtraction        x <= v - w;
  x         <= sv_addsub2_data_out;
  x_vld_out <= sl_addsub2_vld_out;

  -- fourth step: subtraction       y <= v + w;
  y         <= sv_addsub3_data_out;
  y_vld_out <= sl_addsub3_vld_out;

  -- fifth step: multiplication     z <= x * y;
  z         <= sv_mult2_data_out;
  z_vld_out <= sl_mult2_vld_out;

  data_out  <= z;
  vld_out   <= z_vld_out;

  ------------------------------------------------------------------------------------------------
  -- Process Area RX
  ------------------------------------------------------------------------------------------------
  third_line_process :  -- x <= v - w
  process (clk_in, rst_in)
  begin
    if (rst_in = '1') then
      sv_vldout_to_vldin1     <= (others => '0');
      sv_addsub2_data_A_in    <= (others => '0');
      sv_addsub2_data_B_in    <= (others => '0');
      sl_addsub2_vld_in       <= '0';
    elsif (rising_edge(clk_in)) then
      --sv_vldout_to_vldin1 <= "00";
      if (v_vld_out = '1') then
        sv_vldout_to_vldin1(0) <= '1';
      end if;

      if (w_vld_out = '1') then
        sv_vldout_to_vldin1(1) <= '1';
      end if;

      if (sv_vldout_to_vldin1 = "11") then
        sv_addsub2_data_A_in  <= '0' & v;
        sv_addsub2_data_B_in  <= w;
        sl_addsub2_vld_in     <= '1';
        sv_vldout_to_vldin1   <= (others => '0');
      else
        sl_addsub2_vld_in     <= '0';
      end if;
    end if;
  end process;

  fourth_line_process : -- y <= v + w
  process (clk_in, rst_in)
  begin
    if (rst_in = '1') then
      sv_vldout_to_vldin2     <= (others => '0');
      sv_addsub3_data_A_in    <= (others => '0');
      sv_addsub3_data_B_in    <= (others => '0');
      sl_addsub3_vld_in       <= '0';
    elsif (rising_edge(clk_in)) then
      if (v_vld_out = '1') then
        sv_vldout_to_vldin2(0)<= '1';
      end if;

      if (w_vld_out = '1') then
        sv_vldout_to_vldin2(1)<= '1';
      end if;

      if (sv_vldout_to_vldin2 = "11") then
        sv_addsub3_data_A_in  <= '0' & v;
        sv_addsub3_data_B_in  <= w;
        sl_addsub3_vld_in     <= '1';
        sv_vldout_to_vldin2   <= (others => '0');
      else
        sl_addsub3_vld_in     <= '0';
      end if;
    end if;
  end process;

  fifth_line_process : -- z <= x * y
  process (clk_in, rst_in)
  begin
    if (rst_in = '1') then
      sv_vldout_to_vldin3     <= (others => '0');
      sv_mult2_data_A_in      <= (others => '0');
      sv_mult2_data_B_in      <= (others => '0');
      sl_mult2_vld_in         <= '0';
    elsif (rising_edge(clk_in)) then
      if (x_vld_out = '1') then
        sv_vldout_to_vldin3(0)<= '1';
      end if;

      if (y_vld_out = '1') then
        sv_vldout_to_vldin3(1)<= '1';
      end if;

      if (sv_vldout_to_vldin3 = "11") then
        sv_mult2_data_A_in  <= x;
        sv_mult2_data_B_in  <= y;
        sl_mult2_vld_in     <= '1';
        sv_vldout_to_vldin3 <= (others => '0');
      else
        sl_mult2_vld_in     <= '0';
      end if;
    end if;
  end process;


  ------------------------------------------------------------------------------------------------
  -- Instance Area
  ------------------------------------------------------------------------------------------------

  -- 1Q15 to 2Q15 --    v <= a + b
  addsub_sign_first : entity work.addsub_sign
  generic map (
    G_LATENCY           => gi_latency,
    G_WIDTH             => 4
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    add_sub_in          => '1', -- high selects add
    carry_in            => '0',
    carry_out           => open,
    vld_in              => sl_addsub1_vld_in,
    data_A_in           => sv_addsub1_data_A_in,
    data_B_in           => sv_addsub1_data_B_in,
    vld_out             => sl_addsub1_vld_out,
    data_out            => sv_addsub1_data_out
  );

  -- 1Q15 to 2Q15 --    x <= v - w
  addsub_sign_second : entity work.addsub_sign
  generic map (
    G_LATENCY           => gi_latency,
    G_WIDTH             => 6
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    add_sub_in          => '0',  -- low selects subtract
    carry_in            => '0',
    carry_out           => open,
    vld_in              => sl_addsub2_vld_in,
    data_A_in           => sv_addsub2_data_A_in,
    data_B_in           => sv_addsub2_data_B_in,
    vld_out             => sl_addsub2_vld_out,
    data_out            => sv_addsub2_data_out
  );

  -- 1Q15 to 2Q15 --    y <= v + w
  addsub_sign_third : entity work.addsub_sign
  generic map (
    G_LATENCY           => gi_latency,
    G_WIDTH             => 6
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    add_sub_in          => '1',  -- high selects add
    carry_in            => '0',
    carry_out           => open,
    vld_in              => sl_addsub3_vld_in,
    data_A_in           => sv_addsub3_data_A_in,
    data_B_in           => sv_addsub3_data_B_in,
    vld_out             => sl_addsub3_vld_out,
    data_out            => sv_addsub3_data_out
  );


  -- multiply 8Q0 x 2Q0 to 10Q0 --      w <= b * 2
  mult_sign_v1_first : entity work.mult_sign_v1
  generic map (
    G_LATENCY           => gi_latency,
    G_WIDTH_A           => 2,
    G_WIDTH_B           => 4
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    vld_in              => sl_mult1_vld_in,
    rdy_out             => sl_mult1_rdy_out,
    data_A_in           => sv_mult1_data_A_in,
    data_B_in           => sv_mult1_data_B_in,
    vld_out             => sl_mult1_vld_out,
    data_out            => sv_mult1_data_out
  );

  -- multiply 8Q0 x 2Q0 to 10Q0 --      z <= x * y
  mult_sign_v1_second : entity work.mult_sign_v1
  generic map (
    G_LATENCY           => gi_latency,
    G_WIDTH_A           => 7,
    G_WIDTH_B           => 7
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    vld_in              => sl_mult2_vld_in,
    rdy_out             => sl_mult2_rdy_out,
    data_A_in           => sv_mult2_data_A_in,
    data_B_in           => sv_mult2_data_B_in,
    vld_out             => sl_mult2_vld_out,
    data_out            => sv_mult2_data_out
  );

end architecture rtl;