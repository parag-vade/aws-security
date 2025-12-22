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