variable "prefix" {
  description = "prefix for resources created"
  default     = "scs-bigip-hcpvault"
}
variable "region" {
  description = "region where the infra is deployed"
  default     = "us-west-2"
}

variable "sub-region" {
  description = "region where the infra is deployed"
  default     = "us-west-2a"
}

variable "f5ami" {
  description = "f5 ami in west 2"
  default     = "ami-09ae9af26d2e96786"
}
