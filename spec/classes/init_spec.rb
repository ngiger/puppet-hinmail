require 'spec_helper'

describe 'hinmail' do
  let(:facts) { WheezyFacts }
  context 'when running alone' do
    it { should compile }
    it { should compile.with_all_deps }
    it { should have_resource_count(5) }
    it { should contain_hinmail }
    it { should contain_package('courier-imap').with_ensure('absent')}
    it { should contain_package('exim4-config').with_ensure('absent')}
    it { should contain_package('exim4-daemon-light').with_ensure('absent')}
    it { should contain_package('squirrelmail-locales').with_ensure('absent')}
    it { should contain_package('squirrelmail').with_ensure('absent')}
    it { should_not contain_package('fetchmail')}
    it { should_not contain_file('/etc/fetchmailrc')}    
  end

  context 'when running with ensure' do
    let(:params) { { :ensure => true,}}
    it { should compile }
    it { should compile.with_all_deps }
    it { should create_class('hinmail')}
    it { should contain_package('courier-imap')}
    it { should contain_package('exim4-config')}
    it { should contain_package('exim4-daemon-light')}
    it { should contain_package('squirrelmail-locales')}
    it { should contain_package('squirrelmail')} 
    it { should_not contain_package('fetchmail')}
    it { should_not contain_file('/etc/fetchmailrc')}    
  end
end
