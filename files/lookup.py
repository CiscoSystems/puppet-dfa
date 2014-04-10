#!/usr/bin/python

#################################################
# Copyright 2013 United States Government as represented by the
# Administrator of the National Aeronautics and Space Administration.
# All Rights Reserved.
#
# Copyright 2013 Cisco Systems, Inc.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
###################################################

import sys
import re
import commands

bridge_name = sys.argv[1]
port_name = sys.argv[2]
mac_address = sys.argv[3]
port_id = sys.argv[4]

internal_port = -5
vlan = -5

try:
    internal_port = re.search(r'(?P<num>\d+)\(%s\)' % port_name, commands.getoutput('sudo ovs-ofctl show %s' % bridge_name)).group('num')

    cmd = 'sudo ovs-vsctl -- --columns=name find Interface external_ids:iface-id=%s' % (port_id)
    cout = commands.getoutput(cmd)
    port_name = cout.split(':')[1].replace('"', '').strip()
    vlan = re.search(r'Port "%s"\s+tag\: (?P<tag>\d+)' % port_name, commands.getoutput('sudo ovs-vsctl show')).group('tag')
    print internal_port
    print vlan
except Exception:
    print '-1\n-1'

