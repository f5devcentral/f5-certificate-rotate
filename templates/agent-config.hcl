pid_file = "./pidfile"

vault {
   address = "http://127.0.0.1:8200"
}

auto_auth {
   method "approle" {
       mount_path = "auth/approle"
       config = {
           role_id_file_path = "roleID"
           secret_id_file_path = "secretID"
           remove_secret_id_file_after_reading = false
       }
   }

   sink "file" {
       config = {
           path = "approleToken"
       }
   }
}

template {
  source      = "./certs.tmpl"
  destination = "./certs.json"
  #command = "bash updt.sh"
}

template {
    source = "./https.tmpl"
    destination = "./https.json"
}
