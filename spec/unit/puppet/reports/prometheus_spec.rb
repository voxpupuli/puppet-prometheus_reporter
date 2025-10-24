# rubocop:disable Style/FrozenStringLiteralComment

require 'spec_helper'

describe 'Puppet::Reports::Prometheus' do
  before do
    # Mock Puppet settings and file exist check
    allow(Puppet.settings).to receive(:[]).with(:config).and_return('/dev/null') # Dummy path
    allow(Puppet.settings).to receive(:[]).with(:node_name_value).and_return('test_host')
    allow(Puppet.settings).to receive(:[]).with(:noop).and_return(false)
    allow(File).to receive(:exist?).with(any_args).and_return(true)

    # Mock YAML loading to return a dummy configuration
    allow(YAML).to receive(:load_file).and_return(
      {
        'textfile_directory' => '/tmp',
        'report_file_prefix' => 'puppet_report_',
        'report_file_mode' => 0o644,
        'environments' => nil,
        'reports' => nil,
        'stale_time' => 1,
        'include_config_version' => true
      }
    )

    # Now require the report file AFTER mocking
    require 'puppet/reports/prometheus'
  end

  let(:report) do
    Puppet::Transaction::Report.new('apply').extend(Puppet::Reports.report(:prometheus))
  end

  it 'registers the prometheus report processor' do
    expect(Puppet::Reports.report(:prometheus)).not_to be_nil
  end

  it 'creates the prometheus report file with correct content' do
    allow(report).to receive(:node_name_value).and_return('test_host')
    allow(report).to receive(:environment).and_return('production')
    allow(report).to receive(:metrics).and_return({})
    allow(report).to receive(:status).and_return('changed')
    allow(report).to receive(:transaction_completed).and_return(true)
    allow(report).to receive(:cached_catalog_status).and_return('not_used')
    allow(report).to receive(:configuration_version).and_return('release/puppet8@main v2.1.0')

    file_content = ''
    file_double = instance_double(File)
    allow(File).to receive(:open).with('/tmp/puppet_report_test_host.prom', 'w').and_yield(file_double)
    allow(file_double).to receive(:write) { |content| file_content << content }
    allow(File).to receive(:chmod).with(0o644, '/tmp/puppet_report_test_host.prom')

    report.process

    expect(file_content).to include(%(puppet_report{environment="production",host="test_host"}))
    expect(file_content).to include(%(puppet_status{state="unchanged",environment="production",host="test_host"} 0))
    expect(file_content).to include('# HELP puppet_configuration_version Puppet catalog configuration version')
    expect(file_content).to include('# TYPE puppet_configuration_version gauge')
    expect(file_content).to include(%(puppet_configuration_version{version="release/puppet8_main_v2.1.0",environment="production",host="test_host"} 1))
  end
end
# rubocop:enable Style/FrozenStringLiteralComment
