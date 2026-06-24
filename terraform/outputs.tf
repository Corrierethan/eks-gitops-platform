output "vpc_id" {
  description = "VPC ID used by the cluster."
  value       = data.aws_vpc.this.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs where the cluster and nodes will run."
  value       = data.aws_subnets.private.ids
}
