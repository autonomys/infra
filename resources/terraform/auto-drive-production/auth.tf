################################################################################
# Auth Lambda + HTTP API Gateway
#
# All resources use provider alias `aws.auth` (us-east-2), co-located with
# the Aurora DSQL cluster. This replaces the manually-deployed auto-drive-auth
# Lambda (nodejs20.x, us-east-2) and its API Gateway (previously misconfigured
# in us-east-1, causing cross-region latency on every auth request).
#
# Code deployments are handled separately from infrastructure changes:
#   yarn workspace auth lambda:build
#   zip -j apps/auth/build/index.zip apps/auth/build/index.js
#   aws lambda update-function-code \
#     --function-name auto-drive-auth-v2 \
#     --zip-file fileb://apps/auth/build/index.zip \
#     --region us-east-2
################################################################################

locals {
  auth_name = var.auth_function_name
  auth_tags = {
    Name      = local.auth_name
    Project   = "auto-drive"
    Component = "auth"
  }

  # Non-sensitive operational config, hardcoded to keep Infisical lean.
  # Only actual secrets and infrastructure identifiers go in auth.auto.tfvars.
  auth_cors_allowed_origins                    = "*"
  auth_jwt_secret_algorithm                    = "RS256"
  auth_log_level                               = "info"
  auth_revoke_token_emitted_before_in_seconds  = 1746187810
}

# Minimal placeholder used only on the first `terraform apply` to satisfy the
# requirement that a Lambda function must have code at creation time.
# Subsequent code updates are done via `aws lambda update-function-code`.
data "archive_file" "auth_placeholder" {
  type        = "zip"
  output_path = "${path.module}/.auth-placeholder.zip"
  source {
    content  = "exports.handler = async () => ({ statusCode: 503, body: JSON.stringify({ message: 'deploying' }) })"
    filename = "index.js"
  }
}

################################################################################
# IAM
################################################################################

resource "aws_iam_role" "auth_lambda" {
  provider = aws.auth
  name     = "${local.auth_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = local.auth_tags
}

resource "aws_iam_role_policy_attachment" "auth_basic_execution" {
  provider   = aws.auth
  role       = aws_iam_role.auth_lambda.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Grants the Lambda IAM-based access to the DSQL cluster (used by @aws-sdk/dsql-signer).
resource "aws_iam_role_policy" "auth_dsql_access" {
  provider = aws.auth
  name     = "${local.auth_name}-dsql-access"
  role     = aws_iam_role.auth_lambda.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["dsql:DbConnect", "dsql:DbConnectAdmin"]
      Resource = var.auth_dsql_cluster_arn
    }]
  })
}

################################################################################
# Lambda
################################################################################

# Explicit log group so we control retention.
# Without this, Lambda auto-creates it with no retention policy.
resource "aws_cloudwatch_log_group" "auth_lambda" {
  provider          = aws.auth
  name              = "/aws/lambda/${local.auth_name}"
  retention_in_days = var.auth_log_retention_days
  tags              = local.auth_tags
}

resource "aws_lambda_function" "auth" {
  provider         = aws.auth
  function_name    = local.auth_name
  role             = aws_iam_role.auth_lambda.arn
  handler          = "index.handler"
  runtime          = "nodejs24.x"
  memory_size      = var.auth_memory_size
  timeout          = var.auth_timeout
  filename         = data.archive_file.auth_placeholder.output_path
  source_code_hash = data.archive_file.auth_placeholder.output_base64sha256

  environment {
    variables = {
      JWT_SECRET                             = var.auth_jwt_secret
      JWT_SECRET_ALGORITHM                   = local.auth_jwt_secret_algorithm
      API_SECRET                             = var.auth_api_secret
      CORS_ALLOWED_ORIGINS                   = local.auth_cors_allowed_origins
      DSQL_CLUSTER_ENDPOINT                  = var.auth_dsql_cluster_endpoint
      LOG_LEVEL                              = local.auth_log_level
      REVOKE_TOKEN_EMITTED_BEFORE_IN_SECONDS = tostring(local.auth_revoke_token_emitted_before_in_seconds)
    }
  }

  depends_on = [aws_cloudwatch_log_group.auth_lambda]

  # Terraform manages function configuration (runtime, memory, env vars, IAM).
  # Code is deployed separately via aws lambda update-function-code.
  lifecycle {
    ignore_changes = [filename, source_code_hash]
  }

  tags = local.auth_tags
}

################################################################################
# HTTP API Gateway (v2) — same region as Lambda (us-east-2)
################################################################################

resource "aws_apigatewayv2_api" "auth" {
  provider      = aws.auth
  name          = "${local.auth_name}-api"
  protocol_type = "HTTP"
  description   = "Auto Drive Auth Service"

  cors_configuration {
    allow_origins = split(",", local.auth_cors_allowed_origins)
    allow_methods = ["GET", "POST", "PUT", "DELETE", "OPTIONS"]
    allow_headers = ["Authorization", "Content-Type", "X-Api-Key"]
    max_age       = 300
  }

  tags = local.auth_tags
}

resource "aws_apigatewayv2_stage" "auth_default" {
  provider    = aws.auth
  api_id      = aws_apigatewayv2_api.auth.id
  name        = "$default"
  auto_deploy = true

  tags = local.auth_tags
}

resource "aws_apigatewayv2_integration" "auth_lambda" {
  provider               = aws.auth
  api_id                 = aws_apigatewayv2_api.auth.id
  integration_type       = "AWS_PROXY"
  integration_uri        = aws_lambda_function.auth.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "auth_default" {
  provider  = aws.auth
  api_id    = aws_apigatewayv2_api.auth.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.auth_lambda.id}"
}

resource "aws_lambda_permission" "auth_api_gateway" {
  provider      = aws.auth
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.auth.execution_arn}/*/*"
}
