# Puppet Prometheus Reports Processor

This module contains a Puppet [reports processor][rpc] that writes report
metrics in a format that is accepted by [Prometheus node_exporter Textfile
Collector][pnetc].

[rpc]:https://docs.puppet.com/puppet/latest/reference/reporting_about.html
[pnetc]:https://github.com/prometheus/node_exporter#textfile-collector


## How to

### Puppet setup

Include this module in your path, and create a file named `prometheus.yaml` in
your Puppet configuration directory.

```yaml
---
textfile_directory: /var/lib/prometheus-dropzone
```

Include `prometheus` in your Puppet reports configuration; enable pluginsync:

```ini
[agent]
report = true
pluginsync = true

[master]
report = true
reports = prometheus
pluginsync = true
```

Note: you can use a comma separated list of reports processors:

```ini
reports = puppetdb,prometheus
```

### Prometheus

Call the Prometheus node_exporter with the `--collector.textfile.directory`
flag:

```
node_exporter --collector.textfile.directory /var/lib/prometheus-dropzone
```

### Sample

```
puppet_report_resources{name="Changed",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_resources{name="Failed",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_resources{name="Failed to restart",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_resources{name="Out of sync",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_resources{name="Restarted",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_resources{name="Scheduled",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_resources{name="Skipped",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_resources{name="Total",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 519
puppet_report_time{name="Acl",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 4.305946465999999
puppet_report_time{name="Anchor",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.002099278
puppet_report_time{name="Augeas",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 10.624435211000002
puppet_report_time{name="Concat file",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.003198308
puppet_report_time{name="Concat fragment",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.011727518000000003
puppet_report_time{name="Config retrieval",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 21.957285313
puppet_report_time{name="Cron",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.000998661
puppet_report_time{name="Exec",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.3956716509999998
puppet_report_time{name="File",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.27236491600000007
puppet_report_time{name="File line",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.0013426360000000001
puppet_report_time{name="Filebucket",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.000321591
puppet_report_time{name="Grafana datasource",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.185209661
puppet_report_time{name="Group",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.002729905
puppet_report_time{name="Mysql datadir",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.000549758
puppet_report_time{name="Package",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 1.6033163289999999
puppet_report_time{name="Service",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.9613265080000001
puppet_report_time{name="Total",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 40.333134474999994
puppet_report_time{name="User",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.0037832459999999997
puppet_report_time{name="Yumrepo",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0.0008275190000000001
puppet_report_changes{name="Total",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_events{name="Failure",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_events{name="Success",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report_events{name="Total",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 0
puppet_report{host="node.example.com",kind="apply",version="9.2-329 (Built on Wed Oct 19 16:15:32 CEST 2016)",transaction_uuid="4f85dbb4-d575-4386-83e4-e71576df71e1",host="node.example.com"} 1477040517280
```

## Contributors

[See Github](https://github.com/voxpupuli/puppet-prometheus_reporter/graphs/contributors).

Special thanks to [Puppet, Inc](http://puppet.com) for Puppet, and its store
reports processor, to [EvenUp](https://letsevenup.com/) for their
[graphite](https://github.com/evenup/evenup-graphite_reporter) reports
processor, and to [Vox Pupuli](https://voxpupuli.org) to provide a platform
that allows us to develop of this module.

## Copyright and License

Copyright © 2016 [Puppet Inc](https://www.puppet.com/)

Copyright © 2016 [EvenUp](https://letsevenup.com/)

Copyright © 2016 [Multiple contributors][mc]

[mc]:https://github.com/voxpupuli/puppet-prometheus_reporter/graphs/contributors

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

