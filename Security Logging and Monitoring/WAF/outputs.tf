output "alb_dns_name" {
  description = "ALB DNS name to test WAF rules"
  value       = aws_lb.web.dns_name
}

output "alb_url" {
  description = "Full URL to test"
  value       = "http://${aws_lb.web.dns_name}"
}

output "web_acl_arn" {
  description = "WAF Web ACL ARN"
  value       = aws_wafv2_web_acl.waf_lab.arn
}

output "web_acl_id" {
  description = "WAF Web ACL ID"
  value       = aws_wafv2_web_acl.waf_lab.id
}

output "ec2_public_ips" {
  description = "EC2 public IPs (for direct testing if needed)"
  value       = aws_instance.web[*].public_ip
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.waf_lab.id
}
