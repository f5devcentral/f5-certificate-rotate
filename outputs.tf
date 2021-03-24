

output "f5_ui" {
  value = "https://${aws_eip.f5.public_ip}:8443"
}

output "vault_ui" {
  value = "http://${aws_instance.vault.public_ip}:8200"
}

output "F5_Password" {
  value = random_string.password.result
}

output "To_SSH_into_vault_ubuntu" {
  value = "ssh -i ${aws_key_pair.demo.key_name}.pem ubuntu@${aws_instance.vault.public_ip}"
}
