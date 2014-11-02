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
#    mail_aliases       = { 'first' => { username => 'new_username', aliasname => 'myAlias'} },
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
  $ensure             = false,
  $packages           = [
  'exim4-base', 'exim4-config', 'exim4-daemon-light',
  'dovecot-imapd', 'dovecot-sqlite', 'dovecot-antispam',
  'squirrelmail', 'squirrelmail-locales', 'squirrelmail-decode',
# roundcube, # seems to have a much modern aspect, but for me it is more difficult to configure at the moment
  ],
  $fetchmailrc_lines  = [],
  $mail_aliases       = {}, # { 'first' => { username => 'new_username', aliasname => 'myAlias'} },
  $exim               = {
    'configtype'      => 'local', # or internet
    'other_hostnames' => [], # is   used   to  build  the  local_domains  list,  together  with
              # “localhost”.  This is the list of domains for which this machine
              # should  consider itself the final destination. The local_domains
              # list ends up in the macro MAIN_LOCAL_DOMAINS.
    'local_interfaces'=> '127.0.0.1 ; ::1', # or '0.0.0.0' to listen on all interfaces, 127.0.0.1 does not listen to external interfaces
    'relay_nets'      => '', #  a network mask, e.g 192.168.1.0/24
    'localdelivery'   => 'maildir_home', # or mail_spool for mailbox in /var/mail
  },
) {
	$servers        = hiera('server_names', [])
	if (member($servers, $hostname)) {
		notify{"hinmail needs $hinmail::ensure server $servers": }
	}
  if ($ensure != absent and $ensure != false) {
    # notify{"HINMAIL ensure $ensure with $packages": }
    require apt
    class {"apt::backports": pin_priority  => 500 }
#    package{['roundcube', 'roundcube-sqlite3', 'roundcube-plugins']: ensure => latest }
    ensure_packages($packages)
    $dovecot_mail_conf = '/etc/dovecot/conf.d/10-mail.conf'
    file{$dovecot_mail_conf:
      content => template("hinmail/dovecot_mail_conf.erb"),
      notify  => Exec['dpkg-reconfigure-exim4-config'],
      require => Package['dovecot-imapd'],
    }

    if (false) { # use apache
    require apache::params
    class { 'apache':
        default_mods        => false,
        default_confd_files => false,
        mpm_module => 'prefork',
    }
    class { 'apache::mod::php': }
    if (member($packages, 'squirrelmail') and defined(Class['apache'])) {
      file{'/etc/apache2/conf.d/squirrelmail.conf':
        ensure => link,
        target => '/etc/squirrelmail/apache.conf',
        require => Class['apache::mod::php'],
#        notify => Service[$::apache::params::service_name],
      }
    }
    } else {
      # use nginx
    }
    if (member($packages, 'exim4-config') ) {
      $conf_file = '/etc/exim4/update-exim4.conf.conf'
      exec{'dpkg-reconfigure-exim4-config':
        command => '/usr/sbin/dpkg-reconfigure exim4-config && /usr/bin/touch /var/cache/ran_update-exim4.conf.conf',
        subscribe => File[$dovecot_mail_conf, $conf_file],
        creates => '/var/cache/ran_update-exim4.conf.conf',
      }
      file{$conf_file:
        content => template("hinmail/update-exim4.conf.conf.erb"),
        notify => Exec['dpkg-reconfigure-exim4-config'],
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
  } else {
    notify{"Hinmail ensure $ensure with $packages absent": }
#    ensure_packages($packages, { ensure => absent } )
  }

#   https://tobrunet.ch/2013/01/iterate-over-datastructures-in-puppet-manifests/
  create_resources(addAlias, $mail_aliases, {})  # no default values

}

define addAlias($username, $aliasname) {
  file_line {"set_alias_${title}_${username}":
    path  => '/etc/aliases',
    line  => "${aliasname}: ${username}",
    match => "^${aliasname}:",
  }
}
