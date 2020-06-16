////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           f5-certificate
//  File Name:      main.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           January 2020
//  Description:    This is the main execution file
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

terraform {
    required_version = ">= 0.12"
}

locals {
    big_ip_address          = "${ google_compute_instance.big_ip.network_interface.0.access_config.0.nat_ip }:${ var.f5.port }"
    basic_creds             = base64encode("${ var.f5.username }:${ var.f5.password }")
    update_vip              = "curl -X PATCH --silent --insecure -H 'Content-Type: application/json' -H 'Authorization: Basic ${local.basic_creds}' -d @certs.json https://${local.big_ip_address}/mgmt/shared/appsvcs/declare | jq"
//    test_as3                = "curl --silent --insecure -H 'Authorization: Basic ${local.basic_creds}' https://${local.big_ip_address}/mgmt/tm/ltm | jq"
//    create_vip              = "curl -X POST --silent --insecure -H 'Content-Type: application/json' -H 'Authorization: Basic ${local.basic_creds}' -d @https.json https://${local.big_ip_address}/mgmt/shared/appsvcs/declare | jq"
//    delete_vip              = "curl -X DELETE --silent --insecure -H 'Content-Type: application/json' -H 'Authorization: Basic ${local.basic_creds}' https://${local.big_ip_address}//mgmt/shared/appsvcs/declare/Demo | jq"
}

provider "google" {
    credentials             = file(var.gcp.path)
    project                 = var.gcp.project
    region                  = var.gcp.region
    zone                    = var.gcp.zone
}

data "template_file" "f5_init" {
    template = file("templates/f5-init.sh")
    vars                    = {
        username            = var.f5.username
        password            = var.f5.password
    }
}

data "template_file" "hashistack_init" {
    template = file("templates/hashistack-init.sh")
    vars                    = {
        VAULT_VERSION       = "1.3.2"
        CONSUL_TEMPLATE_VERSION = "0.24.1"
        UPDATE_VIP          = local.update_vip
        F5_USERNAME         = var.f5.username
        F5_PASSWORD         = var.f5.password
        BIG_IP              = google_compute_instance.big_ip.network_interface.0.network_ip
    }
}

resource "google_compute_firewall" "default" {
    name                    = "demo-firewall"
    network                 = "default"

    allow {
        protocol            = "tcp"
        ports               = [ "22", "8200", "8443" ]
    }
}

resource "google_compute_instance" "big_ip" {
    name                    = "big-ip"
    machine_type            = "e2-standard-4"
    //metadata_startup_script = data.template_file.f5_init.rendered

    boot_disk {
        initialize_params {
            image           = var.f5.image
            size            = var.f5.size
            type            = "pd-ssd"
        }
    }

    network_interface {
        network             = "default"
        access_config {
        }
    }
}

resource "google_compute_instance" "hashistack" {
    name                    = "hashistack"
    machine_type            = "n1-standard-2"

    boot_disk {
        initialize_params {
            image           = var.hashistack.image
            size            = var.hashistack.size
            type            = "pd-ssd"
        }
    }

    network_interface {
        network             = "default"
        access_config {
        }
    }

    connection {
        type                = "ssh"
        host                = google_compute_instance.hashistack.network_interface.0.access_config.0.nat_ip
        user                = var.ssh.username 
        private_key         = file(var.ssh.private_key)
    }

    provisioner "file" {
        content             = data.template_file.hashistack_init.rendered
        destination         = "/tmp/hashistack-init.sh"
    }

    provisioner "file" {
        source              = "templates/certs.tmpl"
        destination         = "/tmp/certs.tmpl"
    }

    provisioner "file" {
        source              = "templates/https.tmpl"
        destination         = "/tmp/https.tmpl"
    }

    provisioner "file" {
        source              = "scripts/install-rpm.sh"
        destination         = "/tmp/install-rpm.sh"
    }

    provisioner "file" {
        content             = file(var.ssh.private_key)
        destination         = "/tmp/id_rsa"
    }

    provisioner "remote-exec" {
        inline                  = [
            "chmod +x /tmp/hashistack-init.sh",
            "sudo /tmp/hashistack-init.sh",
            "sudo rm -r /tmp/hashistack-init.sh",
        ]
    }
}