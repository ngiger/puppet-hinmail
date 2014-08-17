# == Class: hinmail
#
# Full description of class hinmail here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { hinmail:
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2014 Your name here, unless otherwise noted.
#
class hinmail(
  $ensure      = "present",
  $packages    = ['fetchmail', 'exim4-daemon-light', 'exim4-config', 'courier-imap', 'squirrelmail', 'squirrelmail-locales'],
  $fetchmailrc_lines = [ "# Some dummy content, which should be replaced by hieradata" ],
) {
  if ($ensure == "present") {
    ensure_packages($packages)
    class { 'apache':  
       mpm_module => 'prefork',
    }
    $exim = hiera('exim', {})
    class { 'apache::mod::php': }
    if (member($packages, 'squirrelmail') and defined(Class['apache'])) {
      file{'/etc/apache2/conf.d/squirrelmail.conf':
        ensure => link,
        target => '/etc/squirrelmail/apache.conf',
        require => Class['apache::mod::php'],
        notify => Service[$::apache::params::service_name],
      }
    }
    if (member($packages, 'exim4-config') ) {
      $conf_file = '/etc/exim4/update-exim4.conf.conf'
      file{$conf_file:
        content => template("hinmail/update-exim4.conf.conf.erb"),
      }   
    }

    if (member($packages, 'fetchmail') ) {
      service{'fetchmail': } # ensure => running, provider => debian, }
      file{'/etc/default/fetchmail':
        ensure => present,
        content => "#Managed by puppet hinmail
START_DAEMON=yes
",
        require => Package['fetchmail'],
      }

      $lines = join($hinmail::fetchmailrc_lines, "\n")
      file{'/etc/fetchmailrc':
        ensure => present,
        content => "#Managed by puppet hinmail
$lines
",
        require => Package['fetchmail'],
        notify => Service['fetchmail'],
      }
   }    
  } else {
    ensure_packages($packages, { ensure => absent } )
  }
}

  