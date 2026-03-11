output "efs_id" {
  value = aws_efs_file_system.efs.id
}

output "mount_targets" {
  value = aws_efs_mount_target.efs_mount[*].id
}
