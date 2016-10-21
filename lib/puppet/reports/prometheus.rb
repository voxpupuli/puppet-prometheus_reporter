require 'puppet'
require 'puppet/util'
require 'yaml'
require 'fileutils'

# Required for strftime(%Q)
require 'date'

Puppet::Reports.register_report(:prometheus) do
  # Source: evenup/evenup-graphite_reporter code base
  # lib/puppet/reports/graphite.rb
  configfile = File.join([File.dirname(Puppet.settings[:config]),
                          'prometheus.yaml'])
  unless File.exist?(configfile)
    raise(Puppet::ParseError, "Prometheus report config file #{configfile} not readable")
  end

  config = YAML.load_file(configfile)

  TEXTFILE_DIRECTORY = config['textfile_directory']
  REPORT_FILENAME = config['report_filename']

  if TEXTFILE_DIRECTORY.nil?
    raise(Puppet::ParseError, "#{configfile}: textfile_directory is not set.")
  end

  unless REPORT_FILENAME.nil? or REPORT_FILENAME.end_with? '.prom'
    raise(Puppet::ParseError, "#{configfile}: report_filename does not ends with .prom")
  end

  def process
    now = DateTime.now.new_offset(0)

    if REPORT_FILENAME.nil?
      name = host + '.prom'
      file = File.join(TEXTFILE_DIRECTORY, name)
    else
      file = File.join(TEXTFILE_DIRECTORY, REPORT_FILENAME)
    end

    common_values = {
      transaction_uuid: self.transaction_uuid,
      host: self.host,
    }.reduce('') {
        |values, extra| values + ",#{extra[0].to_s}=\"#{extra[1].to_s}\""
    }

    epochtime = now.strftime('%Q')
    File.open(file, 'w') do |file|
      unless metrics.empty? or metrics['events'].nil?
        metrics.each do |metric, data|
          data.values.each do |val|
            file.write("puppet_report_#{metric}{name=\"#{val[1]}\"#{common_values}} #{val[2]}\n")
          end
        end
      end

      file.write("puppet_report{host=\"#{host}\",kind=\"#{kind}\",version=\"#{configuration_version}\"#{common_values}} #{epochtime}\n")
    end
  end
end
