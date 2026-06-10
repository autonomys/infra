variable "aws_access_key" {
  description = "AWS access key"
  type        = string
  sensitive   = true
}

variable "aws_secret_key" {
  description = "AWS secret key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "AWS region where the resources will be created"
  type        = string
  default     = "us-west-2"
}

################################################################################
# Auth Lambda
################################################################################

variable "auth_region" {
  description = "AWS region for auth Lambda and API Gateway. Co-located with the DSQL cluster."
  type        = string
  default     = "us-east-2"
}

variable "auth_function_name" {
  description = "Auth Lambda function name"
  type        = string
  default     = "auto-drive-auth-v2"
}

variable "auth_memory_size" {
  description = "Auth Lambda memory allocation in MB"
  type        = number
  default     = 512
}

variable "auth_timeout" {
  description = "Auth Lambda timeout in seconds"
  type        = number
  default     = 15
}

variable "auth_log_retention_days" {
  description = "Auth Lambda CloudWatch log retention in days"
  type        = number
  default     = 30
}

variable "auth_jwt_secret" {
  description = "Base64-encoded JWT signing secret"
  type        = string
  sensitive   = true
}

variable "auth_api_secret" {
  description = "Admin API authentication secret"
  type        = string
  sensitive   = true
}

variable "auth_dsql_cluster_endpoint" {
  description = "Aurora DSQL cluster endpoint hostname"
  type        = string
  sensitive   = true
}

variable "auth_dsql_cluster_arn" {
  description = "Aurora DSQL cluster ARN, used in the IAM policy granting the Lambda DbConnect access"
  type        = string
  sensitive   = true
}

variable "rabbitmq_username" {
  description = "RabbitMQ username"
  type        = string
  default     = "guru"
  sensitive   = true
}
