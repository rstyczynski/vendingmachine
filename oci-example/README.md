# OCI Vending Machine - FQRN Pattern Example

This example demonstrates the OCI Vending Machine pattern using **FQRNs (Fully Qualified Resource Names)** for resource mapping and dynamic aggregation.

## Key Innovation: FQRN-Based Resource Mapping

**Instead of passing OCIDs directly, we use FQRNs throughout the stack:**

```hcl
# ❌ OLD WAY: Pass OCIDs directly
compartment_id = module.compartments["demo"].id
vcn_id         = module.vcns["demo_vcn"].id
subnet_id      = module.subnets["public_subnet"].id

# ✅ NEW WAY: Pass FQRNs + aggregated FQRN map
compartment_fqrn = "cmp://demo"
vcn_fqrn         = "vcn://demo/demo_vcn"
fqrn_map         = local.compartment_and_vcn_fqrns  # Auto-resolves FQRNs → OCIDs
```

## Architecture: Layered FQRN Aggregation

Resources are created in dependency layers. Each layer:
1. Receives FQRNs from configuration
2. Receives aggregated FQRN map from previous layers
3. Resolves FQRNs to OCIDs internally
4. Outputs new FQRN → OCID mappings
5. Maps are aggregated for next layer

```
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 1: Compartments                                                    │
├─────────────────────────────────────────────────────────────────────────┤
│ Input:  none                                                             │
│ Output: local.compartment_fqrns = { "cmp://demo" => "ocid1.cmp..." }   │
└─────────────────────────────────────────────────────────────────────────┘
                                   ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 2: VCNs                                                            │
├─────────────────────────────────────────────────────────────────────────┤
│ Input:  compartment_fqrn = "cmp://demo"                                 │
│         fqrn_map = local.compartment_fqrns  ← Layer 1 map               │
│ Resolve: "cmp://demo" → OCID via local.compartment_fqrns                │
│ Output: local.vcn_fqrns = { "vcn://demo/demo_vcn" => "ocid1.vcn..." }   │
└─────────────────────────────────────────────────────────────────────────┘
                                   ↓
          local.compartment_and_vcn_fqrns = merge(Layer 1, Layer 2)
                                   ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 3: Subnets                                                         │
├─────────────────────────────────────────────────────────────────────────┤
│ Input:  compartment_fqrn = "cmp://demo"                                 │
│         vcn_fqrn = "vcn://demo/demo_vcn"                                │
│         fqrn_map = local.compartment_and_vcn_fqrns  ← Layer 1+2 map     │
│ Resolve: FQRNs → OCIDs via local.compartment_and_vcn_fqrns              │
│ Output: local.subnet_fqrns = {                                           │
│           "sub://demo/demo_vcn/public_subnet" => "ocid1.subnet..."      │
│         }                                                                │
└─────────────────────────────────────────────────────────────────────────┘
                                   ↓
       local.compartment_vcn_subnet_fqrns = merge(Layer 1, Layer 2, Layer 3)
                                   ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 3.5: Network Security Groups (NSGs)                               │
├─────────────────────────────────────────────────────────────────────────┤
│ Input:  compartment_fqrn = "cmp://demo"                                 │
│         vcn_fqrn = "vcn://demo/demo_vcn"                                │
│         fqrn_map = local.compartment_vcn_subnet_fqrns  ← Layer 1+2+3 map│
│ Resolve: FQRNs → OCIDs via local.compartment_vcn_subnet_fqrns           │
│ Output: local.nsg_fqrns = {                                              │
│           "nsg://demo/demo_vcn/ssh" => "ocid1.nsg..."                   │
│         }                                                                │
└─────────────────────────────────────────────────────────────────────────┘
                                   ↓
              local.network_fqrns = merge(Layer 1, Layer 2, Layer 3, Layer 3.5)
                                   ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ LAYER 4: Compute Instances                                               │
├─────────────────────────────────────────────────────────────────────────┤
│ Input:  zone = {                                                         │
│           compartment = "cmp://demo"                                     │
│           subnet = "sub://demo/demo_vcn/public_subnet"                  │
│           nsg = ["nsg://demo/demo_vcn/public_subnet-nsg-ssh"]           │
│         }                                                                │
│         fqrn_map = local.network_fqrns  ← Layer 1+2+3 map               │
│ Resolve: All FQRNs → OCIDs via local.network_fqrns                      │
│ Output: local.compute_instance_fqrns = {                                 │
│           "instance://demo/demo_instance" => "ocid1.instance..."        │
│         }                                                                │
└─────────────────────────────────────────────────────────────────────────┘
                                   ↓
      output.fqrn_map = merge(all layers) → Unified FQRN → OCID map
```

## Module Pattern: FQRN Resolution

Each module follows this pattern:

```hcl
# Module receives FQRNs + FQRN map
variable "compartment_fqrn" { type = string }
variable "vcn_fqrn" { type = string }
variable "fqrn_map" { type = map(string) }

# Module resolves FQRNs to OCIDs internally
locals {
  compartment_id = var.fqrn_map[var.compartment_fqrn]
  vcn_id         = var.fqrn_map[var.vcn_fqrn]
}

# Module uses OCIDs for OCI resources
resource "oci_core_subnet" "this" {
  compartment_id = local.compartment_id
  vcn_id         = local.vcn_id
  # ...
}

# Module outputs new FQRN mappings
output "fqrn_map" {
  value = {
    "sub://.../${self.display_name}" = self.id
  }
}
```

## What This Creates

1. ✅ **Compartment** (`cmp://demo`)
2. ✅ **VCN with Internet Gateway** (`vcn://demo/demo_vcn`)
3. ✅ **Subnet** (`sub://demo/demo_vcn/public_subnet`)
4. ✅ **Network Security Group with SSH access** (`nsg://demo/demo_vcn/ssh`)
5. ✅ **Compute Instance** (`instance://demo/demo_instance`)

## Configuration Example (terraform.tfvars)

```hcl
# VCNs reference compartments via FQRN
vcns = {
  demo_vcn = {
    compartment_fqrn = "cmp://demo"  # FQRN reference
    cidr_blocks      = ["10.0.0.0/16"]
  }
}

# Subnets reference compartments + VCNs via FQRN
subnets = {
  public_subnet = {
    compartment_fqrn = "cmp://demo"             # FQRN reference
    vcn_fqrn         = "vcn://demo/demo_vcn"    # FQRN reference
    cidr_block       = "10.0.1.0/24"
  }
}

# NSGs reference compartments + VCNs via FQRN (application-owned security)
nsgs = {
  ssh = {
    compartment_fqrn = "cmp://demo"             # FQRN reference
    vcn_fqrn         = "vcn://demo/demo_vcn"    # FQRN reference
    rules = {
      ssh_ingress = {
        direction   = "INGRESS"
        protocol    = "6"  # TCP
        source      = "0.0.0.0/0"
        tcp_options = {
          destination_port_min = 22
          destination_port_max = 22
        }
      }
    }
  }
}

# Zones define WHERE resources will be placed (external map pattern)
zones = {
  app = {
    compartment = "cmp://demo"
    subnet      = "sub://demo/demo_vcn/public_subnet"
    nsg         = ["nsg://demo/demo_vcn/ssh"]
    ad          = 0
  }
}

# Compute instances reference zone by name
compute_instances = {
  demo_instance = {
    zone = "app"  # Zone map key reference
    spec = {
      ocpus          = 1
      memory_in_gbs  = 16
      ssh_public_key = "ssh-rsa AAAAB3..."
    }
  }
}
```

## Quick Start

```bash
cd oci-example

# 1. Configure
cp terraform.tfvars.example terraform.tfvars
vi terraform.tfvars  # Add your OCI credentials and SSH key

# 2. Deploy
terraform init
terraform plan
terraform apply

# 3. View unified FQRN map
terraform output fqrn_map

# Output:
# {
#   "cmp://demo" = "ocid1.compartment.oc1..aaaa..."
#   "vcn://demo/demo_vcn" = "ocid1.vcn.oc1.iad.aaaa..."
#   "sub://demo/demo_vcn/public_subnet" = "ocid1.subnet.oc1.iad.aaaa..."
#   "nsg://demo/demo_vcn/ssh" = "ocid1.nsg.oc1.iad.aaaa..."
#   "instance://demo/demo_instance" = "ocid1.instance.oc1.iad.aaaa..."
# }

# 4. SSH to instance
ssh opc@$(terraform output -json compute_instances | jq -r '.demo_instance.public_ip')
```

## Key Benefits

### 1. Human-Readable Configuration
```hcl
# Clear intent - no OCIDs to track
compartment_fqrn = "cmp://demo"
vcn_fqrn         = "vcn://demo/demo_vcn"
```

### 2. Automatic Same-Session Resolution
Resources created in the same Terraform session are automatically resolvable:
- Layer 1 creates compartments → outputs FQRN map
- Layer 2 resolves compartment FQRNs using Layer 1 map
- Layer 3 resolves compartment + VCN FQRNs using Layer 1+2 map
- Layer 4 resolves all FQRNs using complete map

### 3. Zone Pattern (External Map + Reference by Name)
Follows vending machine 4-domain model:
```hcl
# Define zones as external map (reusable location contexts)
zones = {
  app = {                           # WHERE (location context)
    compartment = "cmp://..."
    subnet      = "sub://..."
    nsg         = ["nsg://..."]
    ad          = 0
  }
}

# Compute instances reference zone by name
compute_instances = {
  demo_instance = {
    zone = "app"                    # Zone map key reference
    spec = {                        # WHAT (feature specification)
      shape     = "..."
      ocpus     = 1
      ssh_key   = "..."
    }
  }
}
```

### 4. Composable and Scalable
```hcl
# Add more resources - just reference zone by name
compute_instances = {
  web_server = {
    zone = "app"  # Reuse existing zone definition
    spec = { ocpus = 2, memory_in_gbs = 32, ssh_public_key = "..." }
  }
  api_server = {
    zone = "app"  # Multiple instances can share same zone
    spec = { ocpus = 4, memory_in_gbs = 64, ssh_public_key = "..." }
  }
}
```

## Directory Structure

```
oci-example/
├── modules/
│   ├── compartment/         # Outputs: cmp:// FQRNs
│   ├── vcn/                 # Receives: compartment FQRNs
│   │                        # Outputs: vcn:// FQRNs
│   ├── subnet/              # Receives: compartment + VCN FQRNs
│   │                        # Outputs: sub:// FQRNs
│   ├── nsg/                 # Receives: compartment + VCN FQRNs
│   │                        # Outputs: nsg:// FQRNs (application-scoped security)
│   └── compute_instance/    # Receives: all network FQRNs (zone pattern)
│                            # Outputs: instance:// FQRNs
├── main.tf                  # Layered module calls + FQRN aggregation
├── locals.tf                # Final unified FQRN map
├── outputs.tf               # Unified FQRN → OCID output
└── terraform.tfvars         # FQRN-based configuration
```

## References

- [FQRN.md](../FQRN.md) - FQRN specification and Pattern 3 aggregation
- [NSG.md](../NSG.md) - Network Security Groups architecture and ownership model
- [CLAUDE.md](../CLAUDE.md) - OCI Vending Machine architecture
- [oci-vending-machine-design v1.md](../oci-vending-machine-design%20v1.md) - Complete design

## Next Steps

1. ✅ Understand layered FQRN aggregation in `main.tf`
2. ✅ Review module FQRN resolution pattern
3. Add FQRN resolver module for existing resources
4. Implement dual-input pattern (existing vs new resources)
