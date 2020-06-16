# F5 Certificate Rotation Using Vault and Consul Template
This is an example of how rotate certificates on an F5 LTM using Vault and Consul Template

**Before you begin, please make sure you have an SSH key pair that allows you to SSH into the environment virtual machines. You will need the private key to perform some setup via Terraform.**

* To get started, clone the repo to your local drive and create a copy of the **terraform.tfvars.example** file named **terraform.tfvars**. 
* Fill in your GCP and SSH credentials.
* Run
  ```bash
  terraform init
  ```
  to initialize Terraform
* Run
  ```bash
  terraform apply -auto-approve
  ```
  to spin up F5 BIP-IP and Hashistack virtual machines. When complete, you should see the output commands

  ![alt text](https://github.com/pgryzan/f5-certificate-rotation/blob/master/images/Terraform%20Outputs.png "Terraform Output Commands")
  The Big-IP vm takes about 3 to 5 minutes to complete initialization. If you need to reference the Terraform outputs commands, you can always see them again by running
  ```bash
  terraform output
  ```
* Open the outputs **big_ip_adsress** url in the browser and login using the F5 credentials located in the variable.tf file. Set the Partition in the upper right hand corner to **Demo** and navigate to **Local Traffic > Virtual Servers > Virtual Server List.** You see something that looks like:

  ![alt text](https://github.com/pgryzan/f5-certificate-rotation/blob/master/images/F5%20VIP.png "F5 VIP")
* Now your ready to SSH into the Hashistack vm. Run the outputs **ssh_hashistack** command to login into the vm and **change the directory to /tmp**. This is where all of the certificate rotation action is happening.
* Take a look at the **certs.tmpl** file. This is the template that Consul Template uses to create the **certs.json** file. The certs.json file is uploaded to the F5 VM to rotate the certificate.
* Take a look at the **certs.json** file. Notice the we've already setup the Vault PKI Engine to rotate the certificates every 60 seconds. You can watch the remarks timestamp update by running:
  ```bash
  cat certs.json
  ```

  ![alt text](https://github.com/pgryzan/f5-certificate-rotation/blob/master/images/Generated%20Certs.png "Vault Generated Certificates")
* Finnaly, run the **update_cert** command on the Hashistack vm. You should see a completion output

  ![alt text](https://github.com/pgryzan/f5-certificate-rotation/blob/master/images/Cert%20Rotation%20Success.png "Certificate Success")
* If you wanted to have Consul Template automatically upload the certificate to the F5 VIP, then uncomment the **command** variable in the **/etc/consul-template.d/consul-template.hcl** file and restart the server using
  ```bash
  sudo service consul-template restart
  ```