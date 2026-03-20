# SIEM Detection Rules - MITRE ATT&CK Mapped
# Environment: ELK Stack (Elasticsearch/Logstash)
# Deploy to: SIEM-LS-01 (Logstash pipeline configuration)

# For Kibana: Create saved searches and alerts from these rules
# Rules are in Elasticsearch Query DSL (KQL) and Logstash filter syntax

---
# T1566: Phishing
# Detects: Email forwarding rule creation, unusual email patterns

PUT /siem-rules-2024/doc/t1566-phishing-rule-001
{
  "rule_name": "Email Forwarding Rule Created",
  "technique": "T1566",
  "tactic": "Initial Access",
  "query": {
    "bool": {
      "must": [
        { "match": { "event.id": "4707" } },
        { "exists": { "field": "ad.forwarding_address" } }
      ],
      "must_not": [
        { "term": { "event.user": "alice.smith" } },
        { "term": { "event.user": "admin" } }
      ]
    }
  },
  "alert_level": "MEDIUM",
  "response_action": ["notify", "investigate"],
  "description": "Detects creation of email forwarding rules by non-admin users (possible T1566 phishing prep)"
}

---
# T1021.006: RDP - Lateral Movement
# Detects: Suspicious RDP connections from non-admin hosts, off-hours access

PUT /siem-rules-2024/doc/t1021-006-rdp-lateral
{
  "rule_name": "Suspicious RDP Lateral Movement",
  "technique": "T1021.006",
  "tactic": "Lateral Movement",
  "query": {
    "bool": {
      "must": [
        { "match": { "event.code": "4624" } },
        { "match": { "event.logon_type": "10" } },  // RDP logon
        { "range": { "event.time": { "gte": "03:00", "lte": "05:00" } } },
        { "term": { "event.logon_process": "seclogo" } }
      ],
      "must_not": [
        { "term": { "event.user": "alice.smith" } }
      ]
    }
  },
  "alert_level": "HIGH",
  "response_action": ["block_session", "generate_ticket"],
  "description": "RDP logon during off-hours from unexpected source"
}

---
# T1110: Brute Force
# Detects: Multiple failed login attempts within time window

PUT /siem-rules-2024/doc/t1110-brute-force
{
  "rule_name": "Brute Force Attack - Multiple Failed Logins",
  "technique": "T1110",
  "tactic": "Credential Access",
  "aggregation": {
    "field": "event.source_ip",
    "time_window": "5m",
    "threshold": 10
  },
  "query": {
    "bool": {
      "must": [
        { "match": { "event.code": "4625" } }  // Failed login (Windows Event ID 4625)
      ]
    }
  },
  "alert_level": "HIGH",
  "response_action": ["block_ip", "notify"],
  "description": "More than 10 failed login attempts in 5 minutes"
}

---
# T1484: Domain Policy Modification
# Detects: Unauthorized GPO or AD object modifications

PUT /siem-rules-2024/doc/t1484-domain-policy-mod
{
  "rule_name": "AD Group Policy Modified by Non-Admin",
  "technique": "T1484",
  "tactic": "Defense Evasion, Privilege Escalation",
  "query": {
    "bool": {
      "must": [
        { "match": { "event.code": "5136" } },  // AD object modification
        { "match": { "ad.object_type": "groupPolicyContainer" } },
        { "match": { "ad.modification_class": "gpEdit" } }
      ],
      "must_not": [
        { "terms": { "event.user": ["alice.smith", "G-IT-STAFF"] } }
      ]
    }
  },
  "alert_level": "CRITICAL",
  "response_action": ["isolate_system", "generate_ticket", "notify_soc"],
  "description": "AD Group Policy modified by non-admin (possible T1484)"
}

---
# T1078: Valid Accounts (Compromised Credentials)
# Detects: Anomalous account usage (logon from unusual location, device)

PUT /siem-rules-2024/doc/t1078-anomalous-account-usage
{
  "rule_name": "Anomalous Account Activity - Impossible Travel",
  "technique": "T1078",
  "tactic": "Defense Evasion, Persistence, Privilege Escalation, Initial Access",
  "query": {
    "bool": {
      "must": [
        { "match": { "event.code": "4624" } },
        { "range": { "event.logon_time_delta_seconds": { "lt": 300 } } }  // Same user, different IP within 5 min
      ]
    }
  },
  "alert_level": "MEDIUM",
  "response_action": ["notify", "investigate"],
  "description": "Same user logged in from geographically impossible locations within 5 min"
}

---
# T1087: Account Discovery
# Detects: Enumeration of accounts, groups, domain info

PUT /siem-rules-2024/doc/t1087-account-discovery
{
  "rule_name": "Excessive AD Enumeration Activity",
  "technique": "T1087",
  "tactic": "Discovery",
  "aggregation": {
    "field": "event.source_process",
    "time_window": "10m",
    "threshold": 100
  },
  "query": {
    "bool": {
      "must": [
        { "match": { "event.code": "4662" } },  // AD object access
        { "terms": { "ad.operation": ["Query", "Enumerate", "Search"] } }
      ]
    }
  },
  "alert_level": "MEDIUM",
  "response_action": ["notify", "investigate"],
  "description": "Excessive AD enumeration queries (possible T1087 discovery)"
}

---
# T1040: Network Sniffing
# Detects: Promiscuous mode, packet capture tools, unusual protocols

PUT /siem-rules-2024/doc/t1040-network-sniffing
{
  "rule_name": "Process Running in Promiscuous Mode",
  "technique": "T1040",
  "tactic": "Discovery, Credential Access",
  "query": {
    "bool": {
      "must": [
        { "match": { "process.name": ["tcpdump", "wireshark", "windump", "Wireshark.exe", "tcpdump.exe"] } }
      ],
      "must_not": [
        { "term": { "event.user": "alice.smith" } }
      ]
    }
  },
  "alert_level": "HIGH",
  "response_action": ["terminate_process", "notify"],
  "description": "Packet capture tool detected running as non-admin"
}

---
# T1043: Commonly Used Port (Exfiltration)
# Detects: Large data transfers on unusual ports, DNS tunneling

PUT /siem-rules-2024/doc/t1043-dns-tunneling
{
  "rule_name": "DNS Tunneling Detection",
  "technique": "T1043",
  "tactic": "Exfiltration",
  "query": {
    "bool": {
      "must": [
        { "match": { "dns.query_type": "TXT" } },
        { "range": { "dns.query_length": { "gt": 100 } } },
        { "range": { "dns.queries_per_second": { "gt": 10 } } }
      ]
    }
  },
  "alert_level": "MEDIUM",
  "response_action": ["block_dns", "notify"],
  "description": "Possible DNS tunneling detected (large TXT queries, high QPS)"
}

---
# T1548: Privilege Escalation
# Detects: Use of UAC bypass, privilege escalation tools

PUT /siem-rules-2024/doc/t1548-privesc
{
  "rule_name": "Privilege Escalation Attempt",
  "technique": "T1548",
  "tactic": "Privilege Escalation",
  "query": {
    "bool": {
      "must": [
        { "terms": { "process.name": ["uac-bypass", "bypassuac", "elevate", "runas.exe", "powershell.exe"] } },
        { "match": { "process.command_line": "*-Verb runAs*" } }
      ]
    }
  },
  "alert_level": "HIGH",
  "response_action": ["notify", "investigate"],
  "description": "Privilege escalation tool or technique detected"
}

---
# T1047: Windows Management Instrumentation (WMI) Command Execution
# Detects: WMI process exec, unusual WMI activity

PUT /siem-rules-2024/doc/t1047-wmi-exec
{
  "rule_name": "Suspicious WMI Command Execution",
  "technique": "T1047",
  "tactic": "Execution",
  "query": {
    "bool": {
      "must": [
        { "match": { "process.parent": "WmiPrvSE.exe" } },
        { "exists": { "field": "process.command_line" } },
        { "range": { "process.command_line_length": { "gt": 200 } } }
      ],
      "must_not": [
        { "term": { "event.user": "alice.smith" } }
      ]
    }
  },
  "alert_level": "MEDIUM",
  "response_action": ["quarantine_process", "notify"],
  "description": "WMI spawned unusual process with long command line (possible T1047)"
}

---
# T1003: OS Credential Dumping
# Detects: LSASS access, SAM registry access, credential dumping tools

PUT /siem-rules-2024/doc/t1003-cred-dump
{
  "rule_name": "Credential Dumping Attempt",
  "technique": "T1003",
  "tactic": "Credential Access",
  "query": {
    "bool": {
      "must": [
        { "terms": { "process.name": ["mimikatz.exe", "hashcat.exe", "Invoke-Mimikatz", "procdump.exe", "lsass"] } }
      ],
      "should": [
        { "match": { "file.access": "lsass.exe" } },
        { "match": { "registry.key": "*\\SAM\\*" } }
      ],
      "minimum_should_match": 1
    }
  },
  "alert_level": "CRITICAL",
  "response_action": ["quarantine_process", "isolate_system", "generate_ticket"],
  "description": "Credential dumping tool detected (possible T1003)"
}

---
# Deception Layer Alerts (MITRE Engage Mapping)
# T-Code: Any technique that interacts with honeypot

PUT /siem-rules-2024/doc/deception-honeypot-interaction
{
  "rule_name": "Honeypot/Canary Interaction Detected",
  "engagement_tactic": "MITRE Engage - Expose, Monitor, Deceive",
  "query": {
    "bool": {
      "must": [
        { "match": { "source": "opencanary" } }
      ]
    }
  },
  "alert_level": "HIGH",
  "response_action": ["generate_case", "log_ttp", "enable_full_packet_capture"],
  "description": "Adversary engaged with deception asset. Full packet capture and TTP logging enabled. Case created for analysis."
}

---
# D3FEND Mapping Example: Detect (T1566 → Phishing Detection)
# Links ATT&CK technique to D3FEND defensive technique

PUT /siem-rules-2024/doc/d3fend-mapping-t1566
{
  "attack_technique": "T1566",
  "attack_name": "Phishing",
  "d3fend_technique": "D3FEND:DA-0003",
  "d3fend_name": "Email Analysis",
  "defensive_methods": [
    "DA-0003-email-content-inspection",
    "DA-0003-email-url-extraction",
    "DA-0003-sender-verification"
  ],
  "detection_rules": [
    "t1566-phishing-rule-001"
  ],
  "response_playbook": "playbook-phishing-response-v2"
}
