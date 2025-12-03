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

**Status**: ✅ Complete (Sprint 1)

Discover current research code build to model resource dependency with CLI user interface:

* etc/resource_dependencies.yaml - represents resource catalogue with dependency
* bin/check_dependencies.py - python code to print tree of resources required to be used for given target resource

Create executive summary for already available knowledge, and prepare design vision. Stay at inception phase at this backlog; do not go to design or implementation as it's too early.

Prepare list of backlog item candidates with short description.

**Deliverables**: Executive summary, design vision, 12+ backlog item proposals

---

## Foundation & Architecture

### CVM-2. Design Cloud Vending Machine Architecture

**Dependencies**: CVM-1 (complete)

**Priority**: High - Foundation for all other work

Design the overall system architecture for Cloud Vending Machine.

**Deliverables:**

* System architecture diagram (components, interfaces, data flow)
* Module structure for Go implementation
* Package organization: `pkg/dependencies`, `pkg/catalog`, `pkg/generator`, `pkg/validator`, `pkg/api`, `pkg/web`
* YAML catalog schema (v2) with resource owner support
* **Parameter Sourcing Model** (4-source taxonomy) ⭐
* Terraform HCL output structure and organization
* Interface definitions between components
* Error handling and logging strategy
* Configuration management approach

**Design Decisions:**

* Shared core logic across CLI/API/Web interfaces
* Plugin architecture for extensibility
* State management (if any)
* Concurrency model for code generation
* **Parameter sourcing strategy** (Resource Owner, Deployed Resource, Existing Infrastructure, User Input) ⭐

**Parameter Sourcing Design** (From Sprint 1 Analysis):

Four-source taxonomy for resource arguments:
1. **Resource Owner** - External authority (network team, security team, etc.)
   - CIDR blocks, security policies, SSH keys, configurations
   - Requires approval workflow and contact registry

2. **Deployed Resource** - Created in current deployment round
   - Terraform references: `${oci_core_vcn.main.id}`
   - Automatic dependency ordering

3. **Existing Infrastructure** - Already-deployed resources
   - Terraform data sources: `data.oci_identity_compartment.existing`
   - User provides OCIDs or filters

4. **User Input** - Direct user-provided values
   - Display names, tags, boolean flags, enums

**Implications:**
* Catalog schema must include sourcing metadata for each argument
* Code generator must handle each source type differently
* Parameter collection varies by source (prompts, lookups, placeholders)
* Generated output includes resource owner requirements documentation

**Artifacts:**

* Architecture Decision Records (ADRs)
* Component diagrams
* Sequence diagrams for key workflows
* API contracts between modules
* **Parameter Sourcing Specification** ⭐
* **Resource Owner Registry Schema** ⭐

### CVM-3. Implement Resource Catalog Management

**Dependencies**: CVM-2 (architecture design)

**Priority**: High - Core functionality

Implement YAML-based resource catalog management system.

**Deliverables:**

* YAML schema (v2) with resource owner support
* YAML parser and validator in Go
* Resource catalog data structures
* Catalog versioning and migration support
* Catalog validation rules
* Go package: `pkg/catalog`

**Features:**

* Load and parse `resource_dependencies.yaml`
* Validate catalog structure and relationships
* Query resources by name, kind, type
* Traverse dependency relationships
* Support for embedded, provided, either groups
* Catalog schema evolution

**Testing:**

* Unit tests for parser and validator
* Integration tests with sample catalogs
* Schema validation tests

### CVM-4. Implement Dependency Resolution Engine

**Dependencies**: CVM-3 (catalog management)

**Priority**: High - Core functionality

Port Python dependency resolution algorithms to Go.

**Deliverables:**

* Go package: `pkg/dependencies`
* Dependency resolution algorithms
* Cycle detection and prevention
* Transitive dependency calculation
* Support for all relationship types

**Features:**

* Resolve mandatory dependencies (recursive)
* Resolve optional dependencies
* Handle "either" groups (choose one)
* Handle embedded resources
* Handle "provides" relationships
* Detect circular dependencies
* Build dependency trees
* Calculate longest paths

**Testing:**

* Comprehensive unit tests
* Test with all 20 existing OCI resources
* Edge case testing (cycles, complex either groups)
* Performance benchmarks

---

## Code Generation

### CVM-5. HCL Generation Approach Spike

**Dependencies**: CVM-3, CVM-4

**Priority**: Medium - Informs CVM-6

**Time-box**: 2-3 days

Evaluate and prototype different approaches for Terraform HCL code generation.

**Approaches to Evaluate:**

1. **Programmatic Generation** (hashicorp/hcl/v2/hclwrite)
2. **Template-Based** (text/template)
3. **Hybrid** (templates for simple, generation for complex)

**Evaluation Criteria:**

* Code maintainability
* Testability
* Flexibility for complex scenarios
* Developer experience
* Error handling
* Performance

**Deliverables:**

* Prototype each approach with 3-4 sample resources:
  - Simple: compartment, vcn
  - Medium: subnet (with optional log_group)
  - Complex: compute_instance (with either groups, embedded VNIC)
* Comparison document with pros/cons
* Recommendation with rationale
* Code samples demonstrating each approach

**Output**: Decision for CVM-6 implementation approach

### CVM-6. Implement Terraform HCL Code Generator

**Dependencies**: CVM-5 (approach decision)

**Priority**: High - Core functionality

Implement Terraform HCL code generation based on CVM-5 decision.

**Deliverables:**

* Go package: `pkg/generator`
* HCL code generation from dependency trees
* Parameter interpolation and substitution
* Idempotent, deterministic code generation (CVM.NFR-2)
* Output file organization and naming
* Terraform variable files generation

**Features:**

* Generate resource blocks with proper syntax
* Handle dependencies via Terraform references
* Generate provider configuration
* Generate terraform.tfvars for parameters
* Support for all relationship types
* Code formatting and validation

**Quality:**

* Generated code passes `terraform validate`
* Generated code passes `terraform fmt -check`
* Comprehensive unit tests
* Integration tests with real Terraform

### CVM-7. Implement Parameter Collection System

**Dependencies**: CVM-6 (HCL generator)

**Priority**: Medium - Required for interactive use

Design and implement parameter collection for resources.

**Deliverables:**

* Go package: `pkg/parameters`
* Parameter schema definition
* Parameter validation
* Interactive prompts (for CLI)
* Resource owner concept implementation

**Features:**

* Define parameter types (string, number, boolean, list, map)
* Validation rules (regex, min/max, enum)
* Mandatory vs optional parameters
* Default values
* Parameter dependencies
* Resource owner assignment

**Integration:**

* CLI interactive prompts
* API request validation
* Web form generation support

---

## User Interfaces

### CVM-8. Implement Interactive CLI

**Dependencies**: CVM-4 (dependencies), CVM-6 (generator), CVM-7 (parameters)

**Priority**: High - Primary user interface

Create interactive command-line interface for Cloud Vending Machine.

**Deliverables:**

* CLI application using Cobra or similar framework
* Interactive resource selection
* Parameter collection prompts
* Progress visualization
* Output management (directory, GitHub)

**Commands:**

```bash
cvm init                          # Initialize configuration
cvm catalog list                  # List available resources
cvm catalog show <resource>       # Show resource details
cvm dependencies <resource>       # Show dependency tree
cvm generate <resource> [flags]   # Generate infrastructure code
cvm validate <path>               # Validate generated code
```

**Features:**

* Interactive mode with prompts
* Non-interactive mode with flags
* YAML configuration file support
* Output to directory or GitHub
* Colored output and progress bars
* Clear error messages (CVM.NFR-5)

### CVM-9. Design and implement REST API

**Dependencies**: CVM-4, CVM-6, CVM-7

**Priority**: High - Enables programmatic access and web UI

Design and implement REST API for Cloud Vending Machine providing programmatic access to all core functionality.

**API Endpoints:**

* `GET /api/v1/resources` - List available resources
* `GET /api/v1/resources/{name}` - Get resource details and dependencies
* `GET /api/v1/resources/{name}/dependencies` - Get dependency tree
* `POST /api/v1/generate` - Generate infrastructure code
* `POST /api/v1/validate` - Validate resource configuration
* `GET /api/v1/catalog` - Get full resource catalog
* `GET /api/v1/health` - Health check
* `GET /api/v1/version` - Version information

**Requirements:**

* RESTful design following OpenAPI 3.0 specification
* JSON request/response format
* Authentication and authorization (API keys/JWT tokens)
* Rate limiting and throttling
* Error handling with proper HTTP status codes
* CORS support for web interface integration
* API versioning (v1, v2, etc.)
* Request validation
* Comprehensive API documentation (Swagger/OpenAPI)

**Implementation:**

* Go HTTP server using standard library or framework (Gin/Echo/Fiber)
* Go package: `pkg/api`
* Share core business logic with CLI (pkg/dependencies, pkg/generator, etc.)
* Middleware: logging, auth, rate limiting, CORS
* Unit and integration tests for all endpoints
* API documentation generation (Swagger UI)

**Non-Functional:**

* Handle concurrent requests
* Request/response logging
* Metrics and monitoring endpoints
* Graceful shutdown

### CVM-10. Design and implement Web Interface

**Dependencies**: CVM-9 (REST API)

**Priority**: Medium - Enhanced user experience

Design and implement browser-based web interface for Cloud Vending Machine providing visual, user-friendly access.

**Web Interface Features:**

* Resource catalog browser with search and filtering
* Visual dependency tree display (interactive graph or tree view)
* Interactive resource selection (multi-select with auto-dependency resolution)
* Web forms for parameter configuration
* Real-time code generation preview
* Code syntax highlighting (Terraform HCL)
* Download generated code as files or zip archives
* Validation feedback and error messages
* Project/workspace management

**Requirements:**

* Responsive design (desktop, tablet, mobile)
* Modern, intuitive user experience
* Real-time updates using WebSockets or Server-Sent Events
* Client-side validation before API calls
* Accessibility compliance (WCAG 2.1 Level AA)
* Cross-browser compatibility (Chrome, Firefox, Safari, Edge)
* Progressive Web App (PWA) capabilities

**Implementation Options:**

* **Option A**: Server-side rendering with Go templates (simpler, Go-only, fast initial load)
* **Option B**: SPA with React/Vue/Svelte + REST API (richer UX, better interactivity)
* **Option C**: HTMX with Go templates (modern hybrid, minimal JavaScript)

**Recommended**: Option C (HTMX) for balance of simplicity and modern UX

**Components:**

* Frontend application (SPA or Go templates)
* Integration with REST API backend (CVM-9)
* Asset serving (CSS, JavaScript, images)
* WebSocket support for real-time updates (optional)
* State management (client-side or session-based)

**Go Package**: `pkg/web`

### CVM-11. Integrate and Test Multi-Interface Architecture

**Dependencies**: CVM-8 (CLI), CVM-9 (API), CVM-10 (Web)

**Priority**: Medium - Quality assurance

Ensure consistent behavior and shared business logic across all three access methods.

**Architecture:**

```
┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│     CLI     │  │  REST API   │  │  Web UI     │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                │
       └────────────────┴────────────────┘
                        │
            ┌───────────▼───────────┐
            │   Core Packages       │
            ├───────────────────────┤
            │ pkg/catalog           │
            │ pkg/dependencies      │
            │ pkg/generator         │
            │ pkg/parameters        │
            │ pkg/validator         │
            └───────────────────────┘
```

**Consistency Requirements:**

* Same validation rules across all interfaces
* Same code generation output regardless of interface
* Consistent error messages and codes
* Unified logging and monitoring
* Shared configuration management
* Same feature availability

**Testing:**

* Cross-interface integration tests
* Behavioral consistency verification
* Performance benchmarks for all interfaces
* End-to-end user journey tests
* Load testing for API and Web

**Quality Metrics:**

* Feature parity matrix (CLI vs API vs Web)
* Performance comparison
* Error handling consistency
* Test coverage per interface

---

## Resource Expansion

### CVM-12. Expand OCI Resource Catalog

**Dependencies**: CVM-3 (catalog management)

**Priority**: Low - Can be done incrementally

Expand resource catalog beyond initial 20 resources.

**Current Coverage**: 20 resources

**Missing OCI Resources**:

* **Database**: Autonomous Database, MySQL, PostgreSQL, NoSQL
* **Load Balancing**: Load Balancer, Network Load Balancer
* **Storage**: Object Storage, Block Volume, File Storage
* **Security**: Key Management (Vault), WAF, Security Lists
* **Monitoring**: Alarms, Notifications, Events
* **Compute**: Instance Pools, Autoscaling, Dedicated Hosts
* **Network**: DRG, IPSec VPN, FastConnect, DNS
* **Container**: OKE (Kubernetes), Container Instances, Registry
* **Functions**: Oracle Functions (serverless)
* **API Gateway**: API Management

**Deliverables:**

* Add 30-50 additional OCI resources to catalog
* Define dependencies for each resource
* Document FQRN schemes
* Update resource relationships

**Process:**

* Research Terraform OCI provider documentation
* Extract resource arguments and attributes
* Define dependency relationships
* Update YAML catalog
* Test with dependency resolver

### CVM-13. Implement Provider Documentation Import

**Dependencies**: CVM-3 (catalog management)

**Priority**: Low - Automation for CVM-12

Automate import of resource properties from Terraform provider documentation.

**Current**: Hand-written YAML resource definitions

**Target**: Automated import from provider schema

**Deliverables:**

* Import tool for Terraform provider schemas
* Parser for provider documentation
* Mapping from provider schema to catalog YAML
* Validation of imported definitions

**Sources:**

* Terraform provider schema (JSON)
* Terraform Registry API
* Provider source code

**Features:**

* Extract resource arguments and attributes
* Generate YAML catalog entries
* Detect required vs optional arguments
* Extract descriptions and types
* Semi-automated dependency inference (requires human review)

---

## Quality & Validation

### CVM-14. Implement Testing Framework

**Dependencies**: CVM-4, CVM-6 (core packages)

**Priority**: Medium - Quality assurance

Create comprehensive testing framework for Cloud Vending Machine.

**Test Types:**

1. **Unit Tests**:
   - All core packages (catalog, dependencies, generator, parameters)
   - 80%+ code coverage target
   - Fast, isolated tests

2. **Integration Tests**:
   - Multi-package workflows
   - CLI commands end-to-end
   - API endpoints with real HTTP
   - Database interactions (if any)

3. **Functional Tests**:
   - Generate code for all 20+ resources
   - Validate with `terraform validate`
   - Test complex dependency scenarios

4. **Performance Tests**:
   - Code generation time benchmarks (CVM.NFR-1)
   - Dependency resolution performance
   - API throughput and latency
   - Concurrent request handling

5. **End-to-End Tests**:
   - Complete user journeys (CLI/API/Web)
   - Real Terraform deployments (optional, expensive)

**Infrastructure:**

* CI/CD pipeline (GitHub Actions)
* Test data fixtures
* Mock HTTP servers for API tests
* Test coverage reporting
* Performance regression detection

### CVM-15. Implement Validation System

**Dependencies**: CVM-4 (dependencies), CVM-6 (generator)

**Priority**: Medium - Quality and safety

Implement validation system to prevent invalid configurations.

**Validation Types:**

1. **Catalog Validation**:
   - YAML schema compliance
   - Dependency relationship validity
   - No circular dependencies
   - FQRN scheme correctness

2. **Configuration Validation**:
   - Required parameters provided
   - Parameter types correct
   - Parameter constraints satisfied (regex, min/max, enum)
   - Resource compatibility

3. **Dependency Validation**:
   - All mandatory dependencies satisfiable
   - "Either" groups have at least one option
   - Embedded resources properly handled
   - Provided resources correctly referenced

4. **Output Validation**:
   - Generated HCL syntax correctness
   - Terraform validate passes
   - Terraform fmt compliance
   - No conflicting resource definitions

**Go Package**: `pkg/validator`

**Features:**

* Pre-generation validation (fail fast)
* Post-generation validation (verify output)
* Clear, actionable error messages (CVM.NFR-5)
* Warning vs error distinction
* Validation rule extensibility

**Integration:**

* CLI validates before generation
* API validates requests and responses
* Web UI validates client-side and server-side

---

## Documentation

### CVM-16. Create User Documentation

**Dependencies**: CVM-8 (CLI), CVM-9 (API), CVM-10 (Web)

**Priority**: Medium - Essential for adoption

Create comprehensive user-facing documentation.

**Documentation Types:**

1. **User Guide**:
   - Getting started tutorial
   - Installation instructions
   - Quick start guide (5-minute example)
   - Step-by-step tutorials for common scenarios
   - CLI command reference
   - API endpoint reference
   - Web UI walkthrough

2. **Resource Catalog Documentation**:
   - Complete resource reference
   - Dependency relationships explained
   - Parameter documentation
   - FQRN scheme examples
   - Best practices for each resource

3. **Developer Documentation**:
   - Architecture overview
   - Package documentation (GoDoc)
   - Contributing guide
   - Code organization
   - Extension points

4. **API Documentation**:
   - OpenAPI/Swagger specification
   - Interactive API explorer
   - Authentication guide
   - Code examples in multiple languages (curl, Go, Python, JavaScript)

5. **Troubleshooting Guide**:
   - Common errors and solutions
   - Debugging tips
   - FAQ
   - Known limitations

**Deliverables:**

* README.md (project overview, quick start)
* docs/ directory with comprehensive guides
* Generated API documentation (Swagger UI)
* Generated code documentation (GoDoc)
* Tutorial videos or screencasts (optional)

**Tools:**

* Markdown for user guides
* MkDocs or similar for documentation site
* Swagger/OpenAPI for API docs
* GoDoc for code documentation
