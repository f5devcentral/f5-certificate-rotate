resource "aws_instance" "vault_agent" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = "m5.large"
  private_ip             = "10.0.0.100"
  subnet_id              = module.vpc.public_subnets[0]
  vpc_security_group_ids = [aws_security_group.vault_agent.id]
  user_data              = file("templates/hashistack-init.sh")
  iam_instance_profile   = aws_iam_instance_profile.vault.name
  key_name               = aws_key_pair.demo.key_name
  tags = {
    Name = "${var.prefix}-vault_agent"
    Env  = "vault_agent"
  }
  provisioner "file" {
    source      = "templates/certs.tmpl"
    destination = "/tmp/certs.tmpl"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${aws_key_pair.demo.key_name}.pem")
      host        = aws_instance.vault_agent.public_ip
    }
  }

  provisioner "file" {
    source      = "templates/https.tmpl"
    destination = "/tmp/https.tmpl"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${aws_key_pair.demo.key_name}.pem")
      host        = aws_instance.vault_agent.public_ip
    }
  }

  provisioner "file" {
    source      = "templates/app-pol.hcl"
    destination = "/tmp/app-pol.hcl"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${aws_key_pair.demo.key_name}.pem")
      host        = aws_instance.vault_agent.public_ip
    }
  }
  provisioner "file" {
    source      = "templates/agent-config.hcl"
    destination = "/tmp/agent-config.hcl"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${aws_key_pair.demo.key_name}.pem")
      host        = aws_instance.vault_agent.public_ip
    }
  }

  provisioner "file" {
    source      = "as3/stuff.sh"
    destination = "/tmp/stuff.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${aws_key_pair.demo.key_name}.pem")
      host        = aws_instance.vault_agent.public_ip
    }
  }
  provisioner "file" {
    source      = "as3/updt.sh"
    destination = "/tmp/updt.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${aws_key_pair.demo.key_name}.pem")
      host        = aws_instance.vault_agent.public_ip
    }
  }

  provisioner "file" {
    source      = "as3/install-rpm.sh"
    destination = "/tmp/install-rpm.sh"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${aws_key_pair.demo.key_name}.pem")
      host        = aws_instance.vault_agent.public_ip
    }
  }
  provisioner "file" {
    source      = "as3/f5-appsvcs-3.21.0-4.noarch.rpm"
    destination = "/tmp/f5-appsvcs-3.21.0-4.noarch.rpm"
    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${aws_key_pair.demo.key_name}.pem")
      host        = aws_instance.vault_agent.public_ip
    }
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/stuff.sh",
      "chmod +x /tmp/install-rpm.sh",
      "chmod +x /tmp/updt.sh"
    ]

    connection {
      type        = "ssh"
      user        = "ubuntu"
      private_key = file("${aws_key_pair.demo.key_name}.pem")
      host        = aws_instance.vault_agent.public_ip
    }
  }
}

