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

### API Consumer

As an API consumer I want to access vending machine functionality via REST API

As an API consumer I want to retrieve resource catalog via API

As an API consumer I want to request infrastructure code generation via API

As an API consumer I want to query dependency trees for resources via API

As an API consumer I want to receive generated code via API response

### Web User

As a web user I want to access vending machine through a browser interface

As a web user I want to browse available resources in a visual catalog

As a web user I want to select resources and see dependency trees visualized

As a web user I want to configure resource parameters through web forms

As a web user I want to download generated infrastructure code from the browser

As a web user I want to view and validate generated code before downloading

## Functional Requirements

* CVM.FR-1 System SHALL generate cloud infrastructure code from resource definitions
* CVM.FR-2 System SHALL manage resource dependencies
* CVM.FR-3 System SHALL provide resource catalogue with templates
* CVM.FR-4 System SHALL support infrastructure changes through redeployment
* CVM.FR-5 System SHALL provide REST API for programmatic access
* CVM.FR-6 System SHALL provide web interface for browser-based access
* CVM.FR-7 System SHALL support multiple access methods (CLI, API, Web)

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
* CVM.IC-7 REST API: Go-based (standard library or framework like Gin/Echo)
* CVM.IC-8 Web interface: Modern JavaScript framework (React/Vue/Svelte) or Go templates

## Backlog

### CVM-1. Discover current research code

Discover current research code build to model resource dependency with CLI user interface:

* etc/resource_dependencies.yaml - represents resource catalogue with dependency
* bin/check_dependencies.py - python code to print tree of resources required to be used for given target resource

Create executive summary for already available knowledge, and prepare design vision. Stay at inception phase at this backlog; do not go to design or implementation as it's too early.

Prepare list of backlog item candidates with short description.

### CVM-13. Design and implement REST API

Design and implement REST API for Cloud Vending Machine providing programmatic access to all core functionality.

**API Endpoints:**

* GET /api/v1/resources - List available resources
* GET /api/v1/resources/{name} - Get resource details and dependencies
* GET /api/v1/resources/{name}/dependencies - Get dependency tree
* POST /api/v1/generate - Generate infrastructure code
* POST /api/v1/validate - Validate resource configuration
* GET /api/v1/catalog - Get full resource catalog

**Requirements:**

* RESTful design following OpenAPI 3.0 specification
* JSON request/response format
* Authentication and authorization (API keys/tokens)
* Rate limiting and error handling
* CORS support for web interface integration
* API versioning (v1, v2, etc.)
* Comprehensive API documentation (Swagger/OpenAPI)

**Implementation:**

* Go HTTP server using standard library or framework (Gin/Echo)
* Share core business logic with CLI
* Unit and integration tests for all endpoints
* API documentation generation

### CVM-14. Design and implement Web Interface

Design and implement browser-based web interface for Cloud Vending Machine providing visual, user-friendly access.

**Web Interface Features:**

* Resource catalog browser with search and filtering
* Visual dependency tree display (similar to check_dependencies.py output)
* Interactive resource selection
* Web forms for parameter configuration
* Real-time code generation preview
* Code syntax highlighting (Terraform HCL)
* Download generated code as files or archives
* Validation feedback and error messages

**Requirements:**

* Responsive design (desktop and mobile)
* Modern, intuitive user experience
* Real-time updates using WebSockets or polling
* Client-side validation before API calls
* Accessibility compliance (WCAG 2.1)
* Cross-browser compatibility

**Implementation Options:**

* **Option A**: Server-side rendering with Go templates (simpler, Go-only)
* **Option B**: SPA with React/Vue/Svelte + REST API (richer UX)
* **Option C**: HTMX with Go templates (modern hybrid approach)

**Components:**

* Frontend application (SPA or Go templates)
* Integration with REST API backend
* Asset serving (CSS, JavaScript, images)
* WebSocket support for real-time updates (optional)

### CVM-15. Integrate CLI, API, and Web interfaces

Ensure consistent behavior and shared business logic across all three access methods.

**Architecture:**

* Shared core packages (dependencies, generator, catalog, validator)
* CLI uses core packages directly
* API wraps core packages with HTTP handlers
* Web interface consumes API

**Consistency Requirements:**

* Same validation rules across all interfaces
* Same code generation output regardless of interface
* Consistent error messages and handling
* Unified logging and monitoring
* Shared configuration management

**Testing:**

* Cross-interface integration tests
* Behavioral consistency verification
* Performance benchmarks for all interfaces
