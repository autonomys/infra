variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "vpc_id" {
  default = "default"
  type    = string
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["us-east-1a", "us-east-1c", "eu-central-1a"]
}


variable "ami" {
  default = "ami-0557a15b87f6559cf"
  type    = string

  validation {
    condition     = length(var.ami) > 4 && substr(var.ami, 0, 4) == "ami-"
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
  }
}

# variable "ec2_ami" {
#   type = map

#   default = {
#     us-east-1 = "ami-0557a15b87f6559cf"
#     us-west-1 = "ami-006fce872b320923e"
#   }
# }

variable "instance_count" {
  type    = number
  default = 1
}


variable "aws_region" {
  description = "aws region"
  type        = list(string)
  default     = ["us-east-1"]
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.31.1.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["172.31.2.0/24"]
}

variable "secret_key" {
  type      = string
  sensitive = true
}

variable "access_key" {
  type      = string
  sensitive = true
}

variable "aws_key_name" {
  default   = "deployer"
  type      = string
  sensitive = true
}

variable "public_key_path" {
  type = string
  default = ""
}
