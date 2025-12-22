#!/bin/bash
yum update -y
yum install -y httpd
systemctl start httpd
systemctl enable httpd
echo "<h1>WAF Lab Server $instance_index</h1><p>Time: $(date)</p>" > /var/www/html/index.html
