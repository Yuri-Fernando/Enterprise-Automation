# ---------------------------------------------------------------------------
# Three-tier security groups: web (internet-facing ALB) -> app (only from
# web) -> db (only from app). No security group ever exposes an application
# or database port directly to 0.0.0.0/0 — only the load balancer's HTTP(S)
# listener does, by design.
# ---------------------------------------------------------------------------

resource "aws_security_group" "web" {
  name_prefix = "${var.name_prefix}-web-"
  description = "Load balancer - public HTTP(S) ingress only"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name_prefix}-web-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "web_http" {
  for_each          = toset(var.web_ingress_cidrs)
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = each.value
  from_port         = var.web_ingress_port
  to_port           = var.web_ingress_port
  ip_protocol       = "tcp"
  description       = "HTTP from allowed CIDR"
}

resource "aws_vpc_security_group_ingress_rule" "web_https" {
  count             = var.enable_https ? length(var.web_ingress_cidrs) : 0
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = var.web_ingress_cidrs[count.index]
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  description       = "HTTPS from allowed CIDR"
}

resource "aws_vpc_security_group_egress_rule" "web_all" {
  security_group_id = aws_security_group.web.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

resource "aws_security_group" "app" {
  name_prefix = "${var.name_prefix}-app-"
  description = "Application instances - reachable only from the load balancer (+ optional admin access)"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name_prefix}-app-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "app_from_web" {
  security_group_id            = aws_security_group.app.id
  referenced_security_group_id = aws_security_group.web.id
  from_port                    = var.app_port
  to_port                      = var.app_port
  ip_protocol                  = "tcp"
  description                  = "App port from load balancer only"
}

resource "aws_vpc_security_group_ingress_rule" "app_admin" {
  for_each          = toset(var.admin_access_cidrs)
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = each.value
  from_port         = var.os_type == "windows" ? 3389 : 22
  to_port           = var.os_type == "windows" ? 3389 : 22
  ip_protocol       = "tcp"
  description       = "${var.os_type == "windows" ? "RDP" : "SSH"} admin access from allowed CIDR"
}

resource "aws_vpc_security_group_egress_rule" "app_all" {
  security_group_id = aws_security_group.app.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}

resource "aws_security_group" "db" {
  name_prefix = "${var.name_prefix}-db-"
  description = "Database - reachable only from application instances"
  vpc_id      = var.vpc_id

  tags = merge(var.tags, { Name = "${var.name_prefix}-db-sg" })

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_app" {
  security_group_id            = aws_security_group.db.id
  referenced_security_group_id = aws_security_group.app.id
  from_port                    = var.db_port
  to_port                      = var.db_port
  ip_protocol                  = "tcp"
  description                  = "DB port from app instances only"
}

resource "aws_vpc_security_group_egress_rule" "db_all" {
  security_group_id = aws_security_group.db.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
  description       = "Allow all outbound"
}
