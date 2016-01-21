# == Class: marathon::config
#
class marathon::config(
  $conf_dir_base                    = '/etc/marathon',
  $conf_dir_name                    = 'conf',
  $owner                            = 'root',
  $group                            = 'root',
  $master                           = undef,
  $zookeeper                        = undef,
  $options                          = {},
  $env_var                          = {},
  $manage_logger                    = true,
  $logger                           = 'logback',
  $log_dir                          = '/var/log/marathon',
  $log_filename                     = 'marathon.log',
  $log_level                        = 'info',
  $ulimit                           = undef,
  $mesos_auth_principal             = undef,
  $mesos_auth_secret                = undef,
  $mesos_auth_secret_file           = '/etc/marathon/.secret',
  $java_home                        = undef,
  $java_opts                        = '-Xmx512m',
) {
  $conf_dir = "${conf_dir_base}/${conf_dir_name}"
  file { [$conf_dir_base, $conf_dir]:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  if ($mesos_auth_principal != undef and $mesos_auth_secret != undef) {
    $secret_options = {
      'mesos_authentication_principal'   => $mesos_auth_principal,
      'mesos_authentication_secret_file' => $mesos_auth_secret_file,
    }
    $configure_secrets = true
  } elsif ($options['mesos_authentication_principal'] != undef and $mesos_auth_secret != undef) {
    $secret_options = {
      'mesos_authentication_secret_file' => $mesos_auth_secret_file,
    }
    $configure_secrets = true
  } else {
    $secret_options = {}
    $configure_secrets = false
  }
  $real_options = merge($secret_options, $options)

  if $master {
    mesos::property { 'marathon_master':
      value   => $master,
      dir     => $conf_dir,
      file    => 'master',
      service => undef,
    }
  }

  if $zookeeper {
    mesos::property { 'marathon_zk':
      value   => $zookeeper,
      dir     => $conf_dir,
      file    => 'zk',
      service => undef,
    }
  }

  create_resources(mesos::property,
    mesos_hash_parser($real_options, 'marathon'),
    {
      dir     => $conf_dir,
      service => undef,
    }
  )

  if $manage_logger {
    file { $log_dir:
      ensure => directory,
      owner  => $owner,
      group  => $group,
    }

    case $logger {
      'logback': {
        $log_config_file = "${conf_dir_base}/logback.xml"
        $log_file = "${log_dir}/${log_filename}"
        $log_archive_pattern = "${log_dir}/${log_filename}.%i.gz"
        file { $log_config_file:
          content => template('marathon/logback.xml.erb'),
          owner   => $owner,
          group   => $group,
          require => File[$conf_dir_base],
        }

        $java_extra_opts = "-Dlogback.configurationFile=file:${log_config_file}"
      }
      default: {
        fail("Logger \"${logger}\" is not currently supported. Only logback is supported at this time.")
      }
    }
  }

  file { '/etc/default/marathon':
    ensure  => 'present',
    content => template('marathon/default.erb'),
    owner   => $owner,
    group   => $group,
    mode    => '0644',
  }

  if ($configure_secrets) {
    $real_mesos_auth_secret_file =  $real_options['mesos_authentication_secret_file']
    validate_absolute_path($real_mesos_auth_secret_file)

    file { $real_mesos_auth_secret_file:
      ensure  => file,
      content => $mesos_auth_secret,
      owner   => $owner,
      group   => $group,
      mode    => '0400',
    }
  }
}
