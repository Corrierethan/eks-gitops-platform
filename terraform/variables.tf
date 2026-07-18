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

variable "addon_vpc_cni_version" {
  description = "Version of the vpc-cni EKS add-on."
  type        = string
  default     = "v1.19.0-eksbuild.1"
}

variable "addon_coredns_version" {
  description = "Version of the coredns EKS add-on."
  type        = string
  default     = "v1.11.4-eksbuild.1"
}

variable "addon_kube_proxy_version" {
  description = "Version of the kube-proxy EKS add-on."
  type        = string
  default     = "v1.31.3-eksbuild.2"
}

variable "node_instance_types" {
  description = "EC2 instance types for the worker nodes."
  type        = list(string)
  default     = ["m5.large"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes."
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of worker nodes."
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of worker nodes."
  type        = number
  default     = 4
}

variable "node_disk_size" {
  description = "EBS root volume size in GB for worker nodes."
  type        = number
  default     = 50
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
