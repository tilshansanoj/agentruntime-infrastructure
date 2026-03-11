output "id" {
  description = "The ID of the load balancer"
  value       = aws_ecs_cluster.cluster.id
}