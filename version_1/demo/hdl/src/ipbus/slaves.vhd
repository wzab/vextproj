-- The ipbus slaves live in this entity - modify according to requirements
--
-- Ports can be added to give ipbus slaves access to the chip top level.
--
-- Dave Newbold, February 2011

library IEEE;
use IEEE.STD_LOGIC_1164.all;
use work.ipbus.all;

entity slaves is
  port(
    ipb_clk : in  std_logic;
    ipb_rst : in  std_logic;
    ipb_in  : in  ipb_wbus;
    ipb_out : out ipb_rbus;
    -- User logic connections
    -- You may use record types for more complex connections
    leds    : out std_logic_vector(2 downto 0)
    );

end slaves;

architecture rtl of slaves is

  constant NSLV             : positive := 3;
  signal ipbw               : ipb_wbus_array(NSLV-1 downto 0);
  signal ipbr, ipbr_d       : ipb_rbus_array(NSLV-1 downto 0);
  signal ctrl_reg           : std_logic_vector(31 downto 0);
  signal test_reg           : std_logic_vector(31 downto 0);
  signal inj_ctrl, inj_stat : std_logic_vector(63 downto 0);

begin

  fabric : entity work.ipbus_fabric
    generic map(NSLV => NSLV)
    port map(
      ipb_in          => ipb_in,
      ipb_out         => ipb_out,
      ipb_to_slaves   => ipbw,
      ipb_from_slaves => ipbr
      );

-- Slave 0: id / rst reg

  slave0 : entity work.ipbus_ctrlreg
    port map(
      clk       => ipb_clk,
      reset     => ipb_rst,
      ipbus_in  => ipbw(0),
      ipbus_out => ipbr(0),
      d         => X"abcdfedc",
      q         => ctrl_reg
      );

  leds <= ctrl_reg(2 downto 0);
-- Slave 1: register

  slave1 : entity work.ipbus_reg
    generic map(addr_width => 0)
    port map(
      clk       => ipb_clk,
      reset     => ipb_rst,
      ipbus_in  => ipbw(1),
      ipbus_out => ipbr(1),
      q         => test_reg
      );

-- Slave 2: 4kword RAM

  slave2 : entity work.ipbus_ram
    generic map(addr_width => 12)
    port map(
      clk       => ipb_clk,
      reset     => ipb_rst,
      ipbus_in  => ipbw(2),
      ipbus_out => ipbr(2)
      );

end rtl;
