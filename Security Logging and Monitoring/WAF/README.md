# AWS WAF

 

## Overview

 

- **Network level firewalls (SG/NACL)**: Only check basic details of a request like source IP/port, destination IP/port. Cannot see inside the actual request. Malicious code can be part of the request targeting the application.

- **WAF**: Analyzes HTTP request headers (User-Agent, Content-Type, Cookies, etc.), request body, URL path, HTTP method, etc., by inspecting the packet.

- Protects against common web exploits like **SQL injection**, **Cross Site Scripting (XSS)**, etc.

- Popular WAF solutions: CloudFlare, Akamai, ModSecurity (open source), AWS WAF.

- Protects applications from common web exploits like SQL injection and XSS.

 

## AWS WAF Features

 

- **Managed WAF**: No need to worry about high availability or scalability. Focus is on WAF Rules.

- **Integration with**: ALB, API Gateway, CloudFront Distribution, etc.

- **WAF Web ACL Traffic Overview**: Shows request accepted vs denied, bots/non-bots, desktop vs mobile requests, top 10 countries from which requests originate.

- To check if a resource is protected: Go to WebACL in WAF and see if it has an **Associated AWS resource**.

 

## Components of AWS WAF

 

### 1. Rules

 

- Define how WAF should inspect HTTP/S requests and the actions to take if criteria match.

- Rules can be based on parameters like:

  - Location of request origin

  - IP address

  - Request components: headers, cookies, URI path, request body, etc.

- Each rule can have a single criterion or multiple criteria combined with **AND**, **OR**, **NOT** operators.

- **Rule Actions**:

  - Allow

  - Block

  - Count

  - Present CAPTCHA or challenge to confirm the request is not from a bot

 

### 2. Rule Groups

 

- Reusable collection of rules that can be used across Web ACLs.

- Related rules can be grouped logically. Example: all SQL injection related rules.

- Types of Rule Groups:

  - Customer Managed

  - AWS Managed (created and managed by AWS)

  - AWS Marketplace

 

### 3. Web ACLs

 

- Container for Rules and Rule Groups.

- Web ACLs are associated with **AWS resources**, not individual rules or rule sets.

- A single Web ACL can be associated with multiple AWS resources, but each AWS resource can only have **one Web ACL**.



## WAF Lab Implementation

### Architecture
EC2 (web server) → ALB → WAF Web ACL → Internet

### Resources Created

| Resource | Name | Purpose |
|----------|------|---------|
| VPC | waf-lab-vpc | 10.0.0.0/16 |
| Subnets | waf-lab-public-1, 2 | Two AZs for ALB |
| EC2 | waf-lab-web-1 | Apache web server |
| ALB | waf-lab-alb | Public-facing load balancer |
| WAF Web ACL | waf-lab-webacl | Attached to ALB |

### WAF Rules Configured

| Rule | Priority | Action | Description |
|------|----------|--------|-------------|
| BlockUK | 1 | Block | Blocks requests from GB (geo-match) |
| RateLimitDDoS | 2 | Block | Blocks IP after 100 requests/5 min |

**Default Action**: Allow (if no rules match)

### Testing Performed
1. **Geo-blocking**: Accessed ALB from UK → 403 Forbidden
2. **Rate limiting**: Sent 150 requests via PowerShell → Blocked after 100

## Test Results

**1. Geo-blocking (BlockUK rule)**

| VPN Location | Result |
|--------------|--------|
| US (no VPN) | ✅ 200 OK |
| Ireland | ✅ 200 OK |
| India | ✅ 200 OK |
| UK (London) | ❌ 403 Forbidden |

**2. Rate Limiting (RateLimitDDoS rule)**

| Test Run | Requests | Result |
|----------|----------|--------|
| First | 150 | 135 OK, 15 BLOCKED |
| Second (same IP) | 150 | 0 OK, 150 BLOCKED |

Rate limiting activated after ~100 requests per 5-minute window. Subsequent requests from the same IP were blocked until the window reset.

**3. AWS WAF Console Evidence**

- **Sampled Requests (BlockUK)**: Blocked requests from GB-located IPs
- **Sampled Requests (RateLimitDDoS)**: 100+ blocked requests from IPs exceeding rate limit
- **CloudWatch Metrics**: Traffic spikes visible correlating with test times

### Key Learnings
- WAF rules are evaluated by priority (lower number = higher priority)
- Rate limiting uses sliding window evaluation, not instant blocking
- Geo-blocking uses IP geolocation databases to determine country of origin
- VPN testing effectively demonstrates geo-blocking rules

### Screenshots
- **VPN connected to Ireland - non-UK location allowed**
<img width="1785" height="918" alt="1" src="https://github.com/user-attachments/assets/3e952b66-ebad-4a61-85cd-83cbbb5c7a81" />

- **Successful access (200 OK) from Ireland**
  <img width="1911" height="1073" alt="2" src="https://github.com/user-attachments/assets/adfcea6b-9c76-4dd2-8ac2-cde50a4cc9d2" />

- **VPN connected to UK (London) - blocked country**
  <img width="1905" height="1063" alt="4" src="https://github.com/user-attachments/assets/b3fd2652-3976-4977-81b1-7336f4a5c40c" />

- **PowerShell rate limit test - first run: 135 OK/15 blocked, second run: 0 OK/150 blocked**
  <img width="1900" height="918" alt="5" src="https://github.com/user-attachments/assets/b5ea4094-c04b-41d2-b310-3861849a4084" />

- **WAF CloudWatch metrics showing traffic spikes during testing**
  <img width="1490" height="957" alt="6" src="https://github.com/user-attachments/assets/a7697b40-cfd2-4bcb-8d9d-37dbaabf31d6" />

- **WAF Sampled Requests - BlockUK rule blocking requests from GB**
  <img width="1423" height="715" alt="7" src="https://github.com/user-attachments/assets/e20cafa8-387e-495d-a21c-58c1307a86e9" />

- **WAF Sampled Requests - RateLimitDDoS rule blocking IPs from IN, AU, IE after exceeding threshold**
  <img width="1420" height="805" alt="8" src="https://github.com/user-attachments/assets/b248eb24-27b6-4f53-b4e1-9f40934ae795" />


  
