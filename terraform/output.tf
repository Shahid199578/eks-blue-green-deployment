output "eks_cluster_name" {
  description = "Name of EKS Cluster"
  value       = aws_eks_cluster.demo.name
}

output "eks_cluster_endpoint" {
  description = "The endpoint of cluster"
  value       = aws_eks_cluster.demo.endpoint
}
