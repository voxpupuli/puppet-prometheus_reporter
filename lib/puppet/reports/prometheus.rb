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
  ENVIRONMENTS = config['environments']
  REPORTS = config['reports']

  if TEXTFILE_DIRECTORY.nil?
    raise(Puppet::ParseError, "#{configfile}: textfile_directory is not set.")
  end

  unless REPORT_FILENAME.nil? || REPORT_FILENAME.end_with?('.prom')
    raise(Puppet::ParseError, "#{configfile}: report_filename does not ends with .prom")
  end

  def process
    Process.exit(0) unless ENVIRONMENTS.nil? || ENVIRONMENTS.include?(environment)
    namevar = if REPORT_FILENAME.nil?
                host + '.prom'
              else
                REPORT_FILENAME
              end

    yaml_filename = File.join(TEXTFILE_DIRECTORY, '.' + namevar + '.yaml')
    filename = File.join(TEXTFILE_DIRECTORY, namevar)

    common_values = {
      environment: environment,
      host: host
    }.reduce([]) do |values, extra|
      values + Array("#{extra[0]}=\"#{extra[1]}\"")
    end

    definitions = ""
    new_metrics = {}
    unless metrics.empty? || metrics['events'].nil?
      metrics.each do |metric, data|
        next unless REPORTS.nil? || REPORTS.include?(metric)
        case metric
        when "changes"
          definitions << <<-EOS
# HELP puppet_report_changes Changed resources in the last puppet run
# TYPE puppet_report_changes gauge
EOS
        when "events"
          definitions << <<-EOS
# HELP puppet_report_events Puppet events TODO: explain better
# TYPE puppet_report_events gauge
EOS
        when "resources"
          definitions << <<-EOS
# HELP puppet_report_resources Puppet ressources break down by their state
# TYPE puppet_report_resources gauge
EOS
        when "time"
          definitions << <<-EOS
# HELP puppet_report_time Puppet ressource apply time broken down by their type
# TYPE puppet_report_time gauge
EOS
        end
        data.values.each do |val|
          new_metrics["puppet_report_#{metric}{name=\"#{val[1]}\",#{common_values.join(',')}}"] = val[2]
        end
      end
    end

    epochtime = DateTime.now.new_offset(0).strftime('%Q').to_i / 1000.0
    new_metrics["puppet_report{#{common_values.join(',')}}"] = epochtime
    definitions << <<-EOS
# HELP puppet_report Unix timestamp of the last puppet run
# TYPE puppet_report gauge
EOS

    File.open(filename, 'w') do |file|
      file.write(definitions)
      if File.exist?(yaml_filename)
        file.write("# Old metrics\n")
        existing_metrics = YAML.load_file(yaml_filename)
        existing_metrics.each do |k, _v|
          file.write("#{k} -1\n") unless new_metrics.include?(k)
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
