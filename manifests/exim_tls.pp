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
  $country_code       = 'CH',
  $province           = '',
  $locality           = 'Mollis',
  $org_name           = '',
  $org_unit           = '',
  $email              = '',
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
"
    }
    exec{'/etc/exim4/exim.crt':
      command => "/bin/cat ${info_file} | /usr/share/doc/exim4-base/examples/exim-gencert --force; adduser Debian-exim sasl",
      creates => '/etc/exim4/exim.crt',
      require => File[$info_file],
    }
    # create a default certificate for the next 10 years
    exec{'/etc/exim4/exim.pem':      
      command => "/bin/cat ${info_file} | /usr/bin/openssl req -new -x509 -days 3650 -nodes -out /etc/exim4/exim.pem -keyout /etc/exim4/exim.key",
      creates => '/etc/exim4/exim.pem',
      require => File[$info_file],
    }
    file{'/etc/exim4/exim4.conf.localmacros':
      content => 'MAIN_TLS_ENABLE = yes
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
#        notify => Exec['dpkg-reconfigure-exim4-config'],
    }
  }  
}

