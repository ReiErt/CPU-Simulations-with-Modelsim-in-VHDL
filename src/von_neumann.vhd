-- -----------------------------------------------------------------------------------------------
--  Title      : von_neumann
--  Project    : Library
--  File       : von_neumann.vhd
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


entity von_neumann is
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
    write_ram_a_in          : in std_logic_vector(16-1 downto 0);
    write_ram_b_in          : in std_logic_vector(16-1 downto 0);
    --
    vld_out                 : out std_logic;
    prog_done_out           : out std_logic;
    data_out                : out std_logic_vector(16-1 downto 0)

  );
end entity von_neumann;

architecture rtl of von_neumann is

  constant ci_byte        : integer := 8;

  ------------------------------------------------------------------------------------------------
  -- Type Area
  ------------------------------------------------------------------------------------------------

  type von_neumann_fsm is (IDLE, INSTRUCTION_FETCH, DATA_FETCH, DECODE, EXECUTE, STORE, PC_INCR);

  type ram_array is array (0 to 15) of std_logic_vector(15 downto 0);
  signal ram_data : ram_array := (

  -- opcode 4 bit  //  4 bit (destination)  // operand1 4 bit // operand2 4 bit
    "0001100010001001", -- 0: v <= a + b
    "0100100110011101", -- 1: w <= b * 2
    "0010101010001001", -- 2: x <= v - w
    "0001101110001001", -- 3: y <= v + w
    "0100110010111011", -- 4: z <= x * y
    "0000000000000000", -- empty
    "0000000000000000", -- empty
    "0000000000000000", -- empty
    "0000000000001111", -- 8: stores input 'a' value
    "0000000000001100", -- 9: stores input 'b' value
    "0000000000000000", -- 10: 'x' is stored
    "0000000000000000", -- 11: 'y' is stored
    "0000000000000000", -- 12: 'z' is stored
    "0000000000000010", -- 13: constant '2' is stored
    "0000000000000000", -- 14: constant '2' is stored
    "0000000000000000" --  15: constant '2' is stored
    );
  ------------------------------------------------------------------------------------------------
  -- Signal Area
  ------------------------------------------------------------------------------------------------

  signal FE_STATE                 : von_neumann_fsm;
  -------
  signal sl_addsub1_vld_in        : std_logic;
  signal sv_addsub1_data_a_in     : std_logic_vector(8-1 downto 0);
  signal sv_addsub1_data_b_in     : std_logic_vector(8-1 downto 0);
  signal sl_addsub1_vld_out       : std_logic;
  signal sv_addsub1_data_out      : std_logic_vector(9-1 downto 0);
  ------
  signal sl_mult1_vld_in          : std_logic;
  signal sl_mult1_rdy_out         : std_logic;
  signal sv_mult1_data_a_in       : std_logic_vector(8-1 downto 0);
  signal sv_mult1_data_b_in       : std_logic_vector(8-1 downto 0);
  signal sl_mult1_vld_out         : std_logic;
  signal sv_mult1_data_out        : std_logic_vector(16-1 downto 0);
  --
  signal sv_dereference_A         : std_logic_vector(4-1 downto 0);
  signal sv_dereference_B         : std_logic_vector(4-1 downto 0);
  signal sv_data_a_in             : std_logic_vector(8-1 downto 0);
  signal sv_data_b_in             : std_logic_vector(8-1 downto 0);
  signal sv_prog_mem_addr         : std_logic_vector(5-1 downto 0);
  signal sv_instruction_in        : std_logic_vector(16-1 downto 0);
  signal sl_delay1                : std_logic;
  signal sl_delay2                : std_logic;
  signal sl_delay3                : std_logic;
  signal sl_addsublevel_in        : std_logic;
  signal sl_prog_done_out         : std_logic;
  --
  --signal sv_operand2              :  std_logic_vector(4-1 downto 0);
  --signal sv_operand1              :  std_logic_vector(4-1 downto 0);
  signal sv_destination_addr      :  std_logic_vector(4-1 downto 0);
  signal sv_opcode                :  std_logic_vector(4-1 downto 0);

begin
  ------------------------------------------------------------------------------------------------
  -- Wiring Area
  ------------------------------------------------------------------------------------------------

  data_out                  <= ram_data(12);
  prog_done_out             <= sl_prog_done_out;
  vld_out                   <= sl_mult1_vld_out or sl_addsub1_vld_out;

  fsm:
  process(clk_in, rst_in)
  begin
    if (rst_in = '1') then
      FE_STATE                  <= IDLE;   -- reset stuff
      sl_delay1                 <= '0';
      sl_delay2                 <= '0';
      sl_delay3                 <= '0';
      sv_dereference_A          <= (others => '0');
      sv_dereference_B          <= (others => '0');
      sv_data_a_in              <= (others => '0');
      sv_data_b_in              <= (others => '0');
      sv_addsub1_data_a_in      <= (others => '0');
      sv_addsub1_data_b_in      <= (others => '0');
      sv_mult1_data_a_in        <= (others => '0');
      sv_mult1_data_b_in        <= (others => '0');
      sv_prog_mem_addr          <= (others => '0');
      sv_instruction_in         <= (others => '0');
      sv_destination_addr       <= (others => '0');
      sv_opcode                 <= (others => '0');
      sl_addsublevel_in         <= '0';
      sl_mult1_vld_in           <= '0';
      sl_addsub1_vld_in         <= '0';
      sl_prog_done_out          <= '0';

    elsif (rising_edge(clk_in)) then
      case FE_STATE is
        when IDLE =>
          sl_delay1             <= '0';
          sl_delay2             <= '0';
          sl_delay3             <= '0';
          sv_dereference_A      <= (others => '0');
          sv_dereference_B      <= (others => '0');
          sv_data_a_in          <= (others => '0');
          sv_data_b_in          <= (others => '0');
          sv_addsub1_data_a_in  <= (others => '0');
          sv_addsub1_data_b_in  <= (others => '0');
          sv_mult1_data_a_in    <= (others => '0');
          sv_mult1_data_b_in    <= (others => '0');
          sv_prog_mem_addr      <= (others => '0');
          sv_instruction_in     <= (others => '0');
          sv_destination_addr   <= (others => '0');
          sl_addsublevel_in     <= '0';
          sl_mult1_vld_in       <= '0';
          sl_addsub1_vld_in     <= '0';
          sl_prog_done_out      <= '0';
          if (vld_in = '1') then
            FE_STATE            <= INSTRUCTION_FETCH;   -- reset stuff
          end if;

        when INSTRUCTION_FETCH =>
        -- fetch next instruction
          sv_instruction_in     <= ram_data(ti_u(sv_prog_mem_addr));
          FE_STATE              <= DATA_FETCH;

           if (ti_u(sv_prog_mem_addr) = 5) then
             ram_data(8)       <= write_ram_a_in;
             ram_data(9)       <= write_ram_b_in;
             sl_prog_done_out <= '1';
             FE_STATE <= IDLE;
          end if;

        when DATA_FETCH =>
          --
          sv_opcode             <= sv_instruction_in(15 downto 12);
          sv_destination_addr   <= sv_instruction_in(11 downto 8);
          sv_dereference_A      <= sv_instruction_in(7 downto 4);
          sv_dereference_B      <= sv_instruction_in(3 downto 0);
          --
          sv_data_a_in          <= ram_data(ti_u(sv_dereference_A))(8-1 downto 0);
          sv_data_b_in          <= ram_data(ti_u(sv_dereference_B))(8-1 downto 0);
          --
          sl_delay1             <= '1';
          sl_delay2             <= sl_delay1;
          sl_delay3             <= sl_delay2;
          if (sl_delay2 = '1') then
            sl_delay1           <= '0';
            sl_delay2           <= '0';
            sl_delay3           <= '0';
            FE_STATE            <= DECODE;
          end if;

        when DECODE =>
          case sv_opcode is
            when "0001" => -- addition
              sv_addsub1_data_a_in  <= sv_data_a_in;
              sv_addsub1_data_b_in  <= sv_data_b_in;
              sl_addsublevel_in     <= '1';
              sl_addsub1_vld_in     <= '1';
            when "0010" => -- subtraction
              sv_addsub1_data_a_in  <= sv_data_a_in;
              sv_addsub1_data_b_in  <= sv_data_b_in;
              sl_addsublevel_in     <= '0';
              sl_addsub1_vld_in     <= '1';
            when "0100" => -- multiplication
              sv_mult1_data_a_in    <= sv_data_a_in;
              sv_mult1_data_b_in    <= sv_data_b_in;
              sl_mult1_vld_in       <= '1';
            when others =>
              FE_STATE <= IDLE;
          end case;
          FE_STATE <= EXECUTE;

        when EXECUTE =>
          sl_addsub1_vld_in         <= '0';
          sl_mult1_vld_in           <= '0';
          if(vld_out = '1') then
            FE_STATE                <= STORE;
          end if;

        when STORE   =>
          case sv_opcode is
            when "0001" => -- addition
              ram_data(ti_u(sv_destination_addr)) <= "0000000" & sv_addsub1_data_out;
            when "0010" => -- subtraction
              ram_data(ti_u(sv_destination_addr)) <= "0000000" & sv_addsub1_data_out;
            when "0100" => --multiplication
              ram_data(ti_u(sv_destination_addr)) <= sv_mult1_data_out;
            when others =>
              FE_STATE              <= IDLE;
          end case;
          FE_STATE <= PC_INCR;

        when PC_INCR =>
          sv_prog_mem_addr          <= std_logic_vector(unsigned(sv_prog_mem_addr + '1'));
          FE_STATE                  <= INSTRUCTION_FETCH;

         if (ti_u(sv_prog_mem_addr) = 5) then
           ram_data(8)       <= write_ram_a_in;
           ram_data(9)       <= write_ram_b_in;
           sl_prog_done_out <= '1';
           FE_STATE <= IDLE;
         end if;
         FE_STATE <= INSTRUCTION_FETCH;

        when others =>
          FE_STATE <= IDLE;

      end case;
    end if;
  end process;

  ------------------------------------------------------------------------------------------------
  -- Instance Area
  ------------------------------------------------------------------------------------------------

  -- 1Q15 to 2Q15 --    v <= a + b
  addsub_sign_first : entity work.addsub_sign
  generic map (
    G_LATENCY           => gi_latency,
    G_WIDTH             => 8
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    add_sub_in          => sl_addsublevel_in, -- high selects add
    carry_in            => '0',
    carry_out           => open,
    vld_in              => sl_addsub1_vld_in,
    data_A_in           => sv_addsub1_data_a_in,
    data_B_in           => sv_addsub1_data_b_in,
    vld_out             => sl_addsub1_vld_out,
    data_out            => sv_addsub1_data_out
  );

  -- multiply 8Q0 x 2Q0 to 10Q0 --      w <= b * 2
  mult_sign_v1_first : entity work.mult_sign_v1
  generic map (
    G_LATENCY           => gi_latency,
    G_WIDTH_A           => 8,
    G_WIDTH_B           => 8
  )
  port map (
    clk_in              => clk_in,
    rst_in              => rst_in,
    vld_in              => sl_mult1_vld_in,
    rdy_out             => sl_mult1_rdy_out,
    data_A_in           => sv_mult1_data_a_in,
    data_B_in           => sv_mult1_data_b_in,
    vld_out             => sl_mult1_vld_out,
    data_out            => sv_mult1_data_out
  );

end architecture rtl;