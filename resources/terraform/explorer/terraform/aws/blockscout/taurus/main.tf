terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  required_version = ">= 1.0.0"
}

provider "aws" {
  region = var.region
}

# imported with `terraform import aws_instance.blockscout_taurus i-0539bab3e0096f260`
resource "aws_instance" "blockscout_taurus" {
  ami                                  = "ami-05a9ac2fc2ef3e1d5"
  associate_public_ip_address          = true
  availability_zone                    = "us-east-2b"
  disable_api_stop                     = false
  disable_api_termination              = false
  ebs_optimized                        = true
  get_password_data                    = false
  hibernation                          = false
  instance_initiated_shutdown_behavior = "stop"
  instance_type                        = "m7a.2xlarge"
  key_name                             = "explorer-deployer"
  monitoring                           = false
  placement_partition_number           = 0
  private_ip                           = "172.35.1.52"
  secondary_private_ips                = []
  security_groups                      = []
  source_dest_check                    = true
  subnet_id                            = "subnet-0a57e78575b2bcf5a"
  tags = {
    "Name" = "blockscout-taurus"
  }
  tags_all = {
    "Name" = "blockscout-taurus"
  }
  tenancy = "default"
  vpc_security_group_ids = [
    "sg-05bfab744c63b40e9",
  ]

  capacity_reservation_specification {
    capacity_reservation_preference = "open"
  }

  cpu_options {
    core_count       = 8
    threads_per_core = 1
  }

  enclave_options {
    enabled = false
  }

  maintenance_options {
    auto_recovery = "default"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_protocol_ipv6          = "disabled"
    http_put_response_hop_limit = 1
    http_tokens                 = "optional"
    instance_metadata_tags      = "disabled"
  }

  private_dns_name_options {
    enable_resource_name_dns_a_record    = false
    enable_resource_name_dns_aaaa_record = false
    hostname_type                        = "ip-name"
  }

  root_block_device {
    delete_on_termination = true
    encrypted             = false
    iops                  = 3000
    tags                  = {}
    tags_all              = {}
    throughput            = 125
    volume_size           = 500
    volume_type           = "gp3"
  }
}
