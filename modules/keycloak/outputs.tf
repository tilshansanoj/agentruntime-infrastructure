output "kc_ecs_security_group_id"  { value = aws_security_group.kc_ecs.id }
output "kc_rds_endpoint"{ 
    value = module.kc_rds.db_instance_address
    sensitive = true 
}
output "console_confidential_secret_arn"         { value = aws_ssm_parameter.console_confidential_secret.arn }
output "wheelhouse_service_client_secret_arn"    { value = aws_ssm_parameter.wheelhouse_service_client_secret.arn }
