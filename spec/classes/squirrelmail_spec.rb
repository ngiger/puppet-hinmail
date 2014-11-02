require 'spec_helper'

describe 'hinmail::squirrelmail' do
  let(:facts) { { :fqdn => 'tst'} }
  context 'when running alone' do
    it { should compile }
    it { should compile.with_all_deps }
    it { should contain_file('/etc/nginx/sites-enabled/squirrelmail.conf').with_ensure('absent')}
    it { should contain_file('/etc/nginx/sites-available/squirrelmail.conf').with_ensure('absent')}
    it { should contain_file('/etc/nginx/sites-enabled/tst.vhost').with_ensure('absent')}
    it { should contain_file('/etc/nginx/sites-available/tst.vhost').with_ensure('absent')}
  end

  context 'when running with ensure' do
    let(:params) { { :ensure => true,}}
    it { should compile }
    it { should compile.with_all_deps }
    it { should contain_hinmail__squirrelmail }
    it { should contain_file('/etc/nginx/sites-enabled/squirrelmail.conf')}
    it { should contain_file('/etc/nginx/sites-enabled/squirrelmail.conf').with_ensure('link')}
    it { should contain_file('/etc/nginx/sites-available/squirrelmail.conf').with_content(/managed by puppet elexis-hinmail/)}
    it { should contain_file("/etc/nginx/sites-enabled/tst.vhost").with_ensure('link')}
    it { should contain_file("/etc/nginx/sites-available/tst.vhost").with_content(/managed by puppet elexis-hinmail/) }
    it { should contain_file("/etc/squirrelmail/config.php") }
    it { should contain_package('nginx')}
    it { should contain_service('nginx')}
  end

end
