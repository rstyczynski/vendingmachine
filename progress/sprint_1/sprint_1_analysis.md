# Sprint 1 - Analysis

Status: Complete

## Sprint Overview

Sprint 1 focuses on discovering and analyzing the existing research code that models resource dependencies for Oracle Cloud Infrastructure (OCI). This is a reconnaissance and knowledge transfer sprint, staying strictly at the inception phase without proceeding to design or implementation.

**Sprint Goal**: Understand the current research implementation, extract knowledge, create executive summary, and propose future backlog items.

## Backlog Items Analysis

### CVM-1: Discover current research code

**Requirement Summary:**

Analyze existing research code that models resource dependencies with a CLI interface:

- `etc/resource_dependencies.yaml` - Resource catalogue with dependency structure
- `bin/check_dependencies.py` - Python script to visualize dependency trees

Create an executive summary of available knowledge, prepare design vision, and propose backlog item candidates. Critically important: **DO NOT proceed to design or implementation** - this is purely reconnaissance work.

**Technical Approach:**

Discovery approach consists of:

1. **Code Review**: Examine YAML schema and Python implementation
2. **Knowledge Extraction**: Document current capabilities and limitations
3. **Vision Development**: Outline potential evolution toward Cloud Vending Machine
4. **Backlog Planning**: Identify work items for future sprints

**Current Implementation Analysis:**

**1. Resource Catalog (etc/resource_dependencies.yaml)**

**Schema Structure:**

```yaml
resources:
  <resource_name>:
    description: "Human-readable description"
    kind: "<resource_category>"
    type: "<implementation_type>"
    fqrn_scheme: "<fully_qualified_resource_name_template>"
    embedded: [<resources_embedded_in_this_resource>]
    requires:
      mandatory: [<list_of_required_resources>]
      optional: [<list_of_optional_resources>]
    provides: [<resources_provided_by_this_resource>]
```

**Key Features:**

- **Resource Kinds**: oci://contract, oci://resource, oci://module, app://application
- **Resource Types**: config/yaml, config/terraform, config/ansible, config/stack
- **FQRN Scheme**: Template for fully qualified resource names with parameter substitution
- **Dependency Model**:
  - `requires.mandatory`: Resources that must exist before this resource
  - `requires.optional`: Resources that can optionally be used
  - `requires.mandatory.either`: "Choose one" scenarios (e.g., internet_gateway OR nat_gateway OR bastion)
  - `embedded`: Resources tightly coupled with parent (e.g., VNIC embedded in compute_instance)
  - `provides`: Resources automatically created/managed by this resource

**Resource Coverage:**

- **Foundation**: contract, profile, realm, tenancy, region (5 resources)
- **Identity**: compartment (1 resource)
- **Logging**: log_group (1 resource)
- **Network**: vcn, internet_gateway, nat_gateway, service_gateway, subnet, nsg (6 resources)
- **Zone**: zone (logical grouping module) (1 resource)
- **Compute**: compute_instance, vnic (2 resources)
- **Security**: bastion (1 resource)
- **Application**: app, app_db, app_web (3 resources)
- **Total**: 20 resources defined

**2. Dependency Analyzer (bin/check_dependencies.py)**

**Implementation**: Python 3 script (1088 lines)

**Core Capabilities:**

1. **Dependency Resolution**:
   - `load_dependencies()`: Loads YAML resource catalog
   - `resolve_dependencies()`: Recursively resolves all transitive dependencies
   - `build_dependency_tree()`: Creates hierarchical dependency structure
   - Handles circular dependency prevention with visited sets

2. **Visualization**:
   - Tree-based ASCII art rendering
   - Visual symbols: ✅ (mandatory), 🔹 (optional), 🔶 (choose one), 📎 (embedded), 🔻 (dependent)
   - Smart parent selection: Shows resources under most specific parent
   - Longest path calculation to target resource

3. **Advanced Features**:
   - `--with-descriptions` / `-d`: Include resource descriptions
   - `--source`: Show only direct dependencies, annotate transitive ones
   - `--siblings`: Include reverse dependencies (what depends on target)
   - `--kind`: Display resource kind (oci://resource, etc.)
   - `--type`: Display resource type (config/terraform, etc.)
   - `--debug`: Debug mode for troubleshooting

4. **Complex Scenarios**:
   - **Embedded Resources**: VNIC embedded in compute_instance
   - **Provided Resources**: VCN provides internet_gateway, nat_gateway, service_gateway
   - **Either Groups**: compute_instance requires (internet_gateway OR nat_gateway OR bastion)
   - **Transitive Dependencies**: Fully resolved dependency chains

**Example Usage:**

```bash
./bin/check_dependencies.py compute_instance
./bin/check_dependencies.py bastion --with-descriptions
./bin/check_dependencies.py zone --source --kind
```

**Dependencies Analysis:**

The Python script depends on:

- Python 3 (built-in: sys, pathlib, typing)
- PyYAML (external: `pip install PyYAML`)

**Current Implementation Strengths:**

1. **Rich Dependency Model**: Handles mandatory, optional, either, embedded, and provided resources
2. **Smart Visualization**: Intelligent tree rendering with proper parent-child relationships
3. **Comprehensive Coverage**: 20 OCI resources with realistic dependencies
4. **Extensible Schema**: YAML format easily allows adding new resources
5. **User-Friendly Output**: Multiple display options for different use cases
6. **Robust Implementation**: Handles cycles, transitive dependencies, complex scenarios

**Current Implementation Limitations:**

1. **Read-Only Analysis**: Only visualizes dependencies, doesn't generate infrastructure code
2. **Python-Based**: Research prototype, not integrated with Go-based production system
3. **No Code Generation**: Doesn't produce Terraform HCL or any deployable artifacts
4. **Static Catalog**: Resource definitions are static, not imported from provider docs
5. **No User Interaction**: CLI tool for analysis only, not an interactive vending machine
6. **Limited Validation**: Doesn't validate dependency feasibility against actual provider APIs
7. **No Resource Owners**: Concept mentioned in user stories but not implemented

**Dependencies:**

None - Sprint 1 is pure reconnaissance with no code dependencies on other work.

**Testing Strategy:**

For this inception-only sprint:

- **Manual Review**: Examine code quality, logic, and structure
- **Functional Testing**: Run check_dependencies.py with various resources
- **Coverage Testing**: Verify all 20 resources can be analyzed
- **Edge Case Testing**: Test complex scenarios (either groups, embedded, provided)

No automated testing required for discovery phase.

**Risks/Concerns:**

1. **Technology Transition**: Research code is Python, but production must be Go
   - **Mitigation**: Document algorithms for reimplementation
2. **Scope Creep Risk**: CVM-1 explicitly forbids design/implementation
   - **Mitigation**: Strict adherence to inception-only deliverables
3. **Incomplete Knowledge Transfer**: May miss subtle implementation details
   - **Mitigation**: Thorough code analysis with annotated findings

**Compatibility Notes:**

No compatibility concerns - this is the first Sprint with no prior work to integrate with.

## Overall Sprint Assessment

**Feasibility:** High

The sprint is purely analytical with clear deliverables:

- ✅ Code exists and is accessible
- ✅ Requirements are well-defined and bounded
- ✅ No implementation work prevents scope creep
- ✅ Python and YAML are readable and analyzable

**Estimated Complexity:** Simple

Discovery and documentation work without coding:

- Read and analyze 1 YAML file (~300 lines)
- Read and analyze 1 Python script (~1088 lines)
- Document findings in structured format
- Propose backlog items based on gaps

**Prerequisites Met:** Yes

All prerequisites satisfied:

- ✅ Contracting phase complete
- ✅ Research code exists at specified paths
- ✅ No dependencies on other Sprints
- ✅ Execution mode confirmed (Managed)

**Open Questions:**

None - requirements are clear and unambiguous.

## Design Vision

**From Research Prototype to Cloud Vending Machine**

The existing research code provides a solid foundation for understanding resource dependencies. The evolution path to Cloud Vending Machine involves:

### Architecture Vision

**Current State** (Research):

```
User → CLI (Python) → YAML Catalog → Dependency Tree (ASCII)
```

**Target State** (Cloud Vending Machine):

```
User → Interactive CLI (Go) → Resource Selection → Dependency Resolution →
Parameter Collection → Code Generation (Terraform HCL) → Deployment
```

### Key Architectural Shifts

1. **From Analysis to Generation**
   - Current: Visualize dependency trees
   - Target: Generate deployable Terraform code

2. **From Static to Interactive**
   - Current: Command-line analysis tool
   - Target: Interactive vending machine experience

3. **From Python to Go**
   - Current: Python prototype
   - Target: Go implementation per CVM.IC-1

4. **From Hardcoded to Imported**
   - Current: Hand-written YAML resource definitions
   - Target: Import from Terraform provider documentation

5. **From Simple to Parameterized**
   - Current: Basic dependency resolution
   - Target: Parameter collection with resource owners

### Design Principles (Future)

Based on user stories and requirements:

1. **Code Generation over Runtime Configuration** (CVM.NFR-2)
   - Favor static, deterministic, idempotent code
   - Redeployment model for infrastructure changes

2. **Human-Readable Formats** (CVM.NFR-4)
   - YAML input (maintains compatibility with research)
   - Terraform HCL output (industry standard)

3. **Dependency-Driven Workflow** (CVM.FR-2)
   - Automatic dependency resolution
   - Validation of dependency constraints

4. **Resource Owner Concept** (User Stories)
   - External authorities provide configuration parameters
   - Clear responsibility boundaries

### Technology Stack (Confirmed)

From BACKLOG.md implementation constraints:

- **Language**: Go (CVM.IC-1)
- **Input**: YAML (CVM.IC-2) ✅ Compatible with research
- **Output**: Terraform HCL (CVM.IC-3)
- **Target**: Oracle OCI (CVM.IC-4) ✅ Matches research
- **Deployment**: Terraform (CVM.IC-5)
- **Optional Config**: Ansible (CVM.IC-6)

## Recommended Design Focus Areas

Future sprints should address:

1. **Go Implementation of Dependency Resolution**
   - Port Python algorithms to Go
   - Maintain rich dependency model (mandatory/optional/either/embedded/provides)
   - Add validation against Terraform provider schemas

2. **Code Generation Engine**
   - Terraform HCL generation from dependency trees
   - Parameter interpolation and validation
   - Output formatting and organization

3. **Interactive CLI Experience**
   - Resource selection interface
   - Parameter collection prompts
   - Progress visualization

4. **Resource Catalog Management**
   - YAML schema evolution
   - Import tools for Terraform provider documentation
   - Resource owner definitions

5. **Testing Framework**
   - Functional tests for dependency resolution
   - Code generation validation
   - Terraform plan/apply simulation

## Proposed Backlog Item Candidates

Based on this analysis, the following backlog items are recommended:

### Category 1: Core Infrastructure

**CVM-2: Design Cloud Vending Machine Architecture**

- Define system architecture (components, interfaces, data flow)
- Specify module structure for Go implementation
- Design YAML catalog schema evolution
- Define Terraform HCL output structure
- Create architectural diagrams

**CVM-3: Implement Dependency Resolution in Go**

- Port Python dependency resolution algorithms to Go
- Support mandatory, optional, either, embedded, provides relationships
- Implement cycle detection and validation
- Create Go package: `pkg/dependencies`
- Write comprehensive unit tests

**CVM-4: Implement Resource Catalog Management**

- Design YAML schema (v2) with resource owner support
- Implement YAML parser and validator in Go
- Create resource catalog data structures
- Support catalog versioning
- Create Go package: `pkg/catalog`

### Category 2: Code Generation

**CVM-5: Implement Terraform HCL Code Generator**

- Design HCL generation strategy
- Implement code generation from dependency trees
- Support parameter interpolation
- Generate idempotent, deterministic code per CVM.NFR-2
- Create Go package: `pkg/generator`
- Validate generated code with `terraform validate`

**CVM-6: Implement Parameter Collection System**

- Design parameter input mechanisms
- Support resource owner concept
- Implement interactive prompts
- Validate parameter types and constraints
- Handle mandatory vs optional parameters

### Category 3: User Experience

**CVM-7: Implement Interactive CLI**

- Create interactive resource selection
- Implement vending machine-style UX
- Add progress visualization
- Provide clear error messages per CVM.NFR-5
- Use Go CLI framework (e.g., Cobra)

**CVM-8: Implement GitHub Repository Integration**

- Support writing code to GitHub repositories
- Implement git operations (clone, commit, push)
- Support branch strategies
- Handle authentication

### Category 4: Resource Coverage

**CVM-9: Expand Resource Catalog**

- Add missing OCI resources
- Import resource properties from Terraform OCI provider docs
- Define resource arguments and attributes
- Update dependency relationships

### Category 5: Testing and Quality

**CVM-10: Implement Testing Framework**

- Create functional test suite
- Implement integration tests with Terraform
- Add performance tests for code generation time (CVM.NFR-1)
- Set up CI/CD pipeline

**CVM-11: Implement Validation System**

- Validate dependencies against provider APIs
- Prevent invalid configurations per CVM.NFR-3
- Implement constraint checking
- Add pre-generation validation

### Category 6: Documentation

**CVM-12: Create User Documentation**

- Write user guide
- Create tutorial with examples
- Document resource catalog
- Provide troubleshooting guide

## Readiness for Design Phase

**Status: NOT APPLICABLE**

As explicitly stated in CVM-1 requirements, this sprint stays at inception phase only. There is no progression to design or implementation.

The purpose of this Sprint is knowledge transfer and planning, not delivery of production code.

## Executive Summary

### Current Research Code Assessment

The existing research implementation provides:

1. **Rich Dependency Model**: 20 OCI resources with comprehensive dependency relationships
2. **Solid Foundation**: Python implementation demonstrates feasibility of approach
3. **Clear Patterns**: Algorithms for dependency resolution are well-structured and portable to Go
4. **YAML Compatibility**: Input format aligns with CVM.IC-2 requirement

### Key Knowledge Extracted

1. **Dependency Types Matter**: Must support mandatory, optional, either, embedded, and provides
2. **Tree Visualization is Complex**: Smart parent selection and longest-path algorithms are essential
3. **Extensibility is Key**: Schema must support easy addition of new resources
4. **Validation is Critical**: Dependency constraints must be validated

### Design Vision

Cloud Vending Machine will evolve the research prototype from a read-only analysis tool into a full code generation system:

- **Input**: Resource selection + parameters (via interactive CLI)
- **Processing**: Dependency resolution + validation + code generation
- **Output**: Deployable Terraform HCL code
- **Technology**: Go-based implementation

### Next Steps

12 backlog item candidates proposed across 6 categories:

1. Core Infrastructure (CVM-2 to CVM-4)
2. Code Generation (CVM-5 to CVM-6)
3. User Experience (CVM-7 to CVM-8)
4. Resource Coverage (CVM-9)
5. Testing and Quality (CVM-10 to CVM-11)
6. Documentation (CVM-12)

### Success Criteria (for CVM-1)

- ✅ Existing code discovered and analyzed
- ✅ Knowledge extracted and documented
- ✅ Design vision created
- ✅ Backlog item candidates proposed with descriptions
- ✅ Stayed at inception phase (no design/implementation)

## Conclusion

Sprint 1 successfully completes its reconnaissance mission. The research code provides a solid algorithmic foundation and validates the core dependency resolution approach. The 12 proposed backlog items provide a clear roadmap for evolving from prototype to production Cloud Vending Machine.

**Recommendation**: Proceed to Sprint planning with Product Owner to prioritize proposed backlog items CVM-2 through CVM-12.
