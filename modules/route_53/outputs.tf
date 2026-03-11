output "zone_id" {
  description = "The ARN of the acm certificate"
  value       = aws_route53_zone.primary_external.zone_id
}

output "zone_id_private" {
  description = "The ARN of the acm certificate"
  value       = aws_route53_zone.primary.zone_id
}