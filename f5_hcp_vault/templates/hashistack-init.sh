#!/bin/bash

set -e

#   Utils
sudo apt-get install unzip
sudo snap install jq
VAULT_VERSION="1.5.0"

#   Move to Temp Directory
cd /tmp

#############################################################################################################################
#   Vault
#############################################################################################################################
#   Download
curl --silent --remote-name https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip

#   Install
unzip vault_${VAULT_VERSION}_linux_amd64.zip
sudo chown root:root vault
sudo mv vault /usr/local/bin/
vault -autocomplete-install
complete -C /usr/local/bin/vault vault
sudo setcap cap_ipc_lock=+ep /usr/local/bin/vault

cat <<-EOF > vault.service
[Unit]
Description=Vault
Documentation=https://www.vaultproject.io/
Requires=network-online.target
After=network-online.target

[Service]
Restart=on-failure
Environment=GOMAXPROCS=nproc
ExecStart=/usr/local/bin/vault server -dev -dev-root-token-id="root" -dev-listen-address=0.0.0.0:8200
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

sudo chmod 755 vault.service
sudo mv vault.service /etc/systemd/system/

#   Enable the Service
sudo systemctl enable vault
sudo service vault start

sleep 10

#   Tell Vault we're using http
echo -e "export VAULT_ADDR=http://127.0.0.1:8200" >> ~/.bash_profile
export VAULT_ADDR=http://127.0.0.1:8200

#   Export VAULT_TOKEN
echo -e "export VAULT_TOKEN=root" >> ~/.bash_profile
export VAULT_TOKEN=root

#   Enable the PKI Engine
vault secrets enable pki

# Tune the pki secrets engine to issue certificates with a maximum time-to-live (TTL) of 87600 hours.
vault secrets tune -max-lease-ttl=87600h pki

#   Generate a Root CA
# vault write pki/root/generate/internal common_name=demof5.com  > root-ca

vault write -field=certificate pki/root/generate/internal common_name=demof5.com ttl=87600h > CA_cert.crt

# Configure the CA and CRL URLs.
vault write pki/config/urls issuing_certificates="$VAULT_ADDR/v1/pki/ca" crl_distribution_points="$VAULT_ADDR/v1/pki/crl"

# Generate Intermediate CA
# Now, you are going to create an intermediate CA using the root CA you regenerated in the previous step.
# First, enable the pki secrets engine at the pki_int path.
vault secrets enable -path=pki_int pki

#Tune the pki_int secrets engine to issue certificates with a maximum time-to-live (TTL) of 43800 hours.

vault secrets tune -max-lease-ttl=43800h pki_int

# Execute the following command to generate an intermediate and save the CSR as pki_intermediate.csr.
vault write -format=json pki_int/intermediate/generate/internal common_name="demof5.com Intermediate Authority" | jq -r '.data.csr' > pki_intermediate.csr

# Sign the intermediate certificate with the root CA private key, and save the generated certificate as intermediate.cert.pem.

vault write -format=json pki/root/sign-intermediate csr=@pki_intermediate.csr format=pem_bundle ttl="43800h" | jq -r '.data.certificate' > intermediate.cert.pem

# Once the CSR is signed and the root CA returns a certificate, it can be imported back into Vault.
vault write pki_int/intermediate/set-signed certificate=@intermediate.cert.pem

#   Configure a Role
vault write pki_int/roles/web-certs allowed_domains=demof5.com ttl=160s max_ttl=30m allow_subdomains=true allow_localhost=true generate_lease=true

#############################################################################################################################
#############################################################################################################################
#   Setup F5
#############################################################################################################################
sudo mv id_rsa ~/.ssh
sudo chown 600 ~/.ssh/id_rsa

wget https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.17.1/f5-appsvcs-3.17.1-1.noarch.rpm
sudo chmod +x install-rpm.sh

COMMANDS="modify auth user admin { password random_string.password.result };
modify auth user admin shell bash;
modify sys global-settings gui-setup disabled;
save sys config;
quit;"

echo "Setting up BIG-IP"

index=1
maxConnectionAttempts=12

while (( $index <= $maxConnectionAttempts ))
do
  ssh -o stricthostkeychecking=no -i ~/.ssh/id_rsa ${F5_USERNAME}@${BIG_IP} -y $COMMANDS
  case $? in
    (0) echo "Success"; break ;;
    (*) echo "BIG-IP SSH server not ready yet..." ;;
  esac
  sleep 10
  ((index+=1))
done

echo "Checking for BIG-IP Configuration Utility"
while [[ $(curl --silent --insecure -u ${F5_USERNAME}:${F5_PASSWORD} https://${BIG_IP}:8443/mgmt/tm/ltm | jq .kind) != "\"tm:ltm:ltmcollectionstate\"" ]]
do
   sleep 30
   echo "Trying BIG-IP Configuration Utility again..."
done

echo "Installing RPM"
./install-rpm.sh ${aws_eip.f5.public_ip}:8443 admin:random_string.password.result f5-appsvcs-3.17.1-1.noarch.rpm

sleep 30

echo "Creating BIG-IP VIP"
curl -X POST --silent --insecure -u admin:random_string.password.result -H 'Content-Type: application/json' -d @https.json https://${aws_eip.f5.public_ip}:8443/mgmt/shared/appsvcs/declare | jq

exit 0


