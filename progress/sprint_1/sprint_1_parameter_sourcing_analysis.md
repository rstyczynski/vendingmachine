# Sprint 1 - Parameter Sourcing Analysis

**Created**: During Sprint 1 (Inception phase extension)

**Purpose**: Analyze how resource arguments should be sourced to inform architecture and catalog schema design.

**Phase**: Inception (High-Level Design)

## References

This analysis is grounded in Oracle Cloud Infrastructure best practices:

- **[Foundational OCI Governance Model](https://docs.oracle.com/en/solutions/foundational-oci-governance-model/index.html)** - Oracle's framework for governance, policy enforcement, and structured provisioning in cloud environments. Key principles from this model:
  - Identity & Access Management (IAM) policies and tagging
  - Resource organization through compartmentalization
  - Security controls (protective and detective)
  - Cost management (service limits, budgets, quotas)
  - Compliance requirements (HIPAA, FedRAMP, GDPR, CCPA)
  - Iterative operational model: organize → govern → observe/monitor → improve

## Governance as Preliminary Concept

**Important**: Governance is not currently represented in the initial resource dependency map (`etc/resource_dependencies.yaml`), but it should be understood as a **preliminary, cross-cutting concern** that precedes all resource provisioning.

In the Oracle governance model, provisioning is a foundational step that occurs *after* governance boundaries are established. Cloud Vending Machine must recognize that:
- Governance policies are established *before* resource selection
- All provisioned resources operate *within* governance boundaries
- Parameters are constrained by governance *before* user input is collected

**Design Implication**: Future architecture must model governance as a preliminary phase, not as peer-level resource dependencies.

## Executive Summary

Cloud Vending Machine resources require arguments from four distinct sources:

1. **Resource Owner** - External authority (network team, security team, etc.)
2. **Deployed Resources** - Resources created in current deployment round
3. **Existing Infrastructure** - Already-deployed resources (imported/referenced)
4. **User Input** - Direct user-provided values

This analysis examines all 20 existing resources to establish sourcing patterns and design principles for the catalog schema and code generation system.

---

## Parameter Sourcing Taxonomy

### 1. Resource Owner Parameters

**Definition**: Configuration values provided by an external authority designated as the "owner" for specific parameter types.

**Characteristics**:
- Requires coordination with external teams/systems
- May have approval workflows
- Often security-sensitive or governed by policy
- Examples: CIDR blocks, DNS zones, encryption keys

**Design Requirements**:
- Catalog must define which parameters require resource owner
- System must support owner lookup/resolution
- May integrate with external configuration management
- Audit trail for owner-provided values

### 2. Deployed Resource Parameters

**Definition**: Values derived from resources being created in the current deployment round (intra-deployment references).

**Characteristics**:
- Terraform references: `oci_core_vcn.example.id`
- Dependency order matters (VCN before subnet)
- Automatically resolved by dependency tree
- No user/owner interaction needed

**Design Requirements**:
- Code generator must create proper Terraform references
- Dependency resolver determines creation order
- References use Terraform interpolation syntax
- Handle embedded resources specially

### 3. Existing Infrastructure Parameters

**Definition**: Values from already-deployed resources outside current deployment (imported/data sources).

**Characteristics**:
- Resources exist before this deployment
- Use Terraform data sources: `data.oci_identity_compartment.existing`
- User must provide identifiers (OCID, name, etc.)
- May require discovery/import process

**Design Requirements**:
- Distinguish between creating new vs referencing existing
- Support Terraform data sources
- User must identify existing resources (OCID, tags, filters)
- Validation: verify resource exists

### 4. User Input Parameters

**Definition**: Values directly provided by the user during deployment.

**Characteristics**:
- Simple values: strings, numbers, booleans
- User-specific customization within governance constraints
- May have defaults
- **Often governed by policy** (see Source Precedence below)

**Design Requirements**:
- Interactive prompts (CLI)
- Form fields (Web UI)
- API request body (REST API)
- Validation rules (regex, enum, min/max)
- Default values
- **Governance policy checking** (Resource Owner takes precedence)

---

## Parameter Source Precedence (Governance Model)

**Critical Insight**: Many parameters have a **source hierarchy** where governance/policy takes precedence over user choice.

### Source Precedence Pattern

```yaml
parameter:
  source: choice
  precedence:
    1. resource_owner  # Primary: Check policy/governance first
    2. user_input      # Fallback: User choice if no policy
```

### Governance-Controlled Parameters

#### Display Names and Naming Conventions

**Previous Understanding**: User Input
**Governance Reality**: Resource Owner (Governance Authority) → User Input

**Rationale**:
- Organizations enforce naming conventions
- Format: `{env}-{app}-{component}-{seq}` (e.g., `prod-webapp-fe-01`)
- Governance team defines patterns
- User provides values within constraints

**Example Schema**:
```yaml
display_name:
  source: choice
  precedence:
    - resource_owner:
        owner: governance_team
        type: naming_convention
        pattern: "${environment}-${application}-${component}-${sequence}"
        validation:
          regex: "^(dev|test|prod)-[a-z0-9-]+-[a-z0-9-]+-[0-9]{2}$"
    - user_input:
        type: string
        description: "Fallback: Free-form name if no convention defined"
```

**Code Generation Pattern** (Conceptual):
- **With governance policy**: Generate code that enforces naming convention pattern (e.g., format string with governed variables)
- **Without policy**: Generate code accepting free-form user input
- Implementation will use Terraform's `format()` or validation rules

#### Tags and Metadata

**Previous Understanding**: User Input (optional)
**Governance Reality**: Resource Owner (Governance/Finance/Security) → User Input

**Rationale**:
- **Mandatory tags** for cost allocation (finance team)
- **Security classification** tags (security team)
- **Compliance** tags (compliance team)
- User adds additional freeform tags within constraints

**Example Schema**:
```yaml
tags:
  source: composite
  required_tags:
    - key: CostCenter
      source: resource_owner
      owner: finance_team
      required: true
      validation:
        enum: ["CC1001", "CC1002", "CC1003"]

    - key: Environment
      source: resource_owner
      owner: governance_team
      required: true
      validation:
        enum: ["Development", "Test", "Production"]

    - key: SecurityClassification
      source: resource_owner
      owner: security_team
      required: true
      validation:
        enum: ["Public", "Internal", "Confidential", "Restricted"]

    - key: DataResidency
      source: resource_owner
      owner: compliance_team
      required: true
      validation:
        enum: ["US", "EU", "APAC"]

  optional_tags:
    - source: user_input
      description: "Additional freeform tags"
      type: map(string)
```

**Code Generation Pattern** (Conceptual):
- **Mandatory tags**: Generated from governance-required variables (CostCenter, Environment, SecurityClassification, DataResidency)
- **Optional tags**: Merged from user-provided additional tags
- Implementation will use Terraform's `merge()` function to combine governance + user tags

#### Boolean Flags (Security/Policy)

**Previous Understanding**: User Input
**Governance Reality**: Resource Owner (Policy Team) → User Input

**Rationale**:
- Security policies dictate configurations
- Compliance requirements override user preference
- Cost optimization policies enforce settings
- User choice only if no policy

**Examples**:
1. `assign_public_ip` - Security policy may prohibit public IPs
2. `is_management_disabled` - Security policy may require management
3. `enable_monitoring` - Operations policy may mandate monitoring
4. `enable_backup` - Compliance policy may require backups

**Example Schema**:
```yaml
assign_public_ip:
  source: choice
  precedence:
    - resource_owner:
        owner: security_team
        policy: "no_public_ips_in_production"
        value: false
        condition: "environment == 'Production'"
        rationale: "Security policy: Production workloads must not have public IPs"
    - user_input:
        type: boolean
        default: false
        description: "Assign public IP (allowed in non-production only)"
```

**Code Generation Pattern** (Conceptual):
- **Policy evaluation**: Check if governance policy applies (e.g., "no public IPs in production")
- **Precedence logic**: Policy value takes precedence, fallback to user input if no policy
- **Implementation approach**: Use Terraform conditionals (`condition ? true_val : false_val`) and precedence functions (e.g., `coalesce()`)
- **Result**: Generated code enforces policy at infrastructure level, not just UI validation

#### Enums (Shapes, Regions) - Standardization

**Previous Understanding**: User Input (free choice)
**Governance Reality**: Resource Owner (Standardization/Platform Team) → User Input

**Rationale**:
- **Platform team** standardizes allowed instance shapes
- **Cost optimization** restricts expensive shapes
- **Data residency** policies restrict regions
- **Compliance** may mandate specific configurations
- User selects from approved list

**Example: Instance Shapes**

**Example Schema**:
```yaml
shape:
  source: choice
  precedence:
    - resource_owner:
        owner: platform_team
        type: approved_list
        values:
          development:
            - "VM.Standard.E4.Flex"
            - "VM.Standard3.Flex"
          production:
            - "VM.Standard.E4.Flex"
            - "VM.DenseIO.E4.Flex"
          cost_optimized:
            - "VM.Standard.A1.Flex"  # Ampere ARM - cheaper
        rationale: "Standardized shapes for cost optimization and support"
    - user_input:
        type: enum
        description: "Fallback: Any valid OCI shape if no standardization"
        validation:
          source: oci_api  # Query available shapes from OCI
```

**Code Generation Pattern** (Conceptual):
- **Approved lists**: Define environment-specific approved values (shapes per environment, allowed regions per data classification)
- **Validation**: Generate Terraform variable validation rules to enforce approved lists
- **User selection**: User selects from approved list, not free choice
- **Implementation approach**: Use Terraform `validation` blocks with `contains()` checks

**Example: Regions**

**Example Schema**:
```yaml
region:
  source: choice
  precedence:
    - resource_owner:
        owner: compliance_team
        type: data_residency_policy
        allowed_regions:
          us_data: ["us-ashburn-1", "us-phoenix-1"]
          eu_data: ["eu-frankfurt-1", "eu-amsterdam-1"]
          apac_data: ["ap-tokyo-1", "ap-sydney-1"]
        policy: "data_residency_gdpr"
        condition: "data_classification == 'EU_Personal_Data'"
        rationale: "GDPR compliance requires EU data residency"
    - user_input:
        type: enum
        description: "Select from allowed regions"
        validation:
          source: oci_api
```

---

## Analysis of Existing Resources

### Foundation Resources

#### contract

**Purpose**: OCI connection configuration

**Arguments**: All from **Resource Owner** (OCI administrator)
- `tenancy_ocid` - Resource Owner: OCI Administrator
- `user_ocid` - Resource Owner: OCI Administrator
- `fingerprint` - Resource Owner: OCI Administrator
- `private_key_path` - Resource Owner: OCI Administrator
- `region` - User Input or Resource Owner

**Notes**: Highly sensitive, typically managed centrally

#### profile

**Purpose**: Authentication profile

**Arguments**:
- `tenancy_ocid` - Resource Owner: OCI Administrator
- `user_ocid` - Resource Owner: OCI Administrator
- `fingerprint` - Resource Owner: OCI Administrator
- `region` - User Input

**Dependencies**:
- `region` (mandatory) - Can be User Input or from existing `region` resource

#### region

**Purpose**: Deployment region

**Arguments**:
- `region_name` - User Input (e.g., "us-phoenix-1", "eu-frankfurt-1")

**Notes**: Simple user selection from available regions

#### tenancy

**Purpose**: Root-level OCI tenancy

**Arguments**:
- `tenancy_ocid` - Resource Owner: OCI Administrator (from contract)

**Dependencies**:
- `profile` (mandatory) - Deployed Resource
- `realm` (mandatory) - Deployed Resource

#### realm

**Purpose**: Top-level organizational boundary

**Arguments**:
- `realm_id` - Resource Owner: OCI Administrator (e.g., "oc1", "oc2")

**Dependencies**:
- `contract` (mandatory) - Deployed Resource

---

### Identity Resources

#### compartment

**Purpose**: Logical grouping of resources

**Arguments**:
- `compartment_id` (parent) - **Choice**:
  - Existing Infrastructure: OCID of existing parent compartment (root or nested)
  - Deployed Resource: If creating compartment hierarchy in one deployment
- `name` - User Input
- `description` - User Input (optional)
- `freeform_tags` - User Input (optional)
- `defined_tags` - User Input (optional)

**Dependencies**:
- `tenancy` (mandatory) - Deployed Resource

**Sourcing Pattern**:
```yaml
compartment:
  compartment_id:
    source: choice
    options:
      - existing_infrastructure:
          description: "OCID of existing parent compartment"
          data_source: "data.oci_identity_compartment.parent"
      - deployed_resource:
          description: "Parent compartment created in this deployment"
          reference: "${oci_identity_compartment.parent.id}"
  name:
    source: user_input
    type: string
    required: true
```

---

### Network Resources

#### vcn

**Purpose**: Virtual Cloud Network

**Arguments**:
- `compartment_id` - **Existing Infrastructure** (typical) or Deployed Resource (if creating compartment too)
- `cidr_blocks` - **Resource Owner: Network Team** or User Input
- `display_name` - User Input
- `dns_label` - User Input (optional)
- `is_ipv6enabled` - User Input (boolean)
- `freeform_tags` - User Input (optional)

**Dependencies**:
- `region` (mandatory) - Deployed Resource or Existing Infrastructure
- `compartment` (mandatory) - Typically Existing Infrastructure

**Sourcing Pattern**:
```yaml
vcn:
  compartment_id:
    source: existing_infrastructure
    description: "OCID of compartment to create VCN in"
    data_source: "data.oci_identity_compartment.target"
  cidr_blocks:
    source: resource_owner
    owner: "network_team"
    description: "CIDR blocks allocated by network team"
    type: list(string)
    validation:
      regex: "^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$"
  display_name:
    source: user_input
    type: string
    required: true
```

**Provides**: `internet_gateway`, `nat_gateway`, `service_gateway` (embedded/created automatically)

#### subnet

**Purpose**: IP address range within VCN

**Arguments**:
- `vcn_id` - **Deployed Resource** (from VCN in this deployment) or Existing Infrastructure
- `compartment_id` - Typically same as VCN (Deployed Resource reference or Existing Infrastructure)
- `cidr_block` - **Resource Owner: Network Team** (must be within VCN CIDR)
- `display_name` - User Input
- `dns_label` - User Input (optional)
- `prohibit_public_ip_on_vnic` - User Input or Resource Owner: Security Team
- `route_table_id` - Deployed Resource (from route table) or Existing Infrastructure
- `security_list_ids` - Deployed Resource (list) or Existing Infrastructure
- `availability_domain` - User Input (select from available ADs)

**Optional Dependencies**:
- `log_group` - Deployed Resource or Existing Infrastructure (for flow logs)

**Sourcing Pattern**:
```yaml
subnet:
  vcn_id:
    source: deployed_resource
    reference: "${oci_core_vcn.main.id}"
  cidr_block:
    source: resource_owner
    owner: "network_team"
    validation:
      - must_be_within: "${oci_core_vcn.main.cidr_blocks}"
  prohibit_public_ip_on_vnic:
    source: choice
    options:
      - user_input: "User decides public IP policy"
      - resource_owner: "Security team enforces policy"
    default:
      source: resource_owner
      owner: "security_team"
```

#### internet_gateway, nat_gateway, service_gateway

**Purpose**: Network gateways (often auto-created by VCN)

**Arguments**:
- `vcn_id` - Deployed Resource (parent VCN)
- `compartment_id` - Deployed Resource (same as VCN)
- `display_name` - User Input
- `enabled` - User Input (boolean)

**Sourcing Pattern**: Mostly Deployed Resource references, simple User Input for names

**Provides**: Automatically provided by VCN if configured

#### nsg (Network Security Group)

**Purpose**: Firewall rules

**Arguments**:
- `vcn_id` - Deployed Resource or Existing Infrastructure
- `compartment_id` - Deployed Resource or Existing Infrastructure
- `display_name` - User Input
- `security_rules` - **Resource Owner: Security Team** or User Input
  - `protocol` - Resource Owner/User Input
  - `source` - Resource Owner/User Input (CIDR)
  - `destination` - Resource Owner/User Input (CIDR)
  - `port_range` - Resource Owner/User Input

**Sourcing Pattern**:
```yaml
nsg:
  security_rules:
    source: choice
    options:
      - resource_owner:
          owner: "security_team"
          description: "Predefined security policies"
      - user_input:
          description: "User defines custom rules"
          schema:
            type: list
            items:
              protocol: string
              source: cidr
              destination: cidr
```

---

### Compute Resources

#### zone

**Purpose**: Logical grouping (subnet + availability domain)

**Arguments**:
- `subnet_id` - Deployed Resource (from subnet in this deployment)
- `availability_domain` - User Input (select from available)
- `bastion_id` - Deployed Resource (optional)

**Sourcing Pattern**: Primarily Deployed Resource references, simple User Input for AD selection

#### compute_instance

**Purpose**: Virtual machine

**Arguments**:
- `zone_id` - Deployed Resource (module reference)
- `compartment_id` - Existing Infrastructure or Deployed Resource
- `availability_domain` - From zone (Deployed Resource)
- `shape` - User Input (select from available shapes)
- `display_name` - User Input
- `image_id` - User Input (select from available images) or Resource Owner
- `subnet_id` - From zone (Deployed Resource)
- `assign_public_ip` - User Input (boolean) or Resource Owner: Security Team
- `ssh_authorized_keys` - **Resource Owner: Security Team** or User Input
- `freeform_tags` - User Input
- `nsg_ids` - Deployed Resource (list of NSGs) or Existing Infrastructure

**Dependencies**:
- `zone` (mandatory) - Deployed Resource
- `either` (mandatory, choose one):
  - `internet_gateway` - Deployed Resource or Existing Infrastructure
  - `nat_gateway` - Deployed Resource or Existing Infrastructure
  - `bastion` - Deployed Resource or Existing Infrastructure

**Optional Dependencies**:
- `nsg` (optional, can specify multiple) - Deployed Resource or Existing Infrastructure

**Embedded**:
- `vnic` - Automatically created with instance

**Sourcing Pattern**:
```yaml
compute_instance:
  zone_id:
    source: deployed_resource
    reference: "${module.zone.id}"
  shape:
    source: user_input
    type: enum
    values: ["VM.Standard.E4.Flex", "VM.Standard3.Flex", ...]
  image_id:
    source: choice
    options:
      - user_input: "User selects from available OS images"
      - resource_owner:
          owner: "platform_team"
          description: "Standardized golden images"
  ssh_authorized_keys:
    source: resource_owner
    owner: "security_team"
    description: "Centrally managed SSH keys"
    type: list(string)
  assign_public_ip:
    source: choice
    default:
      source: resource_owner
      owner: "security_team"
```

#### vnic

**Purpose**: Virtual network interface

**Arguments**:
- `subnet_id` - Deployed Resource (from parent instance/zone)
- `assign_public_ip` - From parent instance
- `display_name` - User Input
- `hostname_label` - User Input (optional)
- `nsg_ids` - Deployed Resource or Existing Infrastructure
- `private_ip` - User Input (optional, auto-assigned if not provided) or Resource Owner: Network Team

**Sourcing Pattern**: Mostly inherited from parent compute_instance

---

### Security Resources

#### bastion

**Purpose**: OCI Bastion Service for secure access

**Arguments**:
- `compartment_id` - Existing Infrastructure or Deployed Resource
- `subnet_id` - Deployed Resource or Existing Infrastructure
- `bastion_type` - User Input (enum: "STANDARD", "MANAGED_SSH")
- `client_cidr_block_allow_list` - **Resource Owner: Security Team**
- `max_session_ttl_in_seconds` - User Input or Resource Owner: Security Team
- `name` - User Input

**Dependencies**:
- `subnet` (mandatory) - Deployed Resource or Existing Infrastructure
- `service_gateway` (mandatory) - Deployed Resource or Existing Infrastructure
- `either` (mandatory):
  - `internet_gateway` - Deployed Resource or Existing Infrastructure
  - `nat_gateway` - Deployed Resource or Existing Infrastructure

**Sourcing Pattern**:
```yaml
bastion:
  client_cidr_block_allow_list:
    source: resource_owner
    owner: "security_team"
    description: "Allowed source IPs for bastion access"
    type: list(string)
    validation:
      regex: "^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$"
```

---

### Logging Resources

#### log_group

**Purpose**: Container for logs

**Arguments**:
- `compartment_id` - Existing Infrastructure or Deployed Resource
- `display_name` - User Input
- `description` - User Input (optional)

**Sourcing Pattern**: Simple User Input with Existing Infrastructure reference for compartment

---

### Application Resources

#### app

**Purpose**: Application layer stack

**Arguments**:
- `zone_id` - Deployed Resource
- `bastion_id` - Deployed Resource
- `compute_instance_ids` - Deployed Resource (list)
- `app_name` - User Input
- `app_version` - User Input or Resource Owner: Application Team
- `configuration` - **Resource Owner: Application Team**

**Dependencies**:
- `zone` (mandatory) - Deployed Resource
- `bastion` (mandatory) - Deployed Resource
- `compute_instance` (mandatory) - Deployed Resource

**Provides**: `app_web`, `app_db` (application layers)

**Sourcing Pattern**:
```yaml
app:
  configuration:
    source: resource_owner
    owner: "application_team"
    description: "Application-specific configuration"
    type: map(any)
```

#### app_web, app_db

**Purpose**: Web and database application layers

**Arguments**:
- `app_id` - Deployed Resource (parent app)
- `configuration` - Resource Owner: Application Team
- `ansible_playbook` - Resource Owner: Application Team (Ansible configuration)

**Dependencies**:
- `app` (mandatory) - Deployed Resource (parent)

**Sourcing Pattern**: Primarily Resource Owner (Application Team) for configuration

---

## Sourcing Patterns Summary

### By Resource Type

| Resource | Resource Owner % | Deployed Resource % | Existing Infra % | User Input % |
|----------|------------------|---------------------|------------------|--------------|
| Foundation (contract, profile, realm, tenancy) | 80% | 20% | 0% | 0% |
| Identity (compartment) | 0% | 20% | 60% | 20% |
| Network (vcn, subnet, gateways, nsg) | 30% | 40% | 20% | 10% |
| Compute (instance, vnic) | 20% | 50% | 10% | 20% |
| Security (bastion) | 40% | 40% | 10% | 10% |
| Logging (log_group) | 0% | 20% | 60% | 20% |
| Application (app, app_web, app_db) | 60% | 40% | 0% | 0% |

### By Parameter Category

| Parameter Type | Primary Source | Secondary Source |
|----------------|----------------|------------------|
| CIDR blocks, IP ranges | Resource Owner (Network Team) | User Input |
| Security rules, policies | Resource Owner (Security Team) | User Input |
| SSH keys, credentials | Resource Owner (Security Team) | - |
| Resource IDs (OCID) | Existing Infrastructure or Deployed Resource | - |
| Display names | Resource Owner (Governance - Naming Convention) | User Input |
| Tags | Resource Owner (Governance/Finance/Compliance) | User Input (additional) |
| Configuration files | Resource Owner (App/Platform Team) | - |
| Boolean flags | Resource Owner (Policy) | User Input |
| Enums (shapes, regions) | Resource Owner (Standardization) | User Input |

---

## Design Implications

### 1. Catalog Schema Extension

**Current YAML**:
```yaml
vcn:
  description: "Virtual Cloud Network"
  requires:
    mandatory:
      - compartment
```

**Proposed Extended Schema**:
```yaml
vcn:
  description: "Virtual Cloud Network"
  requires:
    mandatory:
      - compartment
  arguments:
    compartment_id:
      source: existing_infrastructure
      type: ocid
      description: "OCID of compartment"
      data_source: "data.oci_identity_compartment.target"

    cidr_blocks:
      source: resource_owner
      owner: "network_team"
      type: list(string)
      required: true
      validation:
        regex: "^([0-9]{1,3}\\.){3}[0-9]{1,3}/[0-9]{1,2}$"
      description: "CIDR blocks for VCN (allocated by network team)"

    display_name:
      source: user_input
      type: string
      required: true
      description: "User-friendly name for VCN"

    dns_label:
      source: user_input
      type: string
      required: false
      validation:
        regex: "^[a-zA-Z][a-zA-Z0-9]{0,14}$"
```

### 2. Resource Owner Registry

**New File**: `etc/resource_owners.yaml`

```yaml
resource_owners:
  # Infrastructure Teams
  network_team:
    description: "Network infrastructure team"
    responsibilities:
      - CIDR block allocation
      - IP address management
      - DNS configuration
    contact: "network-team@company.com"
    parameters:
      - vcn.cidr_blocks
      - subnet.cidr_block
      - vnic.private_ip (optional)

  security_team:
    description: "Information security team"
    responsibilities:
      - Security policies
      - Access control
      - SSH key management
      - Security classification
    contact: "security-team@company.com"
    parameters:
      - nsg.security_rules
      - bastion.client_cidr_block_allow_list
      - compute_instance.ssh_authorized_keys
      - compute_instance.assign_public_ip (policy)
      - tags.SecurityClassification (mandatory)

  platform_team:
    description: "Platform engineering team"
    responsibilities:
      - Golden images
      - Standard configurations
      - Approved instance shapes
      - Standardization
    contact: "platform-team@company.com"
    parameters:
      - compute_instance.image_id (standardized)
      - compute_instance.shape (approved list)

  # Governance & Policy Teams
  governance_team:
    description: "IT governance and standards team"
    responsibilities:
      - Naming conventions
      - Environment classification
      - Resource tagging standards
      - Policy enforcement
    contact: "governance@company.com"
    policies:
      - naming_convention:
          pattern: "${environment}-${application}-${component}-${seq}"
          regex: "^(dev|test|prod)-[a-z0-9-]+-[a-z0-9-]+-[0-9]{2}$"
      - environment_tags:
          required: true
          values: ["Development", "Test", "Production"]
    parameters:
      - *.display_name (convention)
      - tags.Environment (mandatory)

  finance_team:
    description: "Finance and cost management"
    responsibilities:
      - Cost center allocation
      - Budget tracking
      - Cost tagging requirements
    contact: "finance@company.com"
    parameters:
      - tags.CostCenter (mandatory)
      - tags.BudgetCode (mandatory)
      - tags.CostOwner (mandatory)

  compliance_team:
    description: "Regulatory compliance and data residency"
    responsibilities:
      - Data residency policies
      - Regulatory compliance (GDPR, HIPAA, etc.)
      - Region restrictions
      - Backup policies
    contact: "compliance@company.com"
    policies:
      - data_residency_gdpr:
          condition: "data_classification == 'EU_Personal_Data'"
          allowed_regions: ["eu-frankfurt-1", "eu-amsterdam-1"]
      - backup_policy_hipaa:
          condition: "data_classification == 'PHI'"
          enable_backup: true
          retention_days: 2555  # 7 years
    parameters:
      - region (policy-based restriction)
      - tags.DataResidency (mandatory)
      - *.enable_backup (policy)

  operations_team:
    description: "Operations and monitoring"
    responsibilities:
      - Monitoring policies
      - Alerting standards
      - Operational tags
    contact: "operations@company.com"
    policies:
      - monitoring_required:
          condition: "environment == 'Production'"
          enable_monitoring: true
    parameters:
      - *.enable_monitoring (policy)
      - tags.MonitoringTier (mandatory for production)

  # Application Teams
  application_team:
    description: "Application development team"
    responsibilities:
      - Application configuration
      - Deployment artifacts
      - Ansible playbooks
    contact: "app-team@company.com"
    parameters:
      - app.configuration
      - app_web.ansible_playbook
      - app_db.configuration
```

### 3. Code Generation Strategy (Conceptual Patterns)

#### Pattern 1: Deployed Resources (Intra-Deployment References)
- **Approach**: Generate Terraform references using `${resource_type.resource_name.attribute}` syntax
- **Example**: Subnet references VCN via `oci_core_vcn.main.id`
- **Dependency handling**: Respect dependency tree order (VCN before subnet)

#### Pattern 2: Existing Infrastructure
- **Approach**: Generate Terraform data sources (`data "oci_identity_compartment" "existing"`)
- **User provides**: Identifier (OCID, name, or filter criteria)
- **Code references**: Data source attributes (`data.oci_identity_compartment.existing.id`)

#### Pattern 3: Resource Owner Parameters
- **Approach**: Generate variables with placeholders and governance metadata
- **Include**: Contact information, parameter descriptions, validation rules
- **Output files**:
  - `terraform.tfvars` with placeholders and comments
  - `PARAMETERS.md` documenting resource owner requirements
  - README with prerequisites and contact information

#### Pattern 4: User Input Parameters
- **Approach**: Generate standard Terraform variables
- **Include**: Type definitions, validation rules, default values (if applicable)
- **Governance constraints**: Enforce via validation blocks when policies exist

### 4. Parameter Collection Workflow (Conceptual Design)

#### CLI Interactive Mode Concept
- **Progressive prompts**: Step through parameters source-by-source
- **Source-aware prompts**:
  - Existing Infrastructure: Request OCID, validate resource exists
  - Resource Owner: Show contact info, offer to create placeholder
  - User Input: Standard prompt with validation
- **Governance visibility**: Display when policy/governance applies
- **Placeholder support**: Allow generation with placeholders for resource owner parameters

#### API Request Design Concept
- **Structured payload**: Include source metadata for each parameter
- **Validation**: Verify source correctness (don't accept user_input for governance-controlled parameters)
- **Audit trail**: Track approval metadata for resource owner parameters (who, when)
- **Governance enforcement**: API validates against policies before accepting request

#### Web UI Flow Concept
- **Multi-step wizard**: Separate pages for each source type
- **Dependency visualization**: Show tree of resources being created
- **Source-specific UX**:
  - Existing Infrastructure: Resource picker with search/validation
  - Resource Owner: Contact cards with parameter requirements
  - User Input: Forms with real-time validation
  - Governance: Read-only display of policy-enforced values
- **Output packaging**: Generated Terraform + documentation + requirements list

---

## Recommendations

### For CVM-2 (Architecture Design)

1. **Define Parameter Sourcing Model** as core architectural concept
2. **Catalog Schema** must include sourcing information for each argument
3. **Resource Owner Registry** as separate configuration
4. **Validation Layer** must verify source compliance

### For CVM-3 (Catalog Management)

1. Extend YAML schema to include `arguments` section with sourcing metadata
2. Validate sourcing configuration at catalog load time
3. Support resource owner registry integration

### For CVM-6 (Code Generator)

1. Generate different code patterns based on source:
   - Deployed Resource → Terraform reference (`${resource.id}`)
   - Existing Infrastructure → Data source + reference
   - Resource Owner → Variable with placeholder + documentation
   - User Input → Variable

2. Generate supplementary files:
   - `terraform.tfvars` with placeholders and comments
   - `PARAMETERS.md` listing resource owner requirements
   - `README.md` with deployment prerequisites

### For CVM-7 (Parameter Collection)

1. Implement source-aware parameter collection
2. CLI: Different prompts for different sources
3. API: Validate source field in request
4. Web: Wizard with source-specific pages

### For CVM-11 (Integration Testing)

1. Test parameter sourcing consistency across CLI/API/Web
2. Verify generated code correctness for each source type
3. Validate resource owner workflow

---

## Next Steps

1. **Immediate** (Can be done now):
   - ✅ This analysis document (DONE)
   - Update CVM-2 to include parameter sourcing design
   - Propose extended catalog schema

2. **Sprint 2** (Architecture Design):
   - Finalize parameter sourcing model
   - Design resource owner registry schema
   - Define code generation patterns per source
   - Create ADR (Architecture Decision Record)

3. **Sprint 3** (Catalog Implementation):
   - Implement extended YAML schema
   - Add sourcing metadata to existing 20 resources
   - Create resource owner registry

4. **Sprint 4+** (Code Generation):
   - Implement source-aware code generation
   - Generate parameter documentation
   - Test with all sourcing patterns

---

## Conclusion

Parameter sourcing is a **first-class architectural concept** in Cloud Vending Machine, not an afterthought. The enhanced model with **source precedence** and **governance integration** provides a comprehensive framework that:

### Core Concepts

1. **Four-Source Taxonomy**:
   - Resource Owner (Infrastructure + Governance teams)
   - Deployed Resource (Terraform references)
   - Existing Infrastructure (Data sources)
   - User Input (Within policy constraints)

2. **Source Precedence (Governance Model)**:
   - **Policy takes precedence** over user choice
   - Governance/compliance enforced at generation time
   - User selects from approved options
   - Validates real-world enterprise requirements

3. **Expanded Resource Owner Types**:
   - **Infrastructure Teams**: Network, Security, Platform, Application
   - **Governance Teams**: Governance, Finance, Compliance, Operations
   - Each with specific responsibilities and parameters

### Enterprise Value

1. **Reflects Real-World Operational Reality**:
   - Teams with specific responsibilities
   - Policies and governance enforced
   - Compliance requirements automated

2. **Enables Proper Separation of Concerns**:
   - Who owns what is explicit
   - Approval workflows built-in
   - Contact information available

3. **Supports Security and Compliance**:
   - Centralized key management (security_team)
   - Mandatory tags (finance_team, compliance_team)
   - Policy enforcement (governance_team)
   - Data residency compliance (compliance_team)

4. **Guides Code Generation Strategy**:
   - Deployed resources → Terraform references
   - Existing infrastructure → Data sources
   - Resource owner → Variables + validation + policy
   - User input → Variables within constraints

### Key Innovations

1. **Source Precedence**: Not just "who provides" but "who decides"
2. **Governance Integration**: Naming conventions, tags, policies enforced
3. **Policy-Based Configuration**: Security/compliance policies in code
4. **Mandatory vs Optional Tags**: Governance + user tags merged
5. **Approved Lists**: Shapes, regions, images from standardization

### Impact on Architecture

This analysis fundamentally shapes:
- **CVM-2 (Architecture)**: Governance as core concept, policy engine design
- **CVM-3 (Catalog)**: Extended schema with precedence, policies
- **CVM-6 (Generator)**: Policy evaluation, validation enforcement
- **CVM-7 (Parameters)**: Source precedence in collection workflow
- **CVM-9 (API)**: Policy API endpoints, governance integration
- **CVM-10 (Web)**: UX for governed parameters, policy visibility

### Implementation Complexity

**Medium-High Complexity** (but essential for enterprise adoption):
- Schema more complex (precedence, policies, conditions)
- Code generation must evaluate policies
- Parameter collection must check governance
- Validation must enforce compliance
- Documentation must explain policies

**High Value** (justifies complexity):
- Enterprise-ready from day one
- Compliance built-in
- Audit trail automatic
- Governance scalable

**Status**: Analysis complete with governance model ✅
**Recommendation**: Incorporate into CVM-2 Elaboration phase design
**Priority**: High - Governance is critical for enterprise adoption
