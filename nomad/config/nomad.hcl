datacenter = "us-west-2"
data_dir = "/opt/nomad"

advertise {
  http = "{{ GetInterfaceIP \"ens5\" }}"
  rpc = "{{ GetInterfaceIP \"ens5\" }}"
  serf = "{{ GetInterfaceIP \"ens5\" }}"
}

bind_addr = "0.0.0.0"
// bind_addr = "{{ GetInterfaceIP \"ens5\" }}"

log_level = "warn"
log_file = "/var/log/nomad/"
log_rotate_max_files = 31

consul {
  address             = "127.0.0.1:8500"
  server_service_name = "nomad"
  client_service_name = "nomad-client"
  auto_advertise      = true
  server_auto_join    = true
  client_auto_join    = true
}