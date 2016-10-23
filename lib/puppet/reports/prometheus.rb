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
    if REPORT_FILENAME.nil?
      namevar = self.host
    else
      namevar = REPORT_FILENAME
    end

    yaml_filename = File.join(TEXTFILE_DIRECTORY, '.' + namevar + '.yaml')
    filename = File.join(TEXTFILE_DIRECTORY, namevar + '.prom')

    common_values = {
      environment: self.environment,
      host: self.host,
    }.reduce([]) {
      |values, extra| values + Array("#{extra[0].to_s}=\"#{extra[1].to_s}\"")
    }

    new_metrics = Hash.new
    unless metrics.empty? or metrics['events'].nil?
      metrics.each do |metric, data|
        data.values.each do |val|
          new_metrics["puppet_report_#{metric}{name=\"#{val[1]}\",#{common_values.join(',')}}"] = val[2]
        end
      end
    end

    epochtime = DateTime.now.new_offset(0).strftime('%Q')
    new_metrics["puppet_report{#{common_values.join(',')}}"] = epochtime

    File.open(filename, 'w') do |file|
      if File.exist?(yaml_filename)
        file.write("# Old metrics\n")
        existing_metrics = YAML.load_file(yaml_filename)
        existing_metrics.each do |k, _v|
          unless new_metrics.include?(k)
            file.write("#{k} -1\n")
          end
        end
      end

      file.write("# New metrics\n")
      new_metrics.each do |k, v|
        file.write("#{k} #{v}\n")
      end
    end

    File.open(yaml_filename, 'w') do |yaml_file|
      yaml_file.write new_metrics.to_yaml
    end
  end
end
