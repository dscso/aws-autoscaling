locals {
  # XXX
  name = "external"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "~> 3.18.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs             = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  intra_subnets = ["10.0.1.0/24", "10.0.2.0/24"] # private subnets for ec2 instances
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"] # load balancer

  enable_nat_gateway = false # no internet 😢
  enable_vpn_gateway = false

  tags = {}
}

data "aws_ami" "nginx_serverimage" {
  most_recent = true
  owners      = ["979382823631"]

  filter {
    name = "name"

    values = [
      "bitnami-nginx-1.23.2-0-r01-linux-debian-11-x86_64-hvm-ebs-nami",
    ]
  }
}

module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  # Autoscaling group
  name = local.name

  vpc_zone_identifier = module.vpc.intra_subnets
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2

  # Launch template
  create_launch_template = true
  image_id      = data.aws_ami.nginx_serverimage.id
  instance_type = "t2.micro"

  target_group_arns = module.alb.target_group_arns
  security_groups          = [aws_security_group.asg_sg.id
    #module.asg_sg.security_group_id
  ]

#  network_interfaces = [
#    {
#      delete_on_termination = true
#      description           = "eth0"
#      device_index          = 0
#      security_groups       = [module.asg_sg.security_group_id]
#    },
#    {
#      delete_on_termination = true
#      description           = "eth1"
#      device_index          = 1
#      security_groups       = [module.asg_sg.security_group_id]
#    }
#  ]

  tags = {}
}

module "alb_http_sg" { # make load balancer accessible from the internet
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "~> 4.0"

  name        = "${local.name}-alb-http"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for ${local.name}"

  ingress_cidr_blocks = ["0.0.0.0/0"]

  tags = {}
}

module "alb" {
  source  = "terraform-aws-modules/alb/aws"
  version = "~> 6.0"

  name = "${local.name}"

  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.public_subnets
  security_groups = [module.alb_http_sg.security_group_id]

  http_tcp_listeners = [
    {
      port               = 80
      protocol           = "HTTP"
      target_group_index = 0
    }
  ]

  target_groups = [
    {
      name             = local.name
      backend_protocol = "HTTP"
      backend_port     = 80
      target_type      = "instance"
    },
  ]

  tags = {}
}

resource "aws_security_group" "asg_sg" {
  name        = "allow_all"
  description = "Allow inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description      = "TLS from VPC"
    from_port        = 80
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {  }
}