# Cloud Vending Machine

Imagine Cloud configuration using a vending machine you know from your office. You select what you want, the machine asks for options, and voilà! - your setup is ready.

## Overview

Cloud Vending Machine generates Cloud configuration utilizing resource definitions and resource dependency data. Instead of generating dynamic code that can reconfigure at runtime, the vending machine favors code generation that fulfills requirements. At the same time, the vending machine makes it possible to add new resources and remove existing resources from the definition. Such changes require redeployment.

## User stories

### Designer

As a designer I want to define resources to be used by vending machine.

As a designer I want to import resource properties: arguments, and produced attributes from provider documentation

As a designer I want to define resource owners, that are authorities to provide externally defined configuration parameters

### User

As a user I want to ask vending machine to prepare an infrastructure definition for a given resource

As a user I want to ask vending machine to prepare infrastructure definition for given resource set

As a user I want to answer mandatory questions about user specific parameters

As a user I require that vending machine will produce deployable code

As a user I want vending machine to write an infrastructure code to a directory

As a user I want vending machine to use GitHub as target infrastructure repository

## Functional Requirements

* CVM.FR-1 System SHALL generate cloud infrastructure code from resource definitions
* CVM.FR-2 System SHALL manage resource dependencies
* CVM.FR-3 System SHALL provide resource catalogue with templates
* CVM.FR-4 System SHALL support infrastructure changes through redeployment

## Non-Functional Requirements

### Performance

* CVM.NFR-1 Code generation SHALL complete in reasonable time for typical deployments

### Reliability

* CVM.NFR-2 Generated code SHALL be deterministic and idempotent
* CVM.NFR-3 System SHALL validate dependencies and prevent invalid configurations

### Usability

* CVM.NFR-4 Configuration format SHALL be human-readable and maintainable
* CVM.NFR-5 Error messages SHALL be clear and actionable

### Maintainability

* CVM.NFR-6 System SHALL support template versioning and evolution
* CVM.NFR-7 Generated code SHALL be readable and follow industry standards

## Implementation Constraints

* CVM.IC-1 Implementation language: Go
* CVM.IC-2 Input format: YAML
* CVM.IC-3 Output: Terraform HCL
* CVM.IC-4 Target infrastructure: Oracle OCI
* CVM.IC-5 Deployment technology: Terraform
* CVM.IC-6 Optional application configuration technology: Ansible

## Backlog

### CVM-1. Discover current research code

Discover current research code build to model resource dependency with CLI user interface:

* etc/resource_dependencies.yaml - represents resource catalogue with dependency
* bin/check_dependencies.py - python code to print tree of resources required to be used for given target resource

Create executive summary for already available knowledge, and prepare design vision. Stay at inception phase at this backlog; do not go to design or implementation as it's too early.

Prepare list of backlog item candidates with short description.
 