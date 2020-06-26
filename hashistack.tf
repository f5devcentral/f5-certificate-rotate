resource "aws_instance" "vault" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "m5.large"
  private_ip             = "10.0.0.100"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.vault.id]
  user_data              = file("templates/hashistack-init.sh")
  iam_instance_profile   = aws_iam_instance_profile.vault.name
  key_name               = aws_key_pair.demo.key_name
  tags = {
    Name = "${var.prefix}-vault"
    Env  = "vault"
  }
}

