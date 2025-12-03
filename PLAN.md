# Development plan

Project details are in `BACKLOG.md` file.

Instruction for Product Owner: keep the development sprint by sprint by changing `Status` label form `Planned` via `Progress` to `Done`. To achieve simplicity each iteration contains exactly one feature. You may add more Backlog Items in `BACKLOG.md` file, referring them in this plan.

Instruction for Developer: keep analysis, design and implementation as simple as possible to achieve goals presented as Backlog Items. Remove each not required feature from your development plan strictly sticking to the Backlog Items definitions. Any important feature extension propose via methods described in cooperation rules of `RUPStrikesBack` method.

## Sprint 1 - Review of current codebase

Status: Done

Mode: Managed

Backlog Items:

* CVM-1. Discover current research code ✅

Deliverables:
* Executive summary of research code
* Design vision and architecture concepts
* 12+ backlog item proposals (CVM-2 through CVM-16)
* Parameter sourcing analysis (4-source taxonomy)

## Sprint 2 - PoC Phase 1 (Foundation Validation)

Status: Planned

Mode: Managed

Backlog Items:

* POC-1. Setup PoC Project Structure
* POC-2. Implement Extended Catalog Schema and Parser
* POC-3. Port Dependency Resolution to Go
* POC-4. HCL Generation Approach Spike

Goal: Answer architectural questions about HCL generation, catalog schema, dependency resolution, and parameter sourcing.

Success Criteria:
* Catalog parser working with extended schema
* Dependency resolution ported to Go
* HCL generation approach decided (template/programmatic/hybrid)
* All 4 parameter sources tested

## Sprint 3 - PoC Phase 2 (End-to-End Validation)

Status: Planned

Mode: Managed

Backlog Items:

* POC-5. Implement Source-Aware Code Generation
* POC-6. Implement Minimal CLI with Parameter Collection
* POC-7. End-to-End Validation with Real Terraform
* POC-8. Create PoC Summary Report

Goal: Complete end-to-end validation, generate production-quality Terraform code, create comprehensive PoC report.

Success Criteria:
* Generate valid Terraform code for compute_instance
* CLI with interactive parameter collection working
* terraform validate passes
* PoC summary report with architectural decisions
* Updated backlog based on findings
