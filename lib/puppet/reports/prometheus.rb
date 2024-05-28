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
  raise(Puppet::ParseError, "Prometheus report config file #{configfile} not readable") unless File.exist?(configfile)

  config = YAML.load_file(configfile)

  TEXTFILE_DIRECTORY = config['textfile_directory']
  REPORT_FILE_PREFIX = config.fetch('report_file_prefix', 'puppet_report_')
  REPORT_FILE_MODE = config.fetch('report_file_mode', 0o644)
  ENVIRONMENTS = config['environments']
  REPORTS = config['reports']
  STALE_TIME = config['stale_time']

  raise(Puppet::ParseError, "#{configfile}: textfile_directory is not set or is missing.") if TEXTFILE_DIRECTORY.nil? || !File.exist?(TEXTFILE_DIRECTORY)

  def process
    return unless ENVIRONMENTS.nil? || ENVIRONMENTS.include?(environment)

    common_values = {
      environment: environment,
      host: host
    }.reduce([]) do |values, extra|
      values + Array("#{extra[0]}=\"#{extra[1]}\"")
    end

    definitions = ''
    new_metrics = {}
    unless metrics.empty? || metrics['events'].nil?
      metrics.each do |metric, data|
        next unless REPORTS.nil? || REPORTS.include?(metric)

        case metric
        when 'changes'
          definitions << <<~EOS
            # HELP puppet_report_changes Changed resources in the last puppet run
            # TYPE puppet_report_changes gauge
          EOS
        when 'events'
          definitions << <<~EOS
            # HELP puppet_report_events Resource application events
            # TYPE puppet_report_events gauge
          EOS
        when 'resources'
          definitions << <<~EOS
            # HELP puppet_report_resources Resources broken down by their state
            # TYPE puppet_report_resources gauge
          EOS
        when 'time'
          definitions << <<~EOS
            # HELP puppet_report_time Resource apply times
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
    definitions << <<~EOS
      # HELP puppet_report Unix timestamp of the last puppet run
      # TYPE puppet_report gauge
    EOS

    if defined?(transaction_completed) && ([true, false].include? transaction_completed)
      completed = transaction_completed == true ? 1 : 0
      new_metrics["puppet_transaction_completed{#{common_values.join(',')}}"] = completed
      definitions << <<~EOS
        # HELP puppet_transaction_completed transaction completed status of the last puppet run
        # TYPE puppet_transaction_completed gauge
      EOS
    end

    cached_catalog_state = [0, 0, 0]
    if defined?(cached_catalog_status) && (%w[not_used explicitly_requested on_failure].include? cached_catalog_status)
      case cached_catalog_status
      when 'not_used'
        cached_catalog_state[0] = 1
      when 'explicitly_requested'
        cached_catalog_state[1] = 1
      when 'on_failure'
        cached_catalog_state[2] = 1
      end
      new_metrics["puppet_cache_catalog_status{state=\"not_used\",#{common_values.join(',')}}"] = cached_catalog_state[0]
      new_metrics["puppet_cache_catalog_status{state=\"explicitly_requested\",#{common_values.join(',')}}"] = cached_catalog_state[1]
      new_metrics["puppet_cache_catalog_status{state=\"on_failure\",#{common_values.join(',')}}"] = cached_catalog_state[2]
      definitions << <<~EOS
        # HELP puppet_cache_catalog_status whether a cached catalog was used in the run, and if so, the reason that it was used
        # TYPE puppet_cache_catalog_status gauge
      EOS
    end

    # Set initial status
    status_state = [0, 0, 0]
    if defined?(status) && (%w[failed changed unchanged].include? status)
      case status
      when 'failed'
        status_state[0] = 1
      when 'changed'
        status_state[1] = 1
      when 'unchanged'
        status_state[2] = 1
      end
      new_metrics["puppet_status{state=\"failed\",#{common_values.join(',')}}"] = status_state[0]
      new_metrics["puppet_status{state=\"changed\",#{common_values.join(',')}}"] = status_state[1]
      new_metrics["puppet_status{state=\"unchanged\",#{common_values.join(',')}}"] = status_state[2]
      definitions << <<~EOS
        # HELP puppet_status the status of the client run
        # TYPE puppet_status gauge
      EOS
    end

    filename = File.join(TEXTFILE_DIRECTORY, "#{REPORT_FILE_PREFIX}#{host}.prom")

    File.open(filename, 'w') do |file|
      file.write(definitions)
      new_metrics.each do |k, v|
        file.write("#{k} #{v}\n")
      end
    end

    File.chmod(REPORT_FILE_MODE, filename)

    clean_stale_reports
  end

  def clean_stale_reports
    return if STALE_TIME.nil? || STALE_TIME < 1

    Dir.chdir(TEXTFILE_DIRECTORY)
    Dir.glob("#{REPORT_FILE_PREFIX}*.prom").each { |filename| File.delete(filename) if (Time.now - File.mtime(filename)) / (24 * 3600) > STALE_TIME }
  end
end
