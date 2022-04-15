provider "aws" {
  region = var.region
}
locals {
  bigip_address = "${aws_eip.f5.public_ip}:8443"
  update_vip    = "curl -sku admin:${random_string.password.result} -H 'Accept: application/json' -H 'Content-Type:application/json' -X PATCH -d@certs.json https://${local.bigip_address}/mgmt/shared/appsvcs/declare | jq"
  create_vip    = "curl -sku admin:${random_string.password.result} -H 'Accept: application/json' -H 'Content-Type:application/json' -X POST -d@https.json https://${local.bigip_address}/mgmt/shared/appsvcs/declare | jq"
  delete_vip    = "curl -sku admin:${random_string.password.result} -H 'Accept: application/json' -H 'Content-Type:application/json' -X DELETE  https://${local.bigip_address}/mgmt/shared/appsvcs/declare/Demo | jq"
  install_as3   = "./install-rpm.sh ${local.bigip_address} admin:${random_string.password.result} f5-appsvcs-3.21.0-4.noarch.rpm"
}
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

# Generate a tfvars file for AS3 installation
data "template_file" "tfvars" {
  template = file("as3/terraform.tfvars.example")
  vars = {
    addr        = aws_eip.f5.public_ip
    port        = "8443"
    username    = "admin"
    pwd         = random_string.password.result
    CREATE_VIP  = local.create_vip
    DELETE_VIP  = local.delete_vip
    INSTALL_AS3 = local.install_as3
  }
}

resource "local_file" "tfvars" {
  content  = data.template_file.tfvars.rendered
  filename = "as3/stuff.sh"
}

# Generate file to update Certs
data "template_file" "updt_cert" {
  template = file("as3/terraform.tfvars.cert")
  vars = {
    addr        = aws_eip.f5.public_ip
    port        = "8443"
    username    = "admin"
    pwd         = random_string.password.result
    UPDATE_CERT = local.update_vip
  }
}

resource "local_file" "updt_cert" {
  content  = data.template_file.updt_cert.rendered
  filename = "as3/updt.sh"
}
