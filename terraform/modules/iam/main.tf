# ---------------------------------------------------------------------------
# EC2 instance role — least privilege. Only CloudWatch metrics/logs (the
# minimum AWS-documented scope for the CloudWatch Agent, which does not
# support resource-level restriction) plus, by default, SSM Session Manager
# so instances never need an open SSH/RDP port for admin access.
#
# Deliberately NOT granted: S3, EC2, IAM, RDS or any other service — a
# workload that needs more must get an explicit, scoped policy added by the
# environment consuming this module, never a blanket "*"/"*" statement.
# ---------------------------------------------------------------------------

resource "aws_iam_role" "ec2" {
  count = var.create_ec2_role ? 1 : 0
  name  = "${var.name_prefix}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })

  tags = var.tags
}

resource "aws_iam_role_policy" "ec2_cloudwatch" {
  count = var.create_ec2_role ? 1 : 0
  name  = "${var.name_prefix}-ec2-cloudwatch"
  role  = aws_iam_role.ec2[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchMetricsAndLogs"
        Effect = "Allow"
        Action = [
          "cloudwatch:PutMetricData",
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        # cloudwatch:PutMetricData and logs:CreateLogGroup do not support
        # resource-level restriction in IAM — Resource "*" here is the
        # AWS-documented minimum scope for the CloudWatch Agent, not a
        # blanket grant (the Action list stays narrow and explicit).
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_extra" {
  for_each   = var.create_ec2_role ? toset(var.ec2_managed_policy_arns) : toset([])
  role       = aws_iam_role.ec2[0].name
  policy_arn = each.value
}

resource "aws_iam_instance_profile" "ec2" {
  count = var.create_ec2_role ? 1 : 0
  name  = "${var.name_prefix}-ec2-profile"
  role  = aws_iam_role.ec2[0].name
  tags  = var.tags
}

# ---------------------------------------------------------------------------
# GitHub Actions OIDC federation — no long-lived AWS access keys stored as
# GitHub Secrets. The role trust policy pins both the audience and the exact
# repository + ref allowed to assume it.
# ---------------------------------------------------------------------------

resource "aws_iam_openid_connect_provider" "github" {
  count = var.create_github_oidc_provider ? 1 : 0

  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  # AWS validates GitHub's OIDC token against its own trusted CA bundle since
  # 2023 (https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/);
  # this thumbprint is kept only for provider schema compatibility (must be a
  # syntactically valid 40-character SHA-1 hex digest, but AWS ignores it).
  thumbprint_list = ["1c58a3a8518e8759bf075b76b750d4f2df264fcd"]

  tags = var.tags
}

locals {
  github_oidc_provider_arn = var.create_github_oidc_provider ? aws_iam_openid_connect_provider.github[0].arn : var.existing_github_oidc_provider_arn
}

resource "aws_iam_role" "github_actions" {
  name = "${var.name_prefix}-github-actions-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = local.github_oidc_provider_arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = [
            for ref in var.github_allowed_branches :
            "repo:${var.github_org}/${var.github_repo}:${ref}"
          ]
        }
      }
    }]
  })

  tags = var.tags
}

# Read-only Describe/List permissions needed for `terraform plan` to render
# a diff. These are AWS Describe/List APIs that do not support
# resource-level restriction (documented AWS limitation, not a design
# shortcut) — write access below is scoped to specific ARNs.
resource "aws_iam_role_policy" "github_actions_terraform" {
  name = "${var.name_prefix}-github-actions-terraform"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = concat(
      [
        {
          Sid    = "TerraformPlanReadOnly"
          Effect = "Allow"
          Action = [
            "ec2:Describe*",
            "elasticloadbalancing:Describe*",
            "autoscaling:Describe*",
            "rds:Describe*",
            "rds:ListTagsForResource",
            "iam:GetRole",
            "iam:GetRolePolicy",
            "iam:ListRolePolicies",
            "iam:ListAttachedRolePolicies",
            "iam:GetInstanceProfile",
            "iam:GetOpenIDConnectProvider",
            "cloudwatch:DescribeAlarms",
            "cloudwatch:GetDashboard",
            "cloudwatch:ListDashboards",
            "sns:GetTopicAttributes",
            "sns:ListTopics"
          ]
          Resource = "*"
        }
      ],
      var.state_bucket_arn != "" ? [
        {
          Sid    = "TerraformStateBucket"
          Effect = "Allow"
          Action = [
            "s3:GetObject",
            "s3:PutObject",
            "s3:ListBucket"
          ]
          Resource = [
            var.state_bucket_arn,
            "${var.state_bucket_arn}/*"
          ]
        }
      ] : [],
      var.state_lock_table_arn != "" ? [
        {
          Sid    = "TerraformStateLock"
          Effect = "Allow"
          Action = [
            "dynamodb:GetItem",
            "dynamodb:PutItem",
            "dynamodb:DeleteItem"
          ]
          Resource = var.state_lock_table_arn
        }
      ] : []
    )
  })
}
