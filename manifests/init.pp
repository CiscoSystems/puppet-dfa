#
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
###########################################
class dfa($uplink_intf='UNSET',
            $dcnm_ip_addr='UNSET',
            $dcnm_username='UNSET',
            $dcnm_password='UNSET',
            $mysql_host='UNSET',
            $mysql_user='UNSET',
            $mysql_password='UNSET',
            $compute='UNSET',
            $gateway_mac='UNSET',
            $dfa_tunnel_base='UNSET',
            $non_nearest_bridge='UNSET',
            $non_nearest_bridge_mac='UNSET') {
    file {'/etc/vinci.ini':
      ensure => file,
      content => template('dfa/dfa.conf.erb'),
    }
    file {'/opt/dfa/':
      ensure  => directory,
      mode    => 644,
      require => File['/etc/vinci.ini'],
    } 
    file {['/opt/dfa/files/','/opt/dfa/logs/']:
      ensure   => directory,
      mode     => 644,
      require => File['/etc/vinci.ini'],
    } 
    if $compute == 'false' {
      file {'/usr/sbin/dfa_control_scr':
        ensure   => present,
        mode     => 755,
        source   => 'puppet:///modules/dfa/dfa_control_scr',
      }
      exec {'/usr/sbin/dfa_control_scr':
        path      => ['/usr/sbin/', '/usr/bin/', '/bin/', '/sbin/'],
        logoutput => true,
        require   => [File['/etc/vinci.ini'],
                      Service['mysql',
                              'apache2',
                              'keystone',
                              'quantum-server',
                              'nova-api', 
                              'nova-scheduler']],
      }
    }
    if $compute == 'true' {
      file {'/opt/dfa/files/client_sample':
        ensure   => present,
        mode     => 4755,
        owner    => root,
        require  => File['/opt/dfa/files'],
        source   => 'puppet:///modules/dfa/client_sample',
      }  
      file {'/opt/dfa/files/lookup.py':
        ensure   => present,
        mode     => 755,
        require  => File['/opt/dfa/files'],
        source   => 'puppet:///modules/dfa/lookup.py',
      }
      file {'/opt/dfa/files/program_flows':
        ensure   => present,
        mode     => 755,
        require  => File['/opt/dfa/files',  '/opt/dfa/files/lookup.py'],
        source   => 'puppet:///modules/dfa/program_flows',
      }
      file {'/opt/dfa/files/delete_flows':
        ensure   => present,
        mode     => 755,
        require  => File['/opt/dfa/files',  '/opt/dfa/files/lookup.py'],
        source   => 'puppet:///modules/dfa/delete_flows',
      }
      package {['libconfig8', 'libnl-dev', 'gawk', 'libpcap0.8', 
                'libmysqlclient-dev']:
        ensure => installed,
      }
      file {'/opt/dfa/files/gold_temp_short.conf':
        ensure   => present,
        mode     => 755,
        require  => File['/opt/dfa/files'],
        source   => 'puppet:///modules/dfa/gold_temp_short.conf',
      }
      file {'/etc/init.d/lldpad':
        ensure   => present,
        mode     => 755,
        source   => 'puppet:///modules/dfa/lldpad.init',
        require  => File['/opt/dfa/files/gold_temp_short.conf'],
      }
      file {'/usr/sbin/lldpad':
        ensure   => present,
        mode     => 755,
        source   => 'puppet:///modules/dfa/lldpad',
      }
      file {'/etc/init.d/pktcpt':
        ensure   => present,
        mode     => 755,
        source   => 'puppet:///modules/dfa/pktcpt.init',
      }
      file {'/usr/sbin/pktcpt':
        ensure   => present,
        mode     => 755,
        source   => 'puppet:///modules/dfa/pktcpt',
      }
      file {'/usr/sbin/create_dfa_ovs_br':
        ensure   => present,
        mode     => 755,
        source   => 'puppet:///modules/dfa/create_dfa_ovs_br',
      }
      file {'/usr/sbin/dfa_compute_scr':
        ensure   => present,
        mode     => 755,
        source   => 'puppet:///modules/dfa/dfa_compute_scr',
      }
      exec {'/usr/sbin/dfa_compute_scr':
        path      => ['/usr/sbin/', '/usr/bin/', '/bin/', '/sbin/'],
        logoutput => true,
        require   => File['/etc/vinci.ini'],
      }
      exec {'/usr/sbin/create_dfa_ovs_br':
        path      => ['/usr/sbin/', '/usr/bin/', '/bin/', '/sbin/'],
        logoutput => true,
        require   => [File['/etc/vinci.ini'],
                      Service['openvswitch-switch', 
                              'quantum-plugin-openvswitch-agent']],
      }
      ->
      service {'lldpad':
        ensure    => running,
        enable    => false,
        subscribe => File['/etc/vinci.ini'],
        require   => [
                      Service['openvswitch-switch',
                              'quantum-plugin-openvswitch-agent'],
                      Package['libconfig8','libnl-dev'],
                      File['/opt/dfa/files/program_flows', 
                           '/opt/dfa/files/delete_flows',
                           '/usr/sbin/lldpad',
                           '/etc/init.d/lldpad',
                           '/opt/dfa/files/gold_temp_short.conf']],
      }
      ->
      service {'pktcpt':
        ensure    => running,
        enable    => true,
        subscribe => File['/etc/vinci.ini'],
        require   => [
                      Package['libmysqlclient-dev','libpcap0.8'],
                      Service['openvswitch-switch', 
                              'quantum-plugin-openvswitch-agent'],
                      File['/opt/dfa/files/client_sample', 
                           '/usr/sbin/pktcpt']],
      }
  }
}
