# Check Dependencies requirements

## Core Functionality

1. **Dependency Tree Visualization** - Display resource dependencies as a tree structure, reading from YAML configuration (`./etc/resource_dependencies.yaml`)

2. **Top-to-Bottom Tree** - Show dependencies from root (no dependencies) to target resource at the bottom

3. **Resource Types Support**:
   - ✅ Mandatory dependencies
   - 🔹 Optional dependencies  
   - 🔶 "Either/choose one" groups (mutually exclusive options)
   - 📎 Embedded resources (tightly coupled with parent)

## Display Options (CLI Flags)

4. **`--source`** - Show provider annotations (e.g., "provided by vcn")

5. **`--with-descriptions` / `-d`** - Show resource descriptions from YAML

6. **`--kind`** - Show resource kind (e.g., `[oci://resource]`, `[oci://module]`)

7. **`--type`** - Show resource type (e.g., `<bin/terraform>`, `<config/yaml>`)

8. **`--siblings`** - Include dependents in tree (what depends on target)

9. **`--debug`** - Show debug info for hidden resources

## Tree Structure Rules

10. **Correct Parent Path** - Resources appear under their most specific parent (e.g., `subnet` under `vcn`, not `compartment`)

11. **Longest Path Priority** - Prefer parents in the longest path to target

12. **Provided Resources Under Provider** - Resources provided by another appear only under their provider (e.g., `service_gateway` under `vcn`)

13. **No Duplicate Display** - Resources appear once in the tree, not multiple times

14. **Clean Tree Lines** - No dangling/disconnected vertical lines (correct `├──` vs `└──` usage)

## Sorting Order (Per Node)

15. **Children Sorting Priority**:
    1. Optional (not provided) - top
    2. Optional dependencies of the resource
    3. Provided resources (both optional and mandatory)
    4. Mandatory (not in path to target)
    5. Mandatory (in path to target)
    6. Target resource - very bottom

## Embedded Resources

16. **Embedded Attribute** - Resources with `embedded:` in YAML have those resources printed directly above with 📎 marker

17. **Implicit Dependencies** - Embedded resources are treated as implicit mandatory dependencies

18. **Single Display** - Embedded resources only appear with their embedder, not elsewhere in tree

19. **Connected Tree** - Embedded resources maintain tree connectivity (no disconnected nodes)

## Configuration

20. **Default Config Path** - Look in `./etc/` directory for `resource_dependencies.yaml`

21. **YAML Schema Support**:
    - `description` - resource description
    - `kind` - resource kind/category
    - `type` - implementation type
    - `fqrn_scheme` - fully qualified resource name pattern
    - `requires.mandatory` - required dependencies
    - `requires.optional` - optional dependencies
    - `requires.either` - mutually exclusive options
    - `provides` - resources this one provides
    - `embedded` - tightly coupled resources