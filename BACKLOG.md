# OCI Vending Machine - Project Backlog

## Project Overview

OCI Vending Machine is a framework for declarative, human-readable infrastructure provisioning on Oracle Cloud Infrastructure. The project implements a FQRN (Fully Qualified Resource Name) pattern that enables same-session resource resolution and multi-application deployments within a single Terraform workspace.

## Project Status: Working Implementation with Design Documentation

The project has evolved from pure design specification to a working reference implementation with comprehensive documentation. Core patterns are proven, automation is functional, and the framework supports multiple real-world deployment scenarios.

## Current State Assessment

### Phase: Construction (Advanced)

The project has completed design and initial construction phases. A working reference implementation exists in oci-example/ with:
- Core infrastructure modules implemented and tested
- Multi-application deployment pattern proven
- Automation scripts functional
- FQRN aggregation working reliably

### Repository Health

- Implementation: oci-example/ contains working Terraform modules
- Documentation: 7 markdown files (recently consolidated from 9)
- Automation: 6 bash/python scripts for generation and deployment
- Modules: 8 resource types implemented
- Applications: 4+ concurrent apps demonstrated (app1-4, web1)

## Completed Work

### OCIV-001: Core FQRN Pattern Design
Status: COMPLETED
- FQRN syntax specification (cmp://, vcn://, sub://, nsg://, instance://, zone://)
- Layered aggregation pattern for same-session resolution
- Documentation in FQRN.md

### OCIV-002: Base Infrastructure Modules
Status: COMPLETED
- compartment/compartments modules
- vcn module with Internet Gateway, NAT Gateway, Service Gateway
- subnet module with flow logs
- nsg module with rule management
- log_group module for logging infrastructure

### OCIV-003: Compute and Access Modules
Status: COMPLETED
- compute_instance module with zone pattern
- bastion module for secure access
- Integration with Oracle Cloud Agent plugins

### OCIV-004: Multi-Application Deployment Pattern
Status: COMPLETED
- Separation: infra_*.tf for shared resources, app*_*.tf for applications
- FQRN map aggregation across applications
- Cross-application NSG references working
- Documentation in MULTI_APP.md

### OCIV-005: Automation Infrastructure
Status: COMPLETED
- generate_fqrn.sh with Python/Jinja2 template engine
- generate_tfvars.sh for configuration consolidation
- terraform_prepare.sh wrapper script
- Auto-detection of modules and applications
- Documentation in README_GENERATION.md

### OCIV-006: FQRN-as-Index Pattern
Status: COMPLETED
- Resources indexed by full FQRN in tfvars
- Zone FQRN references (not embedded objects)
- Var2HCL transformation layer for user-friendly configuration
- Support for custom transformation overrides

### OCIV-007: Documentation Consolidation
Status: COMPLETED (2025-01-30)
- Updated CLAUDE.md to reflect actual implementation
- Corrected script names and references throughout
- Removed redundant files (AUTO_GENERATION_ASSESSMENT.md, MODULE_INTEGRATION.md)
- Verified documentation against actual code

## Active Issues

### OCIV-DOC-001: Documentation-Code Gap
Priority: MEDIUM
Current: CLAUDE.md oversimplifies the actual module interface pattern
Impact: AI assistants may not understand the var2hcl transformation layer and FQRN-as-index pattern
Recommendation: Add technical addendum to CLAUDE.md or create MODULE_PATTERNS.md

### OCIV-DOC-002: Missing Pattern Documentation
Priority: MEDIUM
Missing documentation for:
- Var2HCL transformation layer and custom overrides
- FQRN-as-index pattern (using FQRNs as map keys)
- Zone FQRN reference pattern
- Custom var2hcl override mechanism

### OCIV-CODE-001: Template Comment Accuracy
Priority: LOW
File: templates/terraform_fqrn.tf.j2
Issue: Header references "bin/generate_all_fqrn.py" but actual file is "bin/generate_fqrn.py"
Impact: Minor confusion when reading generated files

## Backlog Items

### OCIV-008: Additional Resource Modules
Priority: MEDIUM
Description: Implement modules for additional OCI resources
Items:
- Database systems (ATP, ADB, MySQL)
- Load balancers (Network Load Balancer, Application Load Balancer)
- Object storage buckets
- Vault integration for secrets management
- Block volumes
- File storage

### OCIV-009: FQRN Resolver for Existing Resources
Priority: MEDIUM
Description: Module to resolve FQRNs for existing OCI resources (not created in same session)
Pattern: Dual-input approach (existing vs new resources)
Reference: terraform-oci-modules-iam pattern
Benefits: Enable references to pre-existing infrastructure

### OCIV-010: Enhanced Zone Pattern
Priority: LOW
Description: Extend zone pattern with additional location contexts
Items:
- Vault references for secrets
- DRG (Dynamic Routing Gateway) references
- Route table customization
- DHCP options support

### OCIV-011: Module Testing Framework
Priority: MEDIUM
Description: Implement automated testing for modules
Approach:
- Terratest integration
- Module validation tests
- FQRN resolution verification
- Multi-app deployment scenarios

### OCIV-012: CI/CD Integration Guide
Priority: LOW
Description: Document CI/CD pipeline patterns
Items:
- GitHub Actions workflow examples
- GitLab CI templates
- State file management strategies
- Multi-environment deployment patterns

### OCIV-013: Migration Utilities
Priority: LOW
Description: Tools for migrating existing infrastructure to vending machine pattern
Items:
- OCID to FQRN conversion script
- Existing resource import automation
- Configuration generator from existing state

### OCIV-014: Observability Integration
Priority: MEDIUM
Description: Enhanced logging and monitoring
Items:
- Flow logs for all network components
- Service connector hub integration
- Metrics and alarms as code
- Logging analytics integration

### OCIV-015: Security Hardening
Priority: HIGH
Description: Security best practices implementation
Items:
- Security zone support
- Encryption at rest (block volumes, object storage)
- Network encryption in transit
- Secrets management via OCI Vault
- Security baselines and compliance checks

### OCIV-016: Cost Management Features
Priority: MEDIUM
Description: Cost tracking and optimization
Items:
- Resource tagging strategy
- Cost allocation tags
- Budget alerts integration
- Resource scheduling (stop/start)

### OCIV-017: Module Versioning Strategy
Priority: LOW
Description: Establish module versioning and release process
Items:
- Semantic versioning for modules
- Module registry setup
- Upgrade path documentation
- Compatibility matrix

### OCIV-018: Advanced Networking
Priority: MEDIUM
Description: Complex networking scenarios
Items:
- Hub-and-spoke VCN architecture
- Transit routing with DRG
- VPN and FastConnect integration
- DNS and traffic management

### OCIV-019: Disaster Recovery Patterns
Priority: LOW
Description: DR and backup strategies
Items:
- Cross-region replication
- Backup policies as code
- DR runbooks automation
- Recovery time optimization

### OCIV-020: Developer Experience Improvements
Priority: MEDIUM
Description: Enhance developer workflows
Items:
- Interactive wizard for new applications
- Configuration validation pre-deployment
- Better error messages in modules
- Quick-start templates for common scenarios

## Technical Debt

### TD-001: Hardcoded SSH Keys in Example Config
Priority: HIGH
Location: app1_compute_custom.tfvars, app2_compute_custom.tfvars
Issue: SSH public keys are hardcoded in example configs
Recommendation: Use variables or Vault references

### TD-002: Availability Domain Handling
Priority: MEDIUM
Issue: AD resolution requires external data source
Recommendation: Consider simplifying AD selection pattern

### TD-003: Custom var2hcl Complexity
Priority: LOW
Issue: Custom override mechanism (app1_compute_instances_var2hcl_custom) adds complexity
Recommendation: Document trade-offs, consider simplification

## Documentation Priorities

### High Priority
1. MODULE_PATTERNS.md - Detailed technical patterns (FQRN-as-index, var2hcl)
2. Security hardening guide
3. Production deployment checklist

### Medium Priority
4. Module development guide
5. Testing strategy documentation
6. Troubleshooting guide expansion

### Low Priority
7. Architecture decision records (ADRs)
8. Performance tuning guide
9. Module API reference

## Maintenance Tasks

### Regular
- Review and update script references in documentation
- Verify generated files match templates
- Check for OCI provider updates and compatibility

### As Needed
- Update example configurations with new patterns
- Refresh module interface documentation
- Clean up deprecated patterns

## Success Metrics

### Current Achievement
- 8 module types implemented
- 4+ concurrent applications supported
- Same-session FQRN resolution working
- Auto-generation scripts functional
- Zero manual orchestration file edits required

### Target Goals
- 15+ module types
- 10+ concurrent applications tested
- CI/CD pipeline templates
- Production deployments documented
- Community adoption (if open-sourced)

## Next Sprint Recommendations

### Sprint Focus: Security and Stability
1. Address TD-001 (hardcoded SSH keys)
2. Implement OCIV-015 (security hardening basics)
3. Create MODULE_PATTERNS.md (OCIV-DOC-002)
4. Review and test all modules with latest OCI provider

### Quick Wins
- Fix template comment (OCIV-CODE-001)
- Add validation to generation scripts
- Create production deployment checklist
- Document var2hcl pattern

## Notes

This backlog reflects project state as of 2025-01-30 after documentation review and consolidation. The project is in advanced construction phase with working implementation and proven patterns. Focus areas are security hardening, documentation accuracy, and expanding module coverage for production readiness.

---
*Backlog maintained using principles from RUPStrikesBack methodology*
*Last updated: 2025-01-30*
