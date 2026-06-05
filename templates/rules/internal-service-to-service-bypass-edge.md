---
type: rule
purpose: Require internal service-to-service calls to use private FQDNs rather than public CDN-proxied hostnames so WAF rules do not silently 403 internal callers.
read_when: When authoring or reviewing any cron job, worker process, or service-to-service HTTP call -- using the public CDN hostname causes silent WAF 403s that are hard to diagnose.
tags: [networking, internal-services, waf, infrastructure, service-mesh]
scope: public
departments: [engineering]
last_evaluated: 2026-06-03
---
# Internal Service-to-Service Calls Bypass Public Edge

Internal cron jobs, worker processes, health pokes, and cross-service RPC should call the
service's internal / private FQDN, NOT the public CDN-proxied hostname. Public WAF rules
written for external scrapers silently catch internal user agents and return 403.

## Rule

For any service-to-service call where BOTH caller and callee are in the same trust zone
(same cloud account, same VPC, or same CI pipeline):

1. **Prefer:** call the private / internal FQDN (internal ingress, VPC-internal endpoint, cluster DNS)
2. **Acceptable:** call the public FQDN BUT carve path exemptions in WAF rules for internal paths
3. **Avoid:** call the public FQDN and rely on UA spoofing or header tricks to get through WAF

## Why

Public WAF rules are tuned for external threats. Common rules block:
- curl, wget, python-requests, scrapy user agents
- Empty User-Agent
- Non-browser TLS fingerprints
- Rate-limit per IP

Your own internal caller (a cron job container, a retry worker) will trip all of these. The
WAF returns 403. The caller retries. Your own cron silently fails while WAF does exactly what
you configured it to do.

## Good Options

- Use the internal FQDN: bypass the public CDN/WAF entirely (preferred)
- WAF path carve-out: exempt specific internal-only paths from bot UA rules (acceptable workaround)
- Shared-secret auth: add a header the internal caller sends; WAF skips on header presence

## How to Apply

- When authoring a new cron / service-to-service call: default to internal FQDN
- When auditing existing infra: grep for `https://<public-domain>` in cron / job definitions; flag for review
- When modifying WAF rules: consider whether the rule will block any internal caller
- When a cron silently returns 403: check whether it is hitting the public edge first
