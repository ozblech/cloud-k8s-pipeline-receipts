output "minikube_profile" {
  value = aws_iam_instance_profile.minikube_profile.name
}

output "postgres_profile" {
  value = aws_iam_instance_profile.postgres_profile.name
}

output "minikube_role_arn" {
  value = aws_iam_role.minikube_role.arn
}