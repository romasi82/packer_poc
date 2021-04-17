server {
  enabled = true
  bootstrap_expect = 1

  // NOTE: Not needed when using Consul for bootstrapping
  // server_join {
  //   retry_join = [ "provider=aws region=us-west-2 tag_key=Service tag_value=nomad" ]
  //   retry_interval = "15s"
  // }
}

// tls {
//   http = true
//   rpc  = true

//   ca_file   = "/opt/nomad/tls/ca/ca.pem"
//   cert_file = "/opt/nomad/tls/cert.pem"
//   key_file  = "/opt/nomad/tls/key.pem"

//   verify_server_hostname = true
//   verify_https_client    = true
// }