#!/usr/bin/python

import cbus
nodes=cbus.cbus_read_nodes('ipbus_test.xml')
ctrl=nodes['CTRLREG']
stat=nodes['STATREG']
l1a=nodes['LFSR1A']
l1b=nodes['LFSR1B']
l2a=nodes['LFSR2A']
l2b=nodes['LFSR2B']
cbus.bus_delay(250)
print hex(ctrl.read())
print hex(stat.read())

