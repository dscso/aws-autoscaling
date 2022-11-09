variable "region" {
  type    = string
  default = "us-east-1"
}

variable "elb_logging_bucket_name" {
  type    = string
  default = "insa-elb-log-bucket"
}

variable "ten_buckets" {
  type    = string
  default = "useless-insa-bucket-ff00ff"
}

variable "ssh-key-developer" {
  type    = string
  default = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQD3F6tyPEFEzV0LX3X8BsXdMsQz1x2cEikKDEY0aIj41qgxMCP/iteneqXSIFZBp5vizPvaoIR3Um9xK7PGoW8giupGn+EPuxIA4cDM4vzOqOkiMPhz5XK0whEjkVzTo4+S0puvDZuwIsdiW9mxhJc7tgBNL0cYlWSYVkz4G/fslNfRPW5mYAM49f4fhtxPb5ok4Q2Lg9dPKVHO/Bgeu5woMc7RY0p1ej6D4CKFE6lymSDJpW0YHX/wqE9+cfEauh7xZcG0q9t2ta6F6fmX0agvpFyZo8aFbXeUBr7osSCJNgvavWbM/06niWrOvYX2xwWdhXmXSrbX8ZbabVohBK41 z1@z1"
}

variable "asg-min-capacity" {
  type    = number
  default = 2
}

variable "asg-max-capacity" {
  type    = number
  default = 2
}
variable "asg-desired-capacity" {
  type    = number
  default = 2
}

variable "asg-instance-type" {
  type    = string
  default = "t2.micro"
}