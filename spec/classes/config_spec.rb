require 'spec_helper'

describe 'marathon::config' do
  on_supported_os.each do |os, facts|
    context "on #{os}" do
      let(:facts) do
        facts
      end

      it { should compile }

      context 'secrets' do
        context 'w/o secret' do
          let(:params) { {
              :options => {}
          } }

          it 'stores secret in specified file' do
            should_not contain_file('/etc/marathon/.secret')
            should_not contain_mesos__property('marathon_mesos_authentication_principal')
            should_not contain_mesos__property('marathon_mesos_authentication_secret_file')
          end
        end

        context 'at default location' do
          let(:params) { {
              :mesos_auth_principal => 'marathon',
              :mesos_auth_secret => 'very-secret',
              :options => {}
          } }

          it 'stores secret in specified file' do
            should contain_file('/etc/marathon/.secret')
                       .with_content('very-secret')
            should contain_mesos__property('marathon_mesos_authentication_principal').with_value('marathon')
            should contain_mesos__property('marathon_mesos_authentication_secret_file').with_value('/etc/marathon/.secret')
          end
        end

        context 'at specific location from options' do
          let(:params) { {
              :mesos_auth_secret => 'very-secret',
              :options => {
                  'mesos_authentication_principal' => 'not-marathon',
                  'mesos_authentication_secret_file' => '/root/.secret',
              }
          } }

          it 'stores secret in specified file' do
            should contain_file('/root/.secret')
                       .with_content('very-secret')
            should contain_mesos__property('marathon_mesos_authentication_principal').with_value('not-marathon')
            should contain_mesos__property('marathon_mesos_authentication_secret_file').with_value('/root/.secret')
          end
        end

        context 'at specific location from params' do
          let(:params) { {
              :mesos_auth_principal => 'marathon',
              :mesos_auth_secret => 'very-secret',
              :mesos_auth_secret_file => '/root/.marathon_secret',
          } }

          it 'stores secret in specified file' do
            should contain_file('/root/.marathon_secret')
                       .with_content('very-secret')
            should contain_mesos__property('marathon_mesos_authentication_secret_file').with_value('/root/.marathon_secret')
          end
        end
      end
    end
  end
end
