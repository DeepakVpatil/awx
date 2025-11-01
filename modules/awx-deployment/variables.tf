variable "namespace" {
  description = "Kubernetes namespace for AWX"
  type        = string
  default     = "awx"
}

variable "operator_version" {
  description = "AWX Operator Helm chart version"
  type        = string
  default     = null
}

variable "operator_values" {
  description = "Values for AWX Operator Helm chart"
  type        = any
  default     = {}
}