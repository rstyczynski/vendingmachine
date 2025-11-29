# Network Security Groups (NSG)

## Overview

**Network Security Groups (NSGs)** are application-level security policies in OCI that provide fine-grained network access control independent of subnet boundaries.

### Key Distinction: NSG vs Security Lists

| Aspect | Security Lists | Network Security Groups (NSGs) |
|--------|---------------|-------------------------------|
| **Scope** | Subnet-level | Application/VNIC-level |
| **Ownership** | Owned by network team | Owned by application team |
| **Granularity** | All VNICs in subnet | Individual VNICs |
| **Flexibility** | Static, subnet-wide | Dynamic, per-application |
| **Use Case** | Network segmentation | Application security |
| **FQRN Pattern** | Part of subnet | Independent resource |

**Important:** NSG is application-scoped, not subnet-scoped. This allows application teams to own and manage their security rules independently of the network infrastructure.

## Architecture Pattern

### Ownership Model

```
┌─────────────────────────────────────────────────────────────┐
│ Network Team (Infrastructure)                               │
├─────────────────────────────────────────────────────────────┤
│ • Compartments                                              │
│ • VCNs                                                      │
│ • Subnets                                                   │
│ • Security Lists (baseline subnet security)                │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│ Application Team (Workload)                                 │
├─────────────────────────────────────────────────────────────┤
│ • NSGs (application-specific security)                      │
│ • Compute Instances                                         │
│ • Load Balancers                                            │
│ • Databases                                                 │
└─────────────────────────────────────────────────────────────┘
```

### Separation of Concerns

**Security Lists:**
- Managed by network/infrastructure team
- Broad subnet-level rules
- Baseline security policy
- Changes affect all VNICs in subnet

**NSGs:**
- Managed by application/workload team
- Specific application requirements
- Fine-grained access control
- Changes affect only attached VNICs

## FQRN Pattern

NSGs follow the hierarchical FQRN pattern:

```
nsg://compartment_path/vcn_name/nsg_name
```

**Example:**
```
nsg://cmp_prod/cmp_network/vcn_main/app_web_servers
nsg://cmp_prod/cmp_network/vcn_main/app_db_access
nsg://cmp_prod/cmp_app/vcn_app/microservice_api
```

### Cross-Entity Ownership

NSGs can exist in different compartments than the subnets where they're used:

```hcl
# Network team's compartment
subnets = {
  app_subnet = {
    compartment_fqrn = "cmp://shared/network"
    vcn_fqrn         = "vcn://shared/network/vcn_shared"
    cidr_block       = "10.0.1.0/24"
  }
}

# Application team's compartment
nsgs = {
  webapp_security = {
    compartment_fqrn = "cmp://team_a/application"  # Different compartment!
    vcn_fqrn         = "vcn://shared/network/vcn_shared"
    rules = { ... }
  }
}
```

## NSG Module Interface

### Variables

```hcl
variable "compartment_fqrn" {
  description = "Compartment FQRN - can be different from subnet compartment"
  type        = string
}

variable "vcn_fqrn" {
  description = "VCN FQRN - must match the VCN where NSG will be used"
  type        = string
}

variable "name" {
  description = "NSG display name"
  type        = string
}

variable "rules" {
  description = "Map of security rules"
  type        = map(object({
    direction            = string           # INGRESS or EGRESS
    protocol             = string           # "6" (TCP), "17" (UDP), "1" (ICMP), "all"
    source               = optional(string) # For INGRESS
    destination          = optional(string) # For EGRESS
    source_type          = optional(string, "CIDR_BLOCK")
    destination_type     = optional(string, "CIDR_BLOCK")
    description          = optional(string)

    tcp_options = optional(object({
      destination_port_min = optional(number)
      destination_port_max = optional(number)
      source_port_min      = optional(number)
      source_port_max      = optional(number)
    }))

    udp_options = optional(object({
      destination_port_min = optional(number)
      destination_port_max = optional(number)
      source_port_min      = optional(number)
      source_port_max      = optional(number)
    }))

    icmp_options = optional(object({
      type = number
      code = optional(number)
    }))
  }))
}
```

### Output

```hcl
output "fqrn_map" {
  value = {
    "nsg://compartment_path/vcn_name/nsg_name" = nsg_ocid
  }
}
```

## Rule Configuration

### Protocol Types

| Protocol | Value | Description |
|----------|-------|-------------|
| TCP | `"6"` | Transmission Control Protocol |
| UDP | `"17"` | User Datagram Protocol |
| ICMP | `"1"` | Internet Control Message Protocol |
| All | `"all"` | All protocols |

### Rule Directions

- **INGRESS** - Incoming traffic (requires `source`)
- **EGRESS** - Outgoing traffic (requires `destination`)

### Source/Destination Types

- **CIDR_BLOCK** - IP address range (e.g., "10.0.0.0/16", "0.0.0.0/0")
- **SERVICE_CIDR_BLOCK** - OCI service network
- **NETWORK_SECURITY_GROUP** - Another NSG OCID

## Configuration Examples

### Example 1: Web Server NSG

```hcl
nsgs = {
  web_servers = {
    compartment_fqrn = "cmp://app_team/production"
    vcn_fqrn         = "vcn://shared/network/vcn_prod"

    rules = {
      http_ingress = {
        direction   = "INGRESS"
        protocol    = "6"  # TCP
        source      = "0.0.0.0/0"
        description = "Allow HTTP from internet"
        tcp_options = {
          destination_port_min = 80
          destination_port_max = 80
        }
      }

      https_ingress = {
        direction   = "INGRESS"
        protocol    = "6"  # TCP
        source      = "0.0.0.0/0"
        description = "Allow HTTPS from internet"
        tcp_options = {
          destination_port_min = 443
          destination_port_max = 443
        }
      }

      all_egress = {
        direction   = "EGRESS"
        protocol    = "all"
        destination = "0.0.0.0/0"
        description = "Allow all outbound"
      }
    }
  }
}
```

### Example 2: Database NSG

```hcl
nsgs = {
  databases = {
    compartment_fqrn = "cmp://db_team/production"
    vcn_fqrn         = "vcn://shared/network/vcn_prod"

    rules = {
      postgres_from_app = {
        direction   = "INGRESS"
        protocol    = "6"  # TCP
        source      = "10.0.1.0/24"  # App subnet
        description = "PostgreSQL from app tier"
        tcp_options = {
          destination_port_min = 5432
          destination_port_max = 5432
        }
      }

      oracle_from_app = {
        direction   = "INGRESS"
        protocol    = "6"  # TCP
        source      = "10.0.1.0/24"  # App subnet
        description = "Oracle DB from app tier"
        tcp_options = {
          destination_port_min = 1521
          destination_port_max = 1521
        }
      }

      limited_egress = {
        direction   = "EGRESS"
        protocol    = "6"  # TCP
        destination = "0.0.0.0/0"
        description = "HTTPS for patches only"
        tcp_options = {
          destination_port_min = 443
          destination_port_max = 443
        }
      }
    }
  }
}
```

### Example 3: Microservice NSG

```hcl
nsgs = {
  api_gateway = {
    compartment_fqrn = "cmp://microservices/production"
    vcn_fqrn         = "vcn://shared/network/vcn_prod"

    rules = {
      api_ingress = {
        direction   = "INGRESS"
        protocol    = "6"  # TCP
        source      = "10.0.0.0/16"  # Internal VCN only
        description = "API access from internal network"
        tcp_options = {
          destination_port_min = 8080
          destination_port_max = 8080
        }
      }

      service_mesh = {
        direction   = "INGRESS"
        protocol    = "6"  # TCP
        source      = "10.0.2.0/24"  # Service mesh subnet
        description = "Service mesh traffic"
        tcp_options = {
          destination_port_min = 15000
          destination_port_max = 15999
        }
      }

      all_egress = {
        direction   = "EGRESS"
        protocol    = "all"
        destination = "0.0.0.0/0"
        description = "Allow all outbound"
      }
    }
  }
}
```

### Example 4: SSH Bastion NSG

```hcl
nsgs = {
  ssh_bastion = {
    compartment_fqrn = "cmp://security/operations"
    vcn_fqrn         = "vcn://shared/network/vcn_prod"

    rules = {
      ssh_from_corporate = {
        direction   = "INGRESS"
        protocol    = "6"  # TCP
        source      = "203.0.113.0/24"  # Corporate IP range
        description = "SSH from corporate network only"
        tcp_options = {
          destination_port_min = 22
          destination_port_max = 22
        }
      }

      ssh_to_internal = {
        direction   = "EGRESS"
        protocol    = "6"  # TCP
        destination = "10.0.0.0/16"  # Internal VCN
        description = "SSH to internal servers"
        tcp_options = {
          destination_port_min = 22
          destination_port_max = 22
        }
      }
    }
  }
}
```

### Example 5: ICMP (Ping) NSG

```hcl
nsgs = {
  monitoring = {
    compartment_fqrn = "cmp://operations/monitoring"
    vcn_fqrn         = "vcn://shared/network/vcn_prod"

    rules = {
      icmp_echo = {
        direction   = "INGRESS"
        protocol    = "1"  # ICMP
        source      = "10.0.0.0/16"
        description = "ICMP echo (ping) from internal network"
        icmp_options = {
          type = 8  # Echo request
          code = 0
        }
      }

      icmp_unreachable = {
        direction   = "INGRESS"
        protocol    = "1"  # ICMP
        source      = "0.0.0.0/0"
        description = "ICMP destination unreachable"
        icmp_options = {
          type = 3  # Destination unreachable
        }
      }
    }
  }
}
```

## Port Ranges

### Single Port

```hcl
tcp_options = {
  destination_port_min = 443
  destination_port_max = 443
}
```

### Port Range

```hcl
tcp_options = {
  destination_port_min = 8000
  destination_port_max = 8999
}
```

### Source Port Control

```hcl
tcp_options = {
  source_port_min      = 1024
  source_port_max      = 65535
  destination_port_min = 443
  destination_port_max = 443
}
```

## Multi-Team Workflow

### Scenario: Shared VCN, Team-Owned NSGs

```hcl
# Network Team: Creates VCN and Subnets
# Repository: infrastructure/network

compartments = {
  network = { description = "Shared network infrastructure" }
}

vcns = {
  shared_prod = {
    compartment_fqrn = "cmp://network"
    cidr_blocks      = ["10.0.0.0/16"]
  }
}

subnets = {
  app_tier = {
    compartment_fqrn = "cmp://network"
    vcn_fqrn         = "vcn://network/shared_prod"
    cidr_block       = "10.0.1.0/24"
  }
}

# Application Team A: Creates their NSG and instances
# Repository: team-a/application

nsgs = {
  team_a_web = {
    compartment_fqrn = "cmp://team_a/production"  # Own compartment!
    vcn_fqrn         = "vcn://network/shared_prod" # Shared VCN
    rules = { ... }
  }
}

zones = {
  web = {
    compartment = "cmp://team_a/production"
    subnet      = "sub://network/shared_prod/app_tier"  # Shared subnet
    nsg         = ["nsg://team_a/production/team_a_web"] # Own NSG
  }
}

# Application Team B: Creates their NSG and instances
# Repository: team-b/application

nsgs = {
  team_b_api = {
    compartment_fqrn = "cmp://team_b/production"  # Own compartment!
    vcn_fqrn         = "vcn://network/shared_prod" # Shared VCN
    rules = { ... }
  }
}

zones = {
  api = {
    compartment = "cmp://team_b/production"
    subnet      = "sub://network/shared_prod/app_tier"  # Shared subnet
    nsg         = ["nsg://team_b/production/team_b_api"] # Own NSG
  }
}
```

**Result:** Multiple teams deploy to the same subnet with independent security policies.

## Best Practices

### 1. Principle of Least Privilege

```hcl
# ❌ BAD - Too permissive
rules = {
  all_traffic = {
    direction   = "INGRESS"
    protocol    = "all"
    source      = "0.0.0.0/0"
  }
}

# ✅ GOOD - Specific ports and sources
rules = {
  https_only = {
    direction   = "INGRESS"
    protocol    = "6"
    source      = "10.0.0.0/16"  # Internal network only
    tcp_options = {
      destination_port_min = 443
      destination_port_max = 443
    }
  }
}
```

### 2. Descriptive Rule Names

```hcl
# ✅ GOOD - Clear purpose from name
rules = {
  https_from_load_balancer = { ... }
  postgres_from_app_tier   = { ... }
  prometheus_metrics       = { ... }
}
```

### 3. Egress Control

```hcl
# ✅ GOOD - Explicit egress rules
rules = {
  https_to_apis = {
    direction   = "EGRESS"
    protocol    = "6"
    destination = "0.0.0.0/0"
    description = "HTTPS to external APIs"
    tcp_options = {
      destination_port_min = 443
      destination_port_max = 443
    }
  }

  dns_lookups = {
    direction   = "EGRESS"
    protocol    = "17"  # UDP
    destination = "0.0.0.0/0"
    description = "DNS queries"
    udp_options = {
      destination_port_min = 53
      destination_port_max = 53
    }
  }
}
```

### 4. Separate NSGs by Function

```hcl
# Multiple NSGs for different purposes
zones = {
  app = {
    compartment = "cmp://team_a"
    subnet      = "sub://network/shared/app_tier"
    nsg         = [
      "nsg://team_a/web_traffic",      # HTTP/HTTPS
      "nsg://team_a/app_to_db",        # Database access
      "nsg://security/ssh_bastion"     # SSH from bastion
    ]
  }
}
```

## Integration with Vending Machine

NSGs integrate with the 4-domain model:

```
┌────────────────────┬────────────────────┬────────────────────┬─────────────────────┐
│      FEATURE       │      ZONE(S)       │    DEPLOYMENT      │      PACKAGING      │
├────────────────────┼────────────────────┼────────────────────┼─────────────────────┤
│ NSG Resource       │ compartment (owner)│ team repository    │ terraform           │
│ NSG Rules (map)    │ vcn (where used)   │ team pipeline      │                     │
│                    │                    │ team state file    │                     │
└────────────────────┴────────────────────┴────────────────────┴─────────────────────┘
```

**Key Point:** NSG deployment (ownership) can be separate from subnet deployment (network infrastructure).

## Summary

- **NSGs are application-scoped**, not subnet-scoped
- **Owned by application teams**, not network teams
- **Attached to VNICs**, not subnets
- **Independent lifecycle** from network infrastructure
- **Fine-grained control** per workload
- **FQRN-addressable** for declarative configuration
- **Map-based rules** for infrastructure-as-data pattern
