variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "address_space" {
  description = "The address space for the virtual network."
  type        = list(string)
}

variable "private_subnet_cidr" {
  description = "The CIDR block for the private subnet."
  type        = string
}

variable "public_subnet_cidr" {
  description = "The CIDR block for the public subnet."
  type        = string
}

variable "ssh_key_file_path" {
  description = "The SSH public key for the virtual machines."
  type        = string
}

variable "bastion_subnet_cidr" {
  description = "The CIDR block for the bastion subnet."
  type        = string
  default     = ""
}

variable "allowed_ssh_cidr" {
  description = "The CIDR block allowed to SSH into the bastion host."
  type        = string
  default     = "*"
}
