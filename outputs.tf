////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  Repo:           f5-certificate
//  File Name:      outputs.tf
//  Author:         Patrick Gryzan
//  Company:        Hashicorp
//  Date:           January 2020
//  Description:    This is the input variables file for the terraform project
//
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

output "outputs" {
    value                   = {
        ssh_hashistack      = "ssh -o stricthostkeychecking=no -i ${ var.ssh.private_key } ${ var.ssh.username }@${ google_compute_instance.hashistack.network_interface.0.access_config.0.nat_ip } -y"
        big_ip_address      = "https://${ local.big_ip_address }"
        update_cert         = local.update_vip
    }
}