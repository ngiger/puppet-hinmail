require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'

fixture_path = File.expand_path(File.join(__FILE__, '..', 'fixtures'))
WheezyFacts = { :osfamily => 'Debian', 
                :operatingsystem => 'Debian',
                :operatingsystemrelease => 'wheezy',
                :lsbdistcodename => 'wheezy',
                :lsbdistid => 'debian',
                 # for concat/manifests/init.pp:193
                :id => 'id',
                :concat_basedir => '/opt/concat',
                :path => '/path',
                }

RSpec.configure do |c|
  c.module_path = File.join(fixture_path, 'modules')
  c.manifest_dir = File.join(fixture_path, 'manifests')
end
at_exit { RSpec::Puppet::Coverage.report! }