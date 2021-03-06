require 'spec_helper'

describe 'hinmail' do
  let(:facts) { WheezyFacts }
  context 'when running alone' do
    it { should compile }
    it { should compile.with_all_deps }
#    it { should have_resource_count(9) }
    it { should contain_hinmail }
    if false
    it { should contain_package('dovecot-imapd').with_ensure('absent')}
    it { should contain_package('dovecot-sqlite').with_ensure('absent')}
    it { should contain_package('exim4-config').with_ensure('absent')}
    it { should contain_package('exim4-daemon-light').with_ensure('absent')}
    it { should contain_package('squirrelmail-locales').with_ensure('absent')}
    it { should contain_package('squirrelmail').with_ensure('absent')}
    end
    it { should_not contain_package('fetchmail')}
    it { should_not contain_file('/etc/fetchmailrc')}
  end

  context 'when running with ensure' do
    let(:params) { { :ensure => true,}}
    it { should compile }
    it { should compile.with_all_deps }
    it { should create_class('hinmail')}
    it { should contain_package('dovecot-imapd')}
    it { should contain_package('dovecot-sqlite').with_ensure('present')}
    it { should contain_package('exim4-config')}
    it { should contain_package('exim4-daemon-light')}
    it { should contain_package('squirrelmail-locales')}
    it { should contain_package('squirrelmail')}
    it { should_not contain_package('fetchmail')}
    it { should_not contain_file('/etc/fetchmailrc')}
    it { should contain_file('/etc/dovecot/conf.d/10-mail.conf').with_content(/^mail_location = maildir:/)}
  end

  context 'when running with mail_aliases' do
    let(:params) { { :ensure => true, :mail_aliases =>  { 'abuse' => { 'username' => 'admin'}, 'backup' => { 'username' => 'admin'} } } }
    it { should compile }
    it { should compile.with_all_deps }
    it { should contain_addalias('abuse')}
    it { should contain_addalias('backup')}
    it { should contain_file_line('set_alias_abuse_admin') }
    it { should contain_file_line('set_alias_backup_admin') }
  end

  context 'when running with exim' do
    let(:params) { { :ensure => true,
                     :exim => {
                               'configtype'       => 'internet',
                               'other_hostnames'  => ['mustermann.org', 'tst.org'],
                               'local_interfaces' => '0.0.0.0',
                               'relay_nets'       => '192.168.1.0/24',
                              }
                   }}
    it { should compile }
    it { should compile.with_all_deps }
    it { should contain_file('/etc/exim4/update-exim4.conf.conf'). with_content(/dc_eximconfig_configtype='internet'/)}
    it { should contain_file('/etc/exim4/update-exim4.conf.conf'). with_content(/dc_other_hostnames='mustermann.org;tst.org'/)}
    it { should contain_file('/etc/exim4/update-exim4.conf.conf'). with_content(/local_interfaces='0.0.0.0'/)}
    it { should contain_file('/etc/exim4/update-exim4.conf.conf'). with_content(/dc_relay_nets='192.168.1.0\/24'/)}
  end

end
