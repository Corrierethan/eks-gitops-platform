output "vpc_id" {
  description = "VPC ID used by the cluster."
  value       = data.aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs where the cluster and nodes will run."
  value       = data.aws_subnets.private.ids
}

output "kms_key_arn" {
  description = "ARN of the KMS key used for EKS secrets encryption."
  value       = aws_kms_key.eks_secrets.arn
}

output "cluster_name" {
  description = "EKS cluster name."
  value       = aws_eks_cluster.this.name
}

output "cluster_endpoint" {
  description = "EKS API server endpoint."
  value       = aws_eks_cluster.this.endpoint
}

output "cluster_ca_certificate" {
  description = "Base64-encoded certificate authority for the cluster."
  value       = aws_eks_cluster.this.certificate_authority[0].data
}
