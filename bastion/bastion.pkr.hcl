packer {
  required_version = ">= 1.6.6"
}

variable "consul_version" {
  type    = string
  default = "1.9.1"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "region" {
  type    = string
  default = "us-west-2"
}

locals { timestamp = regex_replace(timestamp(), "[- TZ:]", "") }

source "amazon-ebs" "root_ebs" {
  ami_description = "Ubuntu AMI with Consul Agent installed."
  ami_name        = "bastion-server"
  instance_type   = var.instance_type
  region          = var.region
  ssh_username    = "ubuntu"
  profile         = "marin"

  // For testing only
  force_deregister = true
  force_delete_snapshot = true

  source_ami_filter {
    filters = {
      architecture                       = "x86_64"
      "block-device-mapping.volume-type" = "gp2"
      name                               = "ubuntu/images/*ubuntu-focal-20.04-amd64-server*"
      root-device-type                   = "ebs"
      virtualization-type                = "hvm"
    }
    most_recent = true
    owners      = [ "099720109477" ]
  }

  launch_block_device_mappings {
    device_name           = "/dev/sda1"
    volume_size           = "20"
    volume_type           = "gp2"
    delete_on_termination = true
  }
}


build {
  sources = [
    "source.amazon-ebs.root_ebs"
  ]

  // Wait for cloud-init to complete
  provisioner "shell" {
    inline = [ "/usr/bin/cloud-init status --wait" ]
  }

  provisioner "shell" {
    inline = [ "mkdir -p /tmp/packer" ]
  }

  provisioner "file" {
    destination = "/tmp/packer"
    source      = "${path.root}/../"
  }

  provisioner "shell" {
    inline = [ "/tmp/packer/consul/scripts/install_consul.sh --version ${var.consul_version}" ]
    pause_before = "5s"
  }

  provisioner "shell" {
    inline = [ "/tmp/packer/consul/scripts/configure_dns.sh" ]
    pause_before = "5s"
  }

  // Register with Consul
  // TODO: Figure out a better way of doing this, perhaps via the CLI via user_data?
  provisioner "shell" {
    inline = [ "sudo cp /tmp/packer/bastion/config/bastion.hcl /etc/consul.d" ]
    pause_before = "5s"
  }
}
