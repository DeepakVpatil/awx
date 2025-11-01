variable "location" {
  description = "Azure region"
  type        = string
  default     = "East US"
}

variable "node_count" {
  description = "Number of nodes in the default node pool"
  type        = number
  default     = 5
}

variable "vm_size" {
  description = "VM size for the nodes"
  type        = string
  default     = "Standard_D4s_v3"
}

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
  default     = "1.28"
}

variable "awx_operator_version" {
  description = "AWX Operator Helm chart version"
  type        = string
  default     = "2.7.2"
}