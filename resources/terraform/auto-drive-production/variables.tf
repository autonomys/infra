variable "region" {
  description = "AWS region where the resources will be created"
  type        = string
  default     = "us-west-2"
}

variable "backup_region" {
  description = "AWS region for RDS cross-region backup replication"
  type        = string
  default     = "us-west-1"
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

variable "auth_jwt_secret_algorithm" {
  description = "JWT signing algorithm"
  type        = string
  default     = "RS256"
}

variable "auth_api_secret" {
  description = "Admin API authentication secret"
  type        = string
  sensitive   = true
}

variable "auth_cors_allowed_origins" {
  description = "Comma-separated list of CORS-allowed origins"
  type        = string
}

variable "auth_dsql_cluster_endpoint" {
  description = "Aurora DSQL cluster endpoint hostname"
  type        = string
}

variable "auth_dsql_cluster_arn" {
  description = "Aurora DSQL cluster ARN, used in the IAM policy granting the Lambda DbConnect access"
  type        = string
}

variable "auth_log_level" {
  description = "Auth service log level"
  type        = string
  default     = "info"
}

variable "auth_revoke_token_emitted_before_in_seconds" {
  description = "Revoke all tokens issued more than this many seconds ago (0 = disabled)"
  type        = number
  default     = 0
}

variable "rabbitmq_username" {
  description = "RabbitMQ username"
  type        = string
  default     = "guru"
  sensitive   = true
}
