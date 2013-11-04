class dfa($uplink_intf='UNSET',
            $dcnm_ip_addr='UNSET',
            $dcnm_username='UNSET',
            $dcnm_password='UNSET',
            $mysql_host='UNSET',
            $mysql_user='UNSET',
            $mysql_password='UNSET',
            $compute='UNSET',
            $gateway_mac='UNSET') {
    file {'/etc/vinci.ini':
      ensure => file,
      content => template('/etc/puppet/modules/dfa/templates/dfa.conf.erb'),
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
      exec {'/usr/sbin/create_dfa_ovs_br':
        path      => ['/usr/sbin/', '/usr/bin/', '/bin/', '/sbin/'],
        logoutput => true,
        require   => [File['/etc/vinci.ini'],Service['openvswitch-switch']],
      }
      ->
      service {'lldpad':
        ensure    => running,
        enable    => true,
        subscribe => File['/etc/vinci.ini'],
        require   => [
                      Service['openvswitch-switch'],
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
#                      Package['libmysqlclient-dev','libpcap0.8'],
                      Service['openvswitch-switch'],
                      Package['libpcap0.8'],
                      File['/opt/dfa/files/client_sample', 
                           '/usr/sbin/pktcpt']],
      }
  }
}
