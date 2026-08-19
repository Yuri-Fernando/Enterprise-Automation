locals {
  name_prefix = "${var.project_name}-${var.environment}"
  tags        = {}

  # Instances launch in public subnets when there's no NAT Gateway (they need
  # a public IP for package installs / SSM), private subnets otherwise.
  instance_subnet_ids = var.enable_nat_gateway ? module.networking.private_subnet_ids : module.networking.public_subnet_ids
  associate_public_ip = !var.enable_nat_gateway
}

module "networking" {
  source = "../../modules/networking"

  name_prefix          = local.name_prefix
  vpc_cidr             = var.vpc_cidr
  azs                  = var.azs
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  enable_nat_gateway   = var.enable_nat_gateway
  single_nat_gateway   = var.single_nat_gateway
  tags                 = local.tags
}

module "security" {
  source = "../../modules/security"

  name_prefix        = local.name_prefix
  vpc_id             = module.networking.vpc_id
  web_ingress_cidrs  = var.web_ingress_cidrs
  enable_https       = var.enable_https_listener
  app_port           = var.app_port
  admin_access_cidrs = var.admin_access_cidrs
  os_type            = var.os_type
  tags               = local.tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix                       = local.name_prefix
  create_github_oidc_provider       = var.create_github_oidc_provider
  existing_github_oidc_provider_arn = var.existing_github_oidc_provider_arn
  github_org                        = var.github_org
  github_repo                       = var.github_repo
  github_allowed_branches           = var.github_allowed_branches
  state_bucket_arn                  = var.state_bucket_arn
  state_lock_table_arn              = var.state_lock_table_arn
  tags                              = local.tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix                = local.name_prefix
  vpc_id                     = module.networking.vpc_id
  public_subnet_ids          = module.networking.public_subnet_ids
  instance_subnet_ids        = local.instance_subnet_ids
  web_security_group_id      = module.security.web_security_group_id
  app_security_group_id      = module.security.app_security_group_id
  os_type                    = var.os_type
  instance_type              = var.instance_type
  iam_instance_profile_name  = module.iam.ec2_instance_profile_name
  key_name                   = var.key_name
  associate_public_ip        = local.associate_public_ip
  min_size                   = var.min_size
  desired_capacity           = var.desired_capacity
  max_size                   = var.max_size
  app_port                   = var.app_port
  enable_https_listener      = var.enable_https_listener
  certificate_arn            = var.certificate_arn
  enable_deletion_protection = var.enable_alb_deletion_protection
  tags                       = local.tags
}

module "database" {
  source = "../../modules/database"

  name_prefix            = local.name_prefix
  subnet_ids             = module.networking.private_subnet_ids
  vpc_security_group_ids = [module.security.db_security_group_id]
  instance_class         = var.db_instance_class
  multi_az               = var.db_multi_az
  skip_final_snapshot    = var.db_skip_final_snapshot
  deletion_protection    = var.db_deletion_protection
  tags                   = local.tags
}

module "monitoring" {
  source = "../../modules/monitoring"

  name_prefix = local.name_prefix
  tags        = local.tags

  create_sns_topic = var.create_sns_topic
  alarm_email      = var.alarm_email

  enable_ec2_alarms      = var.enable_ec2_alarms
  autoscaling_group_name = module.compute.autoscaling_group_name

  enable_alb_alarms       = var.enable_alb_alarms
  alb_arn_suffix          = module.compute.alb_arn_suffix
  target_group_arn_suffix = module.compute.target_group_arn_suffix

  enable_rds_alarms = var.enable_rds_alarms
  db_instance_id    = module.database.db_instance_id

  log_group_names = ["/${var.project_name}/${var.environment}/app"]
}
