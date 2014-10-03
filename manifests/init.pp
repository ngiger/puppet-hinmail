# == Class: hinmail
#
# A puppet module for receiving and send mail (also via HIN.ch) for the elexis-admin project
# See https://github.com/ngiger/elexis-admin/wiki
#
# === Parameters
#
# Document parameters here.
#
# [*fetchmailrc_lines*]
#   If not empty, fetchmail is installed and /etc/fetchmailrc is filled with its values
#   Allows you to fetch mail from an external mail server
# [*aliases*]
#   aliases to be added to /etc/aliases. Existing entries not mentioned here will not be touched.
#
# === Variables
#
#
#
# === Examples
#
#  class { hinmail:
#    fetchmailrc_lines => [ 'poll mail.example.com with proto POP3',  "user 'john@example.com' there with password 'topsecrect' is johnny here" ],
#    aliases           => { 'postmaster' => 'root', 'root' => 'niklaus' }
#  }
#
# === Authors
#
# Niklaus Giger <niklaus.giger@member.fsf.org>
#
# === Copyright
#
# Copyright 2014 Niklaus Giger
#
notify{"hinmail ensure $hinmail::ensure server $servers": }
class hinmail(
  $ensure      = absent,
  $packages    = ['exim4-daemon-light', 'exim4-config', 'courier-imap', 'squirrelmail', 'squirrelmail-locales'],
  $fetchmailrc_lines = [],
  $mail_aliases      = { 'admin' => 'gyong' }
) {
	$servers        = hiera('server_names', [])
	if (member($servers, $hostname)) {
		notify{"hinmail needs $hinmail::ensure server $servers": }
	}

  if ($ensure != absent) {
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
#        notify => Service[$::apache::params::service_name],
      }
    }
    if (member($packages, 'exim4-config') ) {
      $conf_file = '/etc/exim4/update-exim4.conf.conf'
      file{$conf_file:
        content => template("hinmail/update-exim4.conf.conf.erb"),
      }   
    }

    if ($fetchmailrc_lines != [] ) {
      ensure_packages('fetchmail')
      service{'fetchmail': } # ensure => running, provider => debian, }
      file{'/etc/default/fetchmail':
        ensure => present,
        content => "#Managed by puppet hinmail
START_DAEMON=yes
",
        require => Package['fetchmail'],
      }

      $lines = join($fetchmailrc_lines, "\n")
      file{'/etc/fetchmailrc':
        ensure => present,
        content => "#Managed by puppet hinmail
$lines
",
        require => Package['fetchmail'],
        notify => Service['fetchmail'],
      }
    }    
    add_aliases{$mail_aliases:}
    # ensure_resource('service', "$::apache::params::service_name", { ensure => running } )
  } else {
    ensure_packages($packages, { ensure => absent } )
  }

  
  define add_alias($username) {
    notify{"add_alias $username": }
    file_line {"set_alias_${title}_${username}":
      path  => '/etc/aliases',
      line  => "${title}: $username",
#      match => '^${title}:',
    }
  }
  define add_aliases() {
    add_alias{"add_alias-$title": username => $title}
  }
}

