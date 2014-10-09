require 'spec_helper'

describe 'hinmail' do
  let(:facts) { WheezyFacts }
  context 'when running with ensure and fetchmail' do
    let(:params) { { :ensure => true, :fetchmailrc_lines => ['first_line', 'second_line'] }}

    it { should compile }
    it { should compile.with_all_deps }
    it { should create_class('hinmail')}
    it { should contain_package('dovecot-imapd')}
    it { should contain_package('exim4-config')}
    it { should contain_package('exim4-daemon-light')}
    it { should contain_package('squirrelmail-locales')}
    it { should contain_package('squirrelmail')}
    it { should contain_package('fetchmail')}
    it { should contain_file('/etc/fetchmailrc')}
    it { should contain_file('/etc/fetchmailrc').without_content(/Some dummy content, which should be replaced by hieradata/)}
    it { should contain_file('/etc/fetchmailrc').with_content(/first_line\nsecond_line/)}
    it { should_not contain_file_line }
  end

  context 'when running with ensure and mail_aliases' do
    let(:params) { { :ensure => true, :mail_aliases => {'admin' => 'gyong'} }}
    it { should compile }
    it { should compile.with_all_deps }
    it { should create_class('hinmail')}
    it { should contain_package('dovecot-imapd')}
    it { should contain_package('exim4-config')}
    it { should contain_package('exim4-daemon-light')}
    it { should contain_package('squirrelmail-locales')}
    it { should contain_package('squirrelmail')}
    it { should_not contain_package('fetchmail')}
    it { should contain_hinmail__add_alias('add_alias-{"admin"=>"gyong"}')}
    it { should contain_file_line('set_alias_add_alias-{"admin"=>"gyong"}_{"admin"=>"gyong"}') }    
  end
end
