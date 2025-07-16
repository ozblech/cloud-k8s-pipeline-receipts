output "minikube_sg_id" {
  value = aws_security_group.minikube_sg.id
} 
output "postgres_sg_id" {
  value = aws_security_group.postgres_sg.id
} 