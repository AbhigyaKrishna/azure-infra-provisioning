variable "project_name" {
  description = "The name of the project."
  type        = string
}

variable "environment" {
  description = "The environment for the resources (e.g., dev, prod)."
  type        = string
}

variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group in which to create the virtual network."
  type        = string
}

variable "common_tags" {
  description = "A map of common tags to apply to all resources."
  type        = map(string)
  default     = {}
}

variable "vm_count" {
  description = "The number of virtual machines to create."
  type        = number
  default     = 1
}

variable "vm_size" {
  description = "The size of the virtual machines."
  type        = string
  default     = "Standard_Av2"
}

variable "admin_username" {
  description = "The admin username for the virtual machines."
  type        = string
}

variable "ssh_public_key" {
  description = "The SSH public key for the virtual machines."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the virtual machines will be deployed."
  type        = string
}