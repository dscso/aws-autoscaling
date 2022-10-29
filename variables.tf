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