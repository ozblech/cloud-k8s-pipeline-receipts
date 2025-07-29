// ------------------------
// outputs
// -------------------------
output minikube_ec2_public_ip {
  value       = aws_instance.minikube_ec2.public_ip
}

output postgres_ec2_public_ip {
  value       = aws_instance.postgres_ec2.public_ip
}

output minikube_ec2_tag_name {
  value = aws_instance.minikube_ec2.tags["Name"]
}

output minikube_ec2_id {
  value = aws_instance.minikube_ec2.id
}