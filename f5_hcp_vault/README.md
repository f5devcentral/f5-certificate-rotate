# F5 BIG-IP HCP Vault Integration

This repo uses HashiCorp Vault to manage SSL Certificates

# Architecture
![Demo Arch](rtaImage.png)

# What does the repo uses ?
- Repo uses F5 BIG-IP VE Version 14.X 
- HashiCorp Vault 1.5

# How to use Repo ?
- Git Clone repo using ``` https://github.com/scshitole/bigip-vault.git ```
- change directory ``` cd bigip-vault ```
- deploy ``` terraform plan && terraform apply -auto-approve ```
- This will deploy F5 BIG-IP intance & install Vault on ubuntu on AWS
- SSH into the ubuntu server and cd/tmp
- Configure vault and use vaul agent
```
export VAULT_ADDR="https://vault-cluster.vault.95dfd4f6-6078-40ed-9b82-f58d39eb209e.aws.hashicorp.cloud:8200"
export VAULT_NAMESPACE="admin/f5dev"
### Generate admin token from HCP Vault 
export VAULT_TOKEN=<cut_and paste_token>
vault secrets list 
### update agent file on the ubuntu with HCP Vault address
cd /tmp
vault write pki_int/roles/web-certs allowed_domains=demof5.com ttl=160s max_ttl=30m allow_subdomains=true 
vault auth enable approle
vault policy write app-pol app-pol.hcl
vault write auth/approle/role/web-certs policies="app-pol"
vault read -format=json auth/approle/role/web-certs/role-id | jq -r '.data.role_id' > roleID
vault write -f -format=json auth/approle/role/web-certs/secret-id | jq -r '.data.secret_id' > secretID
vault agent -config=agent-config.hcl -log-level=debug
```
- Open a new terminal and SSH into the ubuntu server again.
- Run the command ``` bash stuff.sh ``` this will deploy the AS3 rpm  & VIP
- Stop the vault agent and uncomment ``` command = "bash updt.sh" ``` in the file agent-config.hcl 
- Run ``` vault agent -config=agent-config.hcl -log-level=debug ``` to update the certs automatically
