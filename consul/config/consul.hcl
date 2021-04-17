datacenter = "us-west-2"
domain = "searchfunc13"
data_dir = "/opt/consul/data"
encrypt = "VIu90JLJl7dPxeFnGUKjGVzKRL+Tvx9fTWK/zE8mtUA="
ca_file = "/opt/consul/tls/ca/ca.pem"
cert_file = "/opt/consul/tls/cert.pem"
key_file = "/opt/consul/tls/key.pem"
verify_incoming = true
verify_outgoing = true
verify_server_hostname = true
retry_join = [ "provider=aws region=us-west-2 tag_key=Service tag_value=consul" ]
log_level = "warn"
log_file = "/var/log/consul/"
log_rotate_max_files = 31

// bind_addr = "{{ GetPrivateInterfaces | include \"network\" \"10.0.0.0/16\" | attr \"address\" }}"
bind_addr = "{{ GetInterfaceIP \"ens5\" }}"

// acl = {
//   enabled = true
//   default_policy = "deny"
//   enable_token_persistence = true
// }

performance {
  raft_multiplier = 1
}

ports {
  grpc = 8502
}

connect {
  enabled = true
}