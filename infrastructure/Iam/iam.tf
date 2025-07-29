// ------------------------
// iam
// ------------------------
resource "aws_iam_role" "postgres_role" {
  name = "postgres-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "minikube_role" {
  name = "minikube-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = {
        Service = "ec2.amazonaws.com"
      },
      Action = "sts:AssumeRole"
    }]
  })
}

// Attach policies to roles
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.minikube_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
}

resource "aws_iam_role_policy_attachment" "ssm_minikube_access" {
  role       = aws_iam_role.minikube_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

// EC2 instances do not accept IAM roles directly, only instance profiles.
resource "aws_iam_instance_profile" "minikube_profile" {
  name = "minikube-instance-profile"
  role = aws_iam_role.minikube_role.name
}

resource "aws_iam_instance_profile" "postgres_profile" {
  name = "postgres-instance-profile"
  role = aws_iam_role.postgres_role.name
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions_role" {
  name = "github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        },
        Action = "sts:AssumeRoleWithWebIdentity",
        Condition = {
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*"
          }
        }
      }
    ]
  })
}

data "aws_caller_identity" "current" {}

resource "aws_iam_role_policy" "github_actions_policy" {
  name = "github-actions-policy"
  role = aws_iam_role.github_actions_role.id

  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid: "AllowSendCommandToInstance",
        Effect: "Allow",
        Action: "ssm:SendCommand",
        Resource: [
          "arn:aws:ec2:${var.region}:${data.aws_caller_identity.current.account_id}:instance/${var.minikube_ec2_id}"
        ]
      },
      {
        Sid: "AllowRunShellScriptDocument",
        Effect: "Allow",
        Action: "ssm:SendCommand",
        Resource: "arn:aws:ssm:${var.region}::document/AWS-RunShellScript"
      },
      {
        Sid: "AllowSSMDescribeAndGet",
        Effect: "Allow",
        Action: [
          "ssm:GetCommandInvocation",
          "ssm:ListCommands",
          "ssm:ListCommandInvocations",
          "ssm:GetDocument",
          "ssm:DescribeDocument"
        ],
        Resource: "*"
      },
      {
        Sid: "AllowEC2Describe",
        Effect: "Allow",
        Action: "ec2:DescribeInstances",
        Resource: "*"
      }
    ]
  })
}

# OIDC Provider for GitHub Actions
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1" # GitHub Actions thumbprint
  ]
}

# SSM Role for GitHub Actions
# resource "aws_iam_role" "ec2_ssm_role" {
#   name = "ec2_ssm_role"
#   assume_role_policy = jsonencode({
#     Version = "2012-10-17",
#     Statement = [{
#       Effect = "Allow",
#       Principal = {
#         Service = "ec2.amazonaws.com"
#       },
#       Action = "sts:AssumeRole"
#     }]
#   })
# }

# resource "aws_iam_role_policy_attachment" "ssm_managed_policy" {
#   role       = aws_iam_role.ec2_ssm_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# resource "aws_iam_instance_profile" "ec2_ssm_profile" {
#   name = "ec2_ssm_profile"
#   role = aws_iam_role.ec2_ssm_role.name
# }