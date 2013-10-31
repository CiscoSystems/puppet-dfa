#!/usr/bin/python
import sys
import re
import commands

bridge_name = sys.argv[1]
port_name = sys.argv[2]
mac_address = sys.argv[3]

internal_port = -5
vlan = -5

try:
    internal_port = re.search(r'(?P<num>\d+)\(%s\)' % port_name, commands.getoutput('sudo ovs-ofctl show %s' % bridge_name)).group('num')

    taps = re.findall(r'tap([\da-f\-]+)', commands.getoutput('brctl show'))
    for tap in taps:
        mac = re.search(r'HWaddr (?P<mac>[\da-f\:]+)', commands.getoutput('ifconfig tap%s' % tap)).group('mac')
        if mac[2:] == mac_address[2:]:
            vlan = re.search(r'Port "qvo%s"\s+tag\: (?P<tag>\d+)' % tap, commands.getoutput('sudo ovs-vsctl show')).group('tag')

    print internal_port
    print vlan
except Exception:
    print '-1\n-1'

