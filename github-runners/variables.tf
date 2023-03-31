variable "instance_type" {
  default = "t2.micro"
  type    = string
}

variable "vpc_id" {
  default = "vpc-67ef901d"
  type    = string
}

variable "ami" {
  default = "ami-0557a15b87f6559cf"
  type    = string

  validation {
    condition     = length(var.image_id) > 4 && substr(var.image_id, 0, 4) == "ami-"
    error_message = "The image_id value must be a valid AMI id, starting with \"ami-\"."
  }
}

# variable "ec2_ami" {
#   type = map

#   default = {
#     us-east-2 = "ami-0416962131234133f"
#     us-west-1 = "ami-006fce872b320923e"
#   }
# }

variable "instance_count" {
  type    = number
  default = 1
}

# variable "subnet_prefix" {
#   description = "subnet cidr prefix"
#   type = list(string)
#   default = ["172.31.1.0/24", "172.31.2.0/24"]
# }

variable "subnet_prefix" {
  description = "subnet cidr prefix"
  type        = list(object({
    cidr_block = string
    name = string

  }))

  default = [{
    cidr_block = "172.31.2.0/24"
    name       = "gh-runner-subnet"
  }]
}

variable "aws_users" {
  default = []
  sensitive = true
}

variable "secret_key" {
  sensitive = true
}

variable "access_key" {
  sensitive = true
}

variable "aws_key_name" {}

