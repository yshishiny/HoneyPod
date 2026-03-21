# HoneyPod Project Roadmap

All notable fixes, changes, and planned work are tracked here.
Format: `[YYYY-MM-DD] - Description`

---

## Branch: `master`

---

## 2026-03-21 — Full Code Review & Bug Fix Sprint

### Critical Fixes (Deploy Blockers)

| # | File(s) | Issue | Fix Applied |
|---|---------|-------|-------------|
| 1 | `security-tooling/docker-compose.yml` | ELK stack used `image: 8.9.1` but all Dockerfiles pinned `7.17.23` — services would fail to start due to auth/enrollment incompatibility | Switched all services to `build:` with local Dockerfiles. Removed 8.x-only xpack enrollment env vars. |
| 2 | `security-tooling/elk/logstash-sysmon.conf` `security-tooling/elk/patterns/sysmon.grok` | Both paths were **directories**, not files — Logstash container would fail to mount them | Deleted directories, created proper pipeline file and grok patterns file |
| 3 | `terraform/main.tf` `terraform/networks.tf` `terraform/vms.tf` | `main.tf` declared only `hyperv` provider but `networks.tf` and `vms.tf` contained extensive `azurerm_*` resources — `terraform plan` would immediately error | Added `azurerm` provider + `random` provider to `main.tf`. Extracted all Azure resources to `vms-azure.tf`, `networks-azure.tf`, and `azure-base.tf`. Added `count = local.deploy_azure ? 1 : 0` guards so Azure resources are skipped when `azure_subscription_id` is empty. |
| 4 | `terraform/vms.tf` | `local.get_vswitch_name(...)` and `local.generate_mac_address(...)` used function-call syntax — Terraform `locals` are maps, not functions | Fixed to use map-lookup syntax: `local.get_vswitch_name["${zone}_zone"]` etc. |
| 5 | `ansible/site.yml` | Used non-existent `win_wait_for_serial:` module — AD setup phase would immediately fail | Replaced with `ansible.builtin.pause: seconds: 120` |

### High Severity Fixes

| # | File(s) | Issue | Fix Applied |
|---|---------|-------|-------------|
| 6 | `security-tooling/docker-compose.yml` `security-tooling/redis/Dockerfile` | All credentials hardcoded in docker-compose | Moved to `${VAR:-default}` env var pattern. Created `security-tooling/.env.example` as template. Redis Dockerfile updated to use `REDIS_PASSWORD` env var. |
| 7 | `security-tooling/docker-compose.yml` | ES healthcheck used HTTP without auth on 8.x (would always fail → Kibana + Logstash never start) | Fixed to `curl -sf http://localhost:9200/_cluster/health` — works for 7.x (no auth) |
| 8 | `security-tooling/kibana/Dockerfile` | Kibana had Railway-only `siem.railway.internal` DNS hardcoded — breaks all non-Railway deploys | Retained for Railway builds; `docker-compose.yml` for local builds uses `ELASTICSEARCH_HOSTS=http://elasticsearch:9200` directly |
| 9 | `ansible/site.yml` | Duplicate roles/post_tasks block in "Deployment Summary" play — all roles executed twice | Removed the entire duplicate block (lines 277–368). Cleaned up duplicate `run_once`/`tags` declarations. |
| 10 | `security-tooling/docker-compose.yml` | Redis healthcheck ran without `--requirepass` — would always report unhealthy | Fixed: `redis-cli -a ${REDIS_PASSWORD} --no-auth-warning ping` |

### Medium Severity Fixes

| # | File(s) | Issue | Fix Applied |
|---|---------|-------|-------------|
| 11 | `security-tooling/elk/logstash.conf` | Dangling Sysmon/Windows/Linux/DNS filter content appended after a valid `output {}` block — malformed Logstash config with two output blocks | Trimmed dangling content (lines 153–387). Moved to proper `elk/logstash-sysmon.conf` pipeline. |
| 12 | `security-tooling/elk/logstash.conf` | `stdout { codec => rubydebug }` in production output — massive log volume, performance hit | Removed stdout output entirely from main pipeline |
| 13 | `security-tooling/elk/logstash.conf` | `ssl_certificate_verification => false` on Elasticsearch output — unnecessary since ES 7.17 has SSL disabled by default in lab | Removed SSL directives from output block |
| 14 | `ansible/roles/siem-agent/templates/` | Templates `filebeat.yml.j2`, `auditbeat.yml.j2`, `rsyslog-forward.conf.j2` referenced but didn't exist — role would fail on first Linux host | Created all three templates with full configuration |
| 15 | `ansible/roles/siem-agent/defaults/main.yml` `ansible/roles/siem-agent/tasks/linux.yml` | Beat versions set to `8.9.1` and Elastic apt repo pointed at `8.x` — mismatched with 7.17.23 ELK stack | Downgraded to `7.17.23` and repo to `7.x` |
| 16 | `terraform/vms.tf` (multiple) | `file("~/.ssh/id_rsa.pub")` — plan fails if key doesn't exist; no fallback | Replaced with `fileexists(var.ssh_public_key_path) ? file(...) : ""`. Added `ssh_public_key_path` variable. |
| 17 | `deception-layer/opencanary/opencanary.conf` | Config used INI-format mixed with Python dict syntax — OpenCanary expects JSON | Rewrote as valid JSON |

### Other Fixes

| # | File(s) | Issue | Fix Applied |
|---|---------|-------|-------------|
| 18 | `ansible/site.yml` | All `gather_facts: yes` / `become: yes` used YAML 1.1 boolean strings — strict validators reject these | Replaced all with `true` |
| 19 | `ansible/playbooks/verify-active-directory.yml` | Accidental `1---` at line 1 (IDE keystroke); also `gather_facts: yes` | Fixed document start marker; replaced `yes` with `true` |
| 20 | `terraform/vms.tf` `terraform/networks.tf` | Azure VM resources had severed resource headers (opening `resource "..."` lines missing) — would cause parse errors | Reconstructed complete resources in `vms-azure.tf` and `networks-azure.tf` with proper count guards |
| 21 | `terraform/variables.tf` | Missing variables: `azure_subscription_id`, `azure_location`, `azure_resource_group`, `ssh_public_key_path`, `server_vm_size`, `siem_vm_size`, `caldera_vm_size`, `endpoint_vm_size`, `linux_image_publisher`, `linux_image_offer` | Added all missing variables with sensible defaults |

---

## New Files Created

| File | Purpose |
|------|---------|
| `terraform/azure-base.tf` | Azure resource group + VNet + subnets (conditional on `azure_subscription_id`) |
| `terraform/vms-azure.tf` | Azure VM definitions with count guards (extracted from `vms.tf`) |
| `terraform/networks-azure.tf` | Azure NSG definitions with count guards + subnet associations (extracted from `networks.tf`) |
| `security-tooling/elk/logstash-sysmon.conf` | Proper Logstash pipeline for Sysmon/Windows/Linux/DNS events |
| `security-tooling/elk/patterns/sysmon.grok` | Custom Grok patterns for Sysmon event parsing |
| `security-tooling/.env.example` | Template for docker-compose secrets — copy to `.env` and set values |
| `ansible/roles/siem-agent/templates/filebeat.yml.j2` | Filebeat config template |
| `ansible/roles/siem-agent/templates/auditbeat.yml.j2` | Auditbeat config template |
| `ansible/roles/siem-agent/templates/rsyslog-forward.conf.j2` | rsyslog forwarding config template |

---

## Deployment Status

| Component | Status |
|-----------|--------|
| ELK Stack (Railway) | **VERIFIED HEALTHY** — all 7 services SUCCESS as of 2026-03-21 |
| Docker Compose (local) | Fixed — aligned with 7.17.23 Dockerfiles |
| Terraform (Hyper-V) | Fixed — local function calls, no Azure provider requirement |
| Terraform (Azure) | Fixed — conditional deployment via `azure_subscription_id` variable |
| Ansible | Fixed — invalid module, duplicate blocks, missing templates |
| Deception Layer | Fixed — OpenCanary config now valid JSON |
| SIEM Agents | Fixed — Beat versions aligned with ELK 7.17.23 |

### Railway Service Health (2026-03-21)

| Service | Status | Notes |
|---------|--------|-------|
| Elasticsearch | SUCCESS | Cluster healthy, GeoIP loaded, Kibana indices created |
| Kibana | SUCCESS | Connected to `siem.railway.internal:9200`, UI available |
| Logstash | SUCCESS | Pipelines running, listening on 514 (syslog) + 5000 (Beats) |
| Redis | SUCCESS | Cache operational |
| OpenCanary | SUCCESS | Honeypot services active |
| Cowrie | SUCCESS | SSH/Telnet honeypot active |
| HoneyPod (root) | SUCCESS | nginx status page — fixed via root Dockerfile |

---

## Planned Work

### Phase 2 (Q2 2026)

- [ ] Multi-hypervisor failover (HA)
- [ ] T-Pot deployment (20+ honeypots)
- [ ] SOAR integration (automated playbooks)
- [ ] EDR integration (Defender for Endpoint)
- [ ] Purple team scenarios

### Phase 3 (Q3 2026)

- [ ] Machine learning anomaly detection
- [ ] Continuous automated exercise mode
- [ ] External red team API integration

### Phase 4 (Q4 2026)

- [ ] OT/IoT simulation
- [ ] Advanced persistence scenarios (bootkit, firmware)
- [ ] Post-compromise forensics (memory, disk imaging)

---

---

## 2026-03-21 — Railway Deployment Verification

### Issues Found & Fixed During Verification

| # | Service | Issue | Fix |
|---|---------|-------|-----|
| 22 | Kibana (Railway) | `ELASTICSEARCH_HOSTS` env var still pointed to `elasticsearch.railway.internal` (old DNS) — Railway vars override Dockerfile ENV | Updated Railway variable to `http://siem.railway.internal:9200` via CLI |
| 23 | Logstash (Railway) | `stdout { codec => rubydebug }` left in `security-tooling/logstash/logstash.conf` — massive log volume in production | Removed stdout output block; committed as `e5a3847` |
| 24 | HoneyPod root service | No Dockerfile at repo root — Railway Railpack could not detect build target; service failing since day 1 | Added root `Dockerfile` (nginx serving `docs/status.html` status page) |
| 25 | Logstash (Railway) | XPack license checker trying `http://elasticsearch:9200/` (docker-compose hostname) — not resolvable in Railway | Set `XPACK_MONITORING_ENABLED=false` Railway env var |

### Verification Results

- All 7 Railway services confirmed `SUCCESS`
- Kibana UI accessible at `kibana-production-4b54.up.railway.app`
- Logstash pipeline running clean — no errors
- Elasticsearch cluster healthy with GeoIP databases loaded

*Last updated: 2026-03-21*
