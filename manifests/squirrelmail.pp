# Install nginx for webmail access	 to an squirrelmail
# we should probably better use https://forge.puppetlabs.com/jfryman/nginx
#
# === Examples:
#
#   class { 'hinmail::squirrelmail':
#     domain_name => 'example.com,
#   }
#

class hinmail::squirrelmail(
  $domain_name = $fqdn, # will take the default domain_name
  $local_url   = 'webmail',
  $ensure      = false,
)  {
  include hinmail
  # should probably use
  if ($ensure != absent and $ensure != false) {
      service{"nginx":
        ensure => running,
        require => Package['nginx'],
      }

    ensure_packages(['nginx', 'squirrelmail'], { ensure => present })
    file {"/etc/nginx/sites-available/${domain_name}.vhost":
      ensure  => present,
      mode    => '0644',
      content => template('hinmail/squirrelmail_nginx.erb'),
      require => Package['nginx'],
    }
    file {"/etc/nginx/sites-enabled/${domain_name}.vhost":
      ensure  => link,
      mode    => '0644',
      target => "/etc/nginx/sites-available/${domain_name}.vhost",
      require => Package['nginx'],
      notify  => Service["nginx"],
    }
    file {'/etc/nginx/sites-available/squirrelmail.conf':
      content => template('hinmail/squirrel_mail_conf.erb'),
      notify  => Service["nginx"],
    }    
    file {"/etc/nginx/sites-enabled/squirrelmail.conf":
      ensure  => link,
      mode    => '0644',
      target => "/etc/nginx/sites-available/squirrelmail.conf",
      require => Package['nginx'],
      notify  => Service["nginx"],
    }
    file {'/etc/squirrelmail/config.php':
      content => template('hinmail/config.php.erb'),
      require => Package['squirrelmail'],
      notify  => Service["nginx"],
    }
  } else {
    file { [ "/etc/nginx/sites-available/squirrelmail.conf",
      "/etc/nginx/sites-enabled/squirrelmail.conf",
      "/etc/nginx/sites-available/${domain_name}.vhost",
      "/etc/nginx/sites-enabled/${domain_name}.vhost",  
      ]:
      ensure  => absent,
    }
  }
}
