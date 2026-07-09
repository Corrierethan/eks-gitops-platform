variable "region" {
  description = "AWS region for all resources."
  type        = string
  default     = "us-gov-west-1"
}

variable "partition" {
  description = "AWS partition: 'aws' for commercial, 'aws-us-gov' for GovCloud."
  type        = string
  default     = "aws-us-gov"

  validation {
    condition     = contains(["aws", "aws-us-gov"], var.partition)
    error_message = "Partition must be 'aws' or 'aws-us-gov'."
  }
}

variable "cluster_name" {
  description = "Name of the EKS cluster."
  type        = string
  default     = "eks-gitops"
}

variable "vpc_id" {
  description = "ID of the existing VPC where the EKS cluster will be deployed."
  type        = string
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster."
  type        = string
  default     = "1.31"
}

variable "endpoint_public_access" {
  description = "Whether the EKS API server is reachable from the public internet. Set to false for hardened deployments."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Default tags applied to all AWS resources."
  type        = map(string)
  default = {
    Project     = "eks-gitops-platform"
    ManagedBy   = "terraform"
    Environment = "dev"
  }
}
