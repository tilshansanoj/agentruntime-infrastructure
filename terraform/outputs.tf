output "alb_dns" {
  value = data.terraform_remote_state.infra.outputs.alb-dns
}
