output "elb" {
  value = module.elb_http.this_elb_dns_name
}

output "elb_logging" {
  value = module.elb_logging_bucket.s3_bucket_arn
}