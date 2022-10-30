locals {
  # defining name of load balancer
  name = "external"
}
# create 10 buckets with incrementing name
module "ten-buckets" {
  count  = 10
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "${var.ten_buckets}-${count.index}"
  acl    = "private"
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 3.18.0"

  name = "my-vpc"
  cidr = "10.0.0.0/16"

  azs            = [data.aws_availability_zones.available.names[0], data.aws_availability_zones.available.names[1]]
  intra_subnets  = ["10.0.1.0/24", "10.0.2.0/24"]     # private subnets for ec2 instances
  public_subnets = ["10.0.101.0/24", "10.0.102.0/24"] # load balancer

  enable_nat_gateway = false # no internet 😢
  enable_vpn_gateway = false
}

# SSH keypair
module "key_pair_developer" {
  source = "terraform-aws-modules/key-pair/aws"

  key_name   = "developer"
  public_key = var.ssh-key-developer
}

# need to use some preinstalled nginx because there is no internet in the ec2 instances due to missing nat gateway
data "aws_ami" "nginx_serverimage" {
  most_recent = true
  owners      = ["979382823631"]

  filter {
    name = "name"

    values = [
      "bitnami-nginx-*-linux-debian-*-hvm-ebs-nami",
    ]
  }
}

# autoscaling group
module "asg" {
  source  = "terraform-aws-modules/autoscaling/aws"
  version = "~> 6.5"

  name = local.name

  vpc_zone_identifier = module.vpc.intra_subnets
  min_size            = 2
  max_size            = 2
  desired_capacity    = 2

  # Launch template
  create_launch_template = true
  image_id               = data.aws_ami.nginx_serverimage.id
  instance_type          = "t2.micro"
  key_name               = module.key_pair_developer.key_pair_name

  security_groups = [aws_security_group.asg_sg.id]
  load_balancers  = [module.elb_http.this_elb_name]
}

module "elb_http" {
  source  = "terraform-aws-modules/elb/aws"
  version = "~> 2.0"

  name = "${local.name}-elb"

  subnets         = module.vpc.public_subnets
  security_groups = [module.elb_http_sg.security_group_id]
  internal        = false

  listener = [
    {
      instance_port     = 80
      instance_protocol = "HTTP"
      lb_port           = 80
      lb_protocol       = "HTTP"
    }
  ]

  health_check = {
    target              = "HTTP:80/"
    interval            = 30
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 5
  }

  access_logs = {
    bucket = var.elb_logging_bucket_name
  }
}

# logging just for fun
module "elb_logging_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket                         = var.elb_logging_bucket_name
  acl                            = "log-delivery-write"
  attach_elb_log_delivery_policy = true
}

# make load balancer accessible from the internet
module "elb_http_sg" {
  source  = "terraform-aws-modules/security-group/aws//modules/http-80"
  version = "~> 4.0"

  name        = "${local.name}-alb-http"
  vpc_id      = module.vpc.vpc_id
  description = "Security group for ${local.name}"

  ingress_cidr_blocks = ["0.0.0.0/0"]
}


resource "aws_security_group" "asg_sg" {
  name        = "allow_all"
  description = "Allow inbound traffic"
  vpc_id      = module.vpc.vpc_id

  ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}