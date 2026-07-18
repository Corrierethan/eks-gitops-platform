resource "aws_eks_addon" "vpc_cni" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "vpc-cni"
  addon_version            = var.addon_vpc_cni_version
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}

resource "aws_eks_addon" "coredns" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "coredns"
  addon_version            = var.addon_coredns_version
  resolve_conflicts_on_update = "OVERWRITE"

  depends_on = [aws_eks_node_group.general]

  tags = var.tags
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name             = aws_eks_cluster.this.name
  addon_name               = "kube-proxy"
  addon_version            = var.addon_kube_proxy_version
  resolve_conflicts_on_update = "OVERWRITE"

  tags = var.tags
}