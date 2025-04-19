output "eks_cluster_name" {
  description = "The name of the EKS cluster."
  value       = aws_eks_cluster.demo.name
  
}

output "eks_cluster_endpoint" {
  description = "The endpoint of the EKS cluster."
  value       = aws_eks_cluster.demo.endpoint
  
}

output "kubeconfig" {
  description = "command to update kubconfig"
  value       = "aws eks update-kubeconfig --name ${aws_eks_cluster.demo.name} --region ${var.region}"
}