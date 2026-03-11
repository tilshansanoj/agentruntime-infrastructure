output "acm-certificate-arn" {
  description = "The ARN of the acm certificate"
  value       = aws_acm_certificate.acm_certificate.arn
}