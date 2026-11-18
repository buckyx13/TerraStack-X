# setproduct() = Creates all combinations 
locals {
  ports = var.certificate_arn == null ? [80] : [80,433]
  ingress_rules = {
    for pair in setproduct(local.ports, var.allowed_ingress_cidrs) :
    "${pair[0]}-${pair[1]}" => { port = pair[0], cidr = pair[1] }
  }
}

resource "aws_security_group" "alb" {
  name_prefix = "${var.name}-alb-"
  description = "ALB: web in from allowed CIDRs; egress to app tier in added by the caller"
  vpc_id = var.vpc_id

  # No inline egress block => Terraform removes the default allow-all egress rule.

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "${var.name}-alb"
  }
}

resource "aws_vpc_security_group_ingress_rule" "web" {
  for_each = local.ingress_rules
  security_group_id = aws_security_group.alb.id
  description = "Web ${each.value.port} from ${each.value.cidr}"
  cidr_ipv4   = each.value.cidr
  from_port   = each.value.port
  ip_protocol = "tcp" 
  to_port     = each.value.port
}

resource "aws_lb" "this" {
  name = var.name
  load_balancer_type = "application"
  internal = false
  security_groups = [ aws_security_group.alb.id ]
  subnets = var.public_subnet_ids
  drop_invalid_header_fields = true
  enable_deletion_protection = var.deletion_protection
}

resource "aws_lb_target_group" "app" {
  name_prefix = "app-"
  vpc_id = var.vpc_id
  port = var.target_port
  protocol = "HTTP"
  deregistration_delay = 30

  health_check {
    path = var.health_check_path
    matcher = "200"
    interval = 15
    healthy_threshold = 2
    unhealthy_threshold = 3
  }

  lifecycle {
    create_before_destroy = true
  }
}

# No certificate: plain HTTP forward (dev / lab).
resource "aws_lb_listener" "http_forward" {
  count = var.certificate_arn == null ? 1 : 0

  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}

# Certificate supplied: redirect 80 -> 443 and terminate TLS 1.2+.
resource "aws_lb_listener" "http_redirect" {
  count = var.certificate_arn == null ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port = 80
  protocol = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port = 443
      protocol = "HTTPS"
      status_code = HTTP_301
    }
  }
}

resource "aws_lb_listener" "https" {
  count = var.certificate_arn == null ? 0 : 1

  load_balancer_arn = aws_lb.this.arn
  port = 443
  protocol = "HTTPS"
  ssl_policy = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  certificate_arn = var.certificate_arn

  default_action {
    type = "forward"
    target_group_arn = aws_lb_target_group.app.arn
  }
}