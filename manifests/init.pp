# @summary Class to configure the prometheus reporter
# @param textfile_directory Location of the node_exporter collector.textfile.directory (Required)
# @param config_directory Directory to place the prometheus.yaml config file. The default value is the Puppet config directory of the
#         compiling puppet server.  If your agents have a different directory you will need to override this value.
# @param report_file_prefix Prefix for metrics files.
# @param report_file_mode File mode to set on report files.
# @param environments If specified, only creates metrics on reports from these environments
# @param reports If specified, only creates metrics from reports of this type (changes, events, resources, time)
# @param stale_time If specified, delete metric files for nodes that haven't sent reports in X days
class prometheus_reporter (
  Stdlib::Absolutepath               $textfile_directory = '/var/lib/prometheus/node-exporter',
  Stdlib::Absolutepath               $config_directory   = $settings::config.dirname,
  String                             $report_file_prefix = 'puppet_report_',
  Stdlib::Filemode                   $report_file_mode   = '0644',
  Array[String[1]]                   $environments       = [],
  Array[Prometheus_reporter::Report] $reports            = [],
  Optional[Integer]                  $stale_time         = undef,
) {
  $config = {
    'textfile_directory' => $textfile_directory,
    'report_file_prefix' => $report_file_prefix,
    'report_file_mode'   => Integer($report_file_mode, 8),
    'environments'       => $environments,
    'reports'            => $reports,
    'stale_time'         => $stale_time,
  }.filter |$k, $v| { $v != undef and ($v !~ Array or !$v.empty) }  # drop undef and empty arrays
  file { "${config_directory}/prometheus.yaml":
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    content => stdlib::to_yaml($config),
  }
}
