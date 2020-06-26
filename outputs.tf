output "F5_IP" {
  value = aws_eip.f5.public_ip
}

output "F5_Password" {
  value = random_string.password.result
}

output "f5_ui" {
  value = "https://${aws_eip.f5.public_ip}:8443"
}


