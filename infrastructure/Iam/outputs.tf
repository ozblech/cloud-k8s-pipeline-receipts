output "minikube_profile" {
  value = aws_iam_instance_profile.minikube_profile.name
}
output "postgres_profile" {
  value = aws_iam_instance_profile.postgres_profile.name
}