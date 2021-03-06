# === Authors
#
# Niklaus Giger <niklaus.giger@member.fsf.org>
#
# === Copyright
#
# Copyright 2014 Niklaus Giger
#
# == Class: hinmail::exim_tls
#
# Add support for TLS (creating certifcate) and sasl TLS_and_Authentication
# To see the cleartext of the generate exim.pem call openssl x509 -in /etc/exim4/exim.pem  -text
# To test how the routing is done via exim use sudo exim -bt vagrant@localhost
#
# === Parameters
#
# Document parameters here.
# Based on https://wiki.debian.org/Exim#TLS_and_Authentication
#
# === Examples
#
#  class { hinmail::exim_tls:
#    ensure       => present,
#    country_code => 'CH',
#  }
#
#
class hinmail::exim_tls(
  $ensure             = false,
  $packages           = [ 'sasl2-bin', ],
  $country_code       = 'XX',
  $province           = '.', # '.' will give an empty string
  $locality           = 'unknown',
  $org_name           = '.', # '.' will give an empty string
  $org_unit           = '.', # '.' will give an empty string
  $email              = '.', # '.' will give an empty string
) {
  if ($ensure != absent and $ensure != false) {
    ensure_packages($packages)
    $info_file = '/etc/exim4/exim_cert.info' 
    file{$info_file: 
      content => "$country_code
$province
$locality
$org_name
$org_unit
$fqdn
$email
",
    }
    exec{'/etc/exim4/exim.crt':
      command => "/bin/cat ${info_file} | /usr/share/doc/exim4-base/examples/exim-gencert --force; adduser Debian-exim sasl",
      creates => '/etc/exim4/exim.crt',
      subscribe => File[$info_file],
      notify => Exec['/etc/exim4/exim.pem'],
    }
    # create a default certificate for the next 10 years
    exec{'/etc/exim4/exim.pem':      
      command => "/bin/cat ${info_file} | /usr/bin/openssl req -new -x509 -days 3650 -nodes -out /etc/exim4/exim.pem -keyout /etc/exim4/exim.key",
      creates => '/etc/exim4/exim.pem',
      subscribe => File[$info_file],
      notify  => Exec['update_exim4'],
    }
    file{'/etc/exim4/exim4.conf.localmacros':
      content => 'MAIN_TLS_ENABLE = yes
',
      notify => Exec['update_exim4'],
    }
    exec{'update_exim4':
      command => '/usr/sbin/update-exim4.conf && /etc/init.d/exim4 restart && /usr/bin/touch /var/cache/ran_update_exim4',
      creates => '/var/cache/ran_update_exim4',
      subscribe  => [ File['/etc/exim4/exim4.conf.localmacros'], Exec['/etc/exim4/exim.pem'] ],
    }
    file{'/etc/exim4/conf.d/auth/30_exim4-config_puppet':
      content => '
plain_saslauthd_server:
  driver = plaintext
  public_name = PLAIN
  server_condition = ${if saslauthd{{$auth2}{$auth3}}{1}{0}}
  server_set_id = $auth2
  server_prompts = :
  .ifndef AUTH_SERVER_ALLOW_NOTLS_PASSWORDS
    server_advertise_condition = ${if eq{$tls_cipher}{}{}{*}}
  .endif
',
        notify => Exec['update_exim4'],
    }
  }  
}

