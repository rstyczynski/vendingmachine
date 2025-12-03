# Resource Dependencies Guide

This document explains the dependency structure for OCI Vending Machine resources, based on `resource_dependencies.yaml`.

## Quick Reference

### Compute Instance
**To create a compute instance, you need:**

**Mandatory:**
- ✅ Tenancy
- ✅ Region  
- ✅ Compartment
- ✅ Zone (which contains subnet)

**Optional:**
- 🔹 NSG (Network Security Groups) - for firewall rules

**Example:**
```yaml
compute_instance:
  mandatory: [tenancy, region, compartment, zone]
  optional: [nsg]
```

### VCN (Virtual Cloud Network)
**To create a VCN, you need:**

**Mandatory:**
- ✅ Compartment

**Optional:**
- 🔹 Internet Gateway - for public internet access
- 🔹 NAT Gateway - for private subnet internet access  
- 🔹 Service Gateway - for OCI services access

**Example:**
```yaml
vcn:
  mandatory: [compartment]
  optional: [internet_gateway, nat_gateway, service_gateway]
```

### Subnet
**To create a subnet, you need:**

**Mandatory:**
- ✅ Compartment
- ✅ VCN

**Optional:**
- 🔹 Log Group - for VCN flow logs (if `enable_flow_log = true`)
- 🔹 Route Table - from VCN gateways (if using NAT/Service Gateway)

**Example:**
```yaml
subnet:
  mandatory: [compartment, vcn]
  optional: [log_group, route_table]
```

## Common Patterns

### Minimal Compute Setup
```
tenancy → region → compartment → vcn → subnet → zone → compute_instance
```

### Compute with Security
```
tenancy → region → compartment → vcn → subnet → zone → compute_instance
                                    ↓
                                  nsg (optional)
```

### Private Compute with NAT
```
tenancy → region → compartment → vcn (with NAT gateway) → subnet (with route table) → zone → compute_instance
```

### Compute with Logging
```
tenancy → region → compartment → log_group → vcn → subnet (with flow logs) → zone → compute_instance
```

## Dependency Resolution Order

Resources must be created in this order:

1. **Foundation**: `tenancy`, `region`
2. **Identity**: `compartment`
3. **Logging**: `log_group` (optional)
4. **Network**: `vcn` → `subnet`, `nsg`
5. **Logical**: `zone` (references subnet)
6. **Compute**: `compute_instance` (references zone)
7. **Security**: `bastion` (references subnet)

## FQRN Schemes

Each resource has a specific FQRN scheme:

- `tenancy://oc1/{name}`
- `region://oc1/{region_name}`
- `cmp:///{compartment_path}`
- `log_group://{compartment_path}/{name}`
- `vcn://{compartment_path}/{vcn_name}`
- `sub://{compartment_path}/{vcn_name}/{subnet_name}`
- `nsg://{compartment_path}/{vcn_name}/{nsg_name}`
- `zone://{compartment_path}/{zone_name}`
- `instance://{compartment_path}/{instance_name}`
- `bastion://{compartment_path}/{bastion_name}`

## Usage

When adding a new resource, check `resource_dependencies.yaml` to see:
- What mandatory dependencies are required
- What optional dependencies are available
- What the resource provides (outputs)

This helps ensure all prerequisites are met before creating the resource.

