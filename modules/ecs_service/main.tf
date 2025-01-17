
## ECS Service
module "ecs_service" {
  source = "terraform-aws-modules/ecs/aws//modules/service"

  cpu                       = 512
  memory                    = 1024
  assign_public_ip          = true
  launch_type               = "FARGATE"
  cluster_arn               = var.cluster_arn
  subnet_ids                = var.private_subnet_ids
  name                      = "${terraform.workspace}-${var.micro_service}-service"

  load_balancer = {
    service = {
      container_port   = 80
      target_group_arn = module.alb.target_groups["default-instance"].arn
      container_name   = "${terraform.workspace}-${var.micro_service}-cdef"
    }
  }

  container_definitions = {
    "${terraform.workspace}-${var.micro_service}-cdef" = {
      cpu                      = 256
      memory                   = 512
      essential                = true
      image                    = var.registry_image
      readonly_root_filesystem = false

      environment = [
        { name = "DB_USER", value = var.db_user },
        { name = "DB_NAME", value = var.db_name },
        { name = "DB_PASS", value = var.db_pass },
        { name = "DB_HOST", value = var.db_host },
      ]

      port_mappings = [
        {
          containerPort = 80
          protocol      = "tcp"
          name          = "http"
        }
      ]
    }
  }

  security_group_rules = {
    alb_ingress = {
      type        = "ingress"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      description = "HTTP port"
      cidr_blocks = ["0.0.0.0/0"]
    }

    db_ingress = {
      type                     = "ingress"
      from_port                = 5432
      to_port                  = 5432
      protocol                 = "tcp"
      description              = "PSQL port"
      source_security_group_id = var.db_sq_id
    }

    egress_all = {
      type        = "egress"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }

  deployment_minimum_healthy_percent = 50
  deployment_maximum_percent         = 200

  tags = {
    Environment = terraform.workspace
  }

  depends_on = [module.alb, module.route53_record]
}

## LoadBalancer
module "alb" {
  source = "terraform-aws-modules/alb/aws"

  internal                   = false
  vpc_id                     = var.vpc_id
  load_balancer_type         = "application"
  subnets                    = var.public_subnet_ids
  name                       = "${var.micro_service}-${terraform.workspace}-alb"
  enable_deletion_protection = false

  security_group_ingress_rules = {
    all_http = {
      from_port   = 80
      to_port     = 80
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTP web traffic"
    }
    all_https = {
      from_port   = 443
      to_port     = 443
      ip_protocol = "tcp"
      cidr_ipv4   = "0.0.0.0/0"
      description = "HTTPS web traffic"
    }
  }
  security_group_egress_rules = {
    all = {
      ip_protocol = "-1"
      cidr_ipv4   = var.vpc_cidr
    }
  }

  listeners = {
    https = {
      port            = 443
      protocol        = "HTTPS"
      certificate_arn = var.ssl_certificate_arn
      forward = {
        target_group_key = "default-instance"
      }
    },
    http = {
      port     = 80
      protocol = "HTTP"
      redirect = {
        port        = "443"
        protocol    = "HTTPS"
        status_code = "HTTP_301"
      }
    }
  }

  target_groups = {
    "default-instance" = {
      name_prefix = "tg"
      port        = 80
      target_type = "ip"
      protocol    = "HTTP"
      vpc_id      = var.vpc_id
      target_id   = "172.0.15.254"
    }
  }

  tags = {
    Environment = terraform.workspace
  }
}

## DNS Record
module "route53_record" {
  source = "terraform-aws-modules/route53/aws//modules/records"

  zone_name = var.domain_name
  records = [
    {
      name = "${var.micro_service}-${terraform.workspace}"
      type = "A"
      alias = {
        name                   = module.alb.dns_name
        zone_id                = module.alb.zone_id
        evaluate_target_health = true
      }
    }
  ]
}
