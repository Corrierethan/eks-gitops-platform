variable "role_name" {
  description = "Name of the IAM role to create."
  type        = string
}

variable "oidc_provider_arn" {
  description = "ARN of the EKS OIDC provider."
  type        = string
}

variable "oidc_provider_url" {
  description = "URL of the OIDC provider (without https://)."
  type        = string
}

variable "namespace" {
  description = "Kubernetes namespace of the service account."
  type        = string
}

variable "service_account" {
  description = "Kubernetes service account name."
  type        = string
}

variable "policy_arns" {
  description = "List of IAM policy ARNs to attach to the role."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Tags to apply to the IAM role."
  type        = map(string)
  default     = {}
}