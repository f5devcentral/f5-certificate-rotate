# Permits token creation
path "auth/token/create" {
  capabilities = ["update"]
}

# Permits token renew
path "auth/token/renew" {
  capabilities = ["update"]
}

# Read-only permission on secret/
path "secret/data/*" {
  capabilities = ["read"]
}

# Enable secrets engine
path "sys/mounts/*" {
  capabilities = [ "create", "read", "update", "delete", "list" ]
}
# List enabled secrets engine
path "sys/mounts" {
  capabilities = [ "read", "list" ]
}
# Work with pki secrets engine
path "pki*" {
  capabilities = [ "create", "read", "update", "delete", "list", "sudo" ]
}
