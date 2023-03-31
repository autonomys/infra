// Output Variables

output "public_ip_web_server" {
  value = aws_eip.web-server-eip.public_ip
}

output "api_server_id" {
  value = aws_instance.api-server-1.id
}

output "api_server_private_ip" {
  value = aws_instance.api-server-1.private_ip
}

output "ingress_rules" {
  value = aws_security_group.allow_web.ingress
}

output "server_ami" {
  value = aws_instance.web-server.ami
}

# output "state_bucket_arn" {
#   value = aws_s3_bucket.backend.arn
# }

# output "dynamo_lock_table" {
#   value = aws_dynamodb_table.lock.id
# }

# output "iam_roles" {
#   value = concat(
#     aws_iam_role.backend-all.*.arn,
#     aws_iam_role.backend-restricted.*.arn,
#   )
# }
