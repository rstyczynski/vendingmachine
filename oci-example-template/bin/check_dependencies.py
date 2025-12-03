#!/usr/bin/env python3
"""
Check resource dependencies based on resource_dependencies.yaml

Usage:
    ./bin/check_dependencies.py compute_instance
    ./bin/check_dependencies.py subnet
    ./bin/check_dependencies.py vcn
"""

import sys
from pathlib import Path
from typing import Dict, List, Set, Tuple

try:
    import yaml
except ImportError:
    print("Error: PyYAML is required. Install it with: pip install PyYAML")
    sys.exit(1)

def load_dependencies(yaml_path: Path) -> Dict:
    """Load resource dependencies from YAML file."""
    with open(yaml_path, 'r') as f:
        data = yaml.safe_load(f)
    return data.get('resources', {})

def get_provided_resources(resources: Dict, resource_name: str, collected: Set[str] = None, provider_map: Dict[str, str] = None) -> Tuple[Set[str], Dict[str, str]]:
    """
    Get all resources provided by a resource (including transitive provides).
    
    For example, if zone provides subnet, and subnet provides vcn,
    then zone effectively provides both subnet and vcn.
    
    Returns:
        Tuple of (set of provided resources, dict mapping provided resource to its provider)
    """
    if collected is None:
        collected = set()
    if provider_map is None:
        provider_map = {}
    
    resource = resources.get(resource_name, {})
    provides = resource.get('provides', [])
    
    for provided in provides:
        if provided not in collected:
            collected.add(provided)
            provider_map[provided] = resource_name
            # Recursively get what the provided resource also provides
            get_provided_resources(resources, provided, collected, provider_map)
    
    return collected, provider_map

def resolve_dependencies(
    resources: Dict,
    resource_name: str,
    visited: Set[str] = None,
    mandatory: Set[str] = None,
    optional: Set[str] = None,
    depth: int = 0
) -> Tuple[Set[str], Set[str]]:
    """
    Recursively resolve all dependencies for a resource.
    
    Returns:
        Tuple of (mandatory_dependencies, optional_dependencies)
    """
    if visited is None:
        visited = set()
    if mandatory is None:
        mandatory = set()
    if optional is None:
        optional = set()
    
    # Prevent infinite loops
    if resource_name in visited:
        return mandatory, optional
    
    visited.add(resource_name)
    
    if resource_name not in resources:
        return mandatory, optional
    
    resource = resources[resource_name]
    requires = resource.get('requires', {})
    
    # Process mandatory dependencies
    for dep in requires.get('mandatory', []):
        # Handle string dependencies and dict dependencies with descriptions
        if isinstance(dep, dict):
            dep_name = list(dep.keys())[0]
        else:
            dep_name = dep
        
        if dep_name not in mandatory:
            mandatory.add(dep_name)
            # Recursively resolve this dependency
            resolve_dependencies(resources, dep_name, visited, mandatory, optional, depth + 1)
    
    # Process optional dependencies
    for dep in requires.get('optional', []):
        # Handle string dependencies and dict dependencies with descriptions
        if isinstance(dep, dict):
            dep_name = list(dep.keys())[0]
        else:
            dep_name = dep
        
        if dep_name not in optional:
            optional.add(dep_name)
            # Recursively resolve this dependency (but mark as optional)
            resolve_dependencies(resources, dep_name, visited, mandatory, optional, depth + 1)
    
    return mandatory, optional

def build_dependency_tree(
    resources: Dict,
    resource_name: str,
    visited: Set[str] = None,
    tree: Dict = None,
    direct_only: bool = False
) -> Dict:
    """
    Build a dependency tree structure showing what each resource depends on.
    
    Args:
        direct_only: If True, only show direct dependencies (no transitive expansion)
    
    Returns:
        Dict with structure: {resource: {mandatory: [...], optional: [...]}}
    """
    if visited is None:
        visited = set()
    if tree is None:
        tree = {}
    
    # Prevent infinite loops
    if resource_name in visited:
        return tree
    
    visited.add(resource_name)
    
    if resource_name not in resources:
        return tree
    
    if resource_name not in tree:
        tree[resource_name] = {
            'mandatory': [],
            'optional': [],
            'either': [],  # For "one of" requirements
            'either_resources': set()  # Track all resources that are part of "either" groups
        }
    
    resource = resources[resource_name]
    requires = resource.get('requires', {})
    
    # Process mandatory dependencies
    for dep in requires.get('mandatory', []):
        if isinstance(dep, dict):
            dep_name = list(dep.keys())[0]
            # Check if this is an "either" group
            if dep_name == 'either':
                either_options = dep.get('either', [])
                if either_options and either_options not in tree[resource_name]['either']:
                    tree[resource_name]['either'].append(either_options)
                    # Mark these resources as "either" options
                    for opt in either_options:
                        tree[resource_name]['either_resources'].add(opt)
                    # Recursively build tree for each option (but don't add to mandatory)
                    # Only if not in direct_only mode
                    if not direct_only:
                        for opt in either_options:
                            build_dependency_tree(resources, opt, visited.copy(), tree, direct_only)
                continue
        else:
            dep_name = dep
        
        if dep_name not in tree[resource_name]['mandatory']:
            tree[resource_name]['mandatory'].append(dep_name)
            # Recursively build tree for this dependency only if not in direct_only mode
            if not direct_only:
                build_dependency_tree(resources, dep_name, visited, tree, direct_only)
    
    # Process optional dependencies - DO NOT recursively expand them
    # They are only shown at the tail of each resource's children with 🔹
    for dep in requires.get('optional', []):
        if isinstance(dep, dict):
            dep_name = list(dep.keys())[0]
        else:
            dep_name = dep
        
        if dep_name not in tree[resource_name]['optional']:
            tree[resource_name]['optional'].append(dep_name)
            # Do NOT recursively build tree for optional dependencies
            # They are just listed as optional, not expanded into the main tree
    
    return tree

def print_dependencies(resource_name: str, mandatory: Set[str], optional: Set[str], resources: Dict, show_descriptions: bool = False, direct_only: bool = False, debug: bool = False, show_siblings: bool = False, show_kind: bool = False):
    """Print formatted dependency information in tree format."""
    print("═" * 70)
    print(f"Resource: {resource_name.upper()}")
    print("═" * 70)
    
    if resource_name in resources and show_descriptions:
        resource = resources[resource_name]
        print(f"\nDescription: {resource.get('description', 'N/A')}")
        print(f"FQRN Scheme: {resource.get('fqrn_scheme', 'N/A')}")
    
    # Build dependency tree (always full tree, annotations added later for --source mode)
    tree = build_dependency_tree(resources, resource_name, direct_only=False)
    
    # If --siblings is set, also include dependents (what depends on target) in the tree
    dependents_set = set()
    if show_siblings:
        dependents_set = get_all_dependents_recursive(resources, resource_name)
        # Add dependents to the tree
        for dep_name in dependents_set:
            if dep_name not in tree:
                tree[dep_name] = {
                    'mandatory': [],
                    'optional': [],
                    'either': [],
                    'either_resources': set()
                }
            # Get the mandatory deps of this dependent
            dep_resource = resources.get(dep_name, {})
            dep_requires = dep_resource.get('requires', {})
            for req in dep_requires.get('mandatory', []):
                if isinstance(req, dict):
                    req_name = list(req.keys())[0]
                    if req_name != 'either' and req_name not in tree[dep_name]['mandatory']:
                        tree[dep_name]['mandatory'].append(req_name)
                elif req not in tree[dep_name]['mandatory']:
                    tree[dep_name]['mandatory'].append(req)
    
    print("\n" + "─" * 70)
    if show_siblings:
        print("DEPENDENCY TREE WITH DEPENDENTS (top to bottom):")
    else:
    print("DEPENDENCY TREE (top to bottom):")
    print("─" * 70)
    print("\n✅ = Mandatory dependency")
    print("🔹 = Optional dependency")
    print("🔶 = One of (choose one)")
    if show_siblings:
        print("🔻 = Dependent (depends on target)")
    print()
    
    # Build reverse mapping: what MANDATORILY depends on what (for building the tree)
    # Only include mandatory dependencies - optional ones are shown separately at the tail
    depends_on = {}
    # Collect all "either" resources from the entire tree
    all_either_resources = set()
    for node_name, node_data in tree.items():
        for dep in node_data.get('mandatory', []):
            if dep not in depends_on:
                depends_on[dep] = []
            depends_on[dep].append((node_name, False))
        # Collect either resources
        either_res = node_data.get('either_resources', set())
        all_either_resources.update(either_res)
        # Optional deps are NOT added to depends_on - they're shown under their parent with 🔹
    
    # Also add target resource to depends_on if it has dependencies
    if resource_name in tree:
        for dep in tree[resource_name].get('mandatory', []):
            if dep not in depends_on:
                depends_on[dep] = []
            depends_on[dep].append((resource_name, False))
        # Optional deps are NOT added here either
    
    # If showing siblings/dependents, add them to depends_on mapping
    if show_siblings and dependents_set:
        for dep_name in dependents_set:
            dep_resource = resources.get(dep_name, {})
            dep_requires = dep_resource.get('requires', {})
            for req in dep_requires.get('mandatory', []):
                if isinstance(req, dict):
                    req_name = list(req.keys())[0]
                    if req_name != 'either':
                        if req_name not in depends_on:
                            depends_on[req_name] = []
                        if (dep_name, False) not in depends_on[req_name]:
                            depends_on[req_name].append((dep_name, False))
                else:
                    if req not in depends_on:
                        depends_on[req] = []
                    if (dep_name, False) not in depends_on[req]:
                        depends_on[req].append((dep_name, False))
    
    # In direct_only mode, use full view but annotate resources that are PROVIDED
    if direct_only:
        # Get direct dependencies of the target resource
        target_deps = tree.get(resource_name, {})
        direct_mandatory = set(target_deps.get('mandatory', []))
        direct_optional = set(target_deps.get('optional', []))
        direct_either_flat = set()
        for group in target_deps.get('either', []):
            direct_either_flat.update(group)
        
        # Build annotation map: annotate resources that are PROVIDED
        # Trace transitively through all dependencies to find what provides what
        annotations = {}
        
        def trace_provides(res_name: str, visited: Set[str]):
            """Recursively trace dependencies and annotate what they provide."""
            if res_name in visited:
                return
            visited.add(res_name)
            
            res_data = resources.get(res_name, {})
            
            # Check what this resource provides
            provides_list = res_data.get('provides', [])
            for provided in provides_list:
                if provided not in annotations:
                    annotations[provided] = f"(provided by {res_name})"
            
            # Trace its requirements
            requires = res_data.get('requires', {})
            for item in requires.get('mandatory', []):
                if isinstance(item, dict):
                    if 'either' not in item:
                        req = list(item.keys())[0]
                        trace_provides(req, visited)
                else:
                    trace_provides(item, visited)
        
        # Trace from all direct deps
        for dep in direct_mandatory | direct_optional | direct_either_flat:
            trace_provides(dep, set())
        
        # Now use the full view logic but pass annotations
        # (Fall through to full view code below)
    else:
        annotations = {}  # No annotations in normal mode
    
    # Full transitive display (both modes use this, but --source adds annotations)
    # Find root nodes (nodes with no dependencies)
    all_nodes = set(tree.keys())
    all_nodes.add(resource_name)
    root_nodes = []
    for node in all_nodes:
        node_data = tree.get(node, {})
        if len(node_data.get('mandatory', [])) == 0 and len(node_data.get('optional', [])) == 0:
            root_nodes.append(node)
    
    # Find the longest path to target from each root
    longest_path = []
    for root in root_nodes:
        path = find_longest_path_to_target(tree, depends_on, resource_name, root, [], set())
        if len(path) > len(longest_path):
            longest_path = path
    
    visited = set()
    target_printed = False
    
    # Print tree starting from roots, following the dependency chain
    if root_nodes:
        for i, root in enumerate(sorted(root_nodes)):
            is_last_root = (i == len(root_nodes) - 1)
            target_printed = print_tree_node(resources, root, tree, depends_on, visited.copy(), "", is_last_root, False, resource_name, target_printed, longest_path, all_either_resources, show_descriptions, annotations, dependents_set, show_kind)
    
    # Don't print target at root if it wasn't printed - it should be under its most specific parent
    # Only print at root if it truly has no dependencies (which shouldn't happen for compute_instance)
    
    print()

def find_longest_path_to_target(tree: Dict, depends_on: Dict, target: str, current: str, path: List[str], visited: Set[str]) -> List[str]:
    """Find the longest path from current node to target."""
    if current == target:
        return path + [target]
    
    if current in visited:
        return []
    
    visited.add(current)
    
    children = depends_on.get(current, [])
    longest_path = []
    
    for child, _ in children:
        if child not in path:  # Avoid cycles
            new_path = find_longest_path_to_target(tree, depends_on, target, child, path + [current], visited.copy())
            if len(new_path) > len(longest_path):
                longest_path = new_path
    
    return longest_path

def print_tree_node(
    resources: Dict,
    resource_name: str,
    tree: Dict,
    depends_on: Dict,
    visited: Set[str],
    indent: str = "",
    is_last: bool = True,
    is_optional: bool = False,
    target: str = None,
    target_printed: bool = False,
    longest_path: List[str] = None,
    either_resources: Set[str] = None,
    show_descriptions: bool = False,
    annotations: Dict[str, str] = None,
    dependents_set: Set[str] = None,
    show_kind: bool = False
) -> bool:
    """Recursively print a tree node showing dependencies top to bottom. Returns True if target was printed."""
    if either_resources is None:
        either_resources = set()
    if annotations is None:
        annotations = {}
    if dependents_set is None:
        dependents_set = set()
    
    if resource_name in visited:
        return target_printed
    
    # Don't print target if it's already been printed
    if resource_name == target:
        if target_printed:
            return target_printed
    
    visited.add(resource_name)
    
    # Mark target as printed if this is the target
    if resource_name == target:
        target_printed = True
    
    resource = resources.get(resource_name, {})
    
    # Determine marker and prefix
    if is_optional:
        marker = "🔹"
        prefix = ""
    elif resource_name in either_resources:
        marker = "🔶"
        prefix = ""
    elif resource_name in dependents_set:
        marker = "🔻"
        prefix = ""
    else:
        marker = "✅"
        prefix = ""
    
    # Print current node with optional annotation
    connector = "└── " if is_last else "├── "
    annotation = annotations.get(resource_name, "")
    if annotation:
        annotation = f" {annotation}"
    
    # Build kind suffix if requested
    kind_suffix = ""
    if show_kind:
        kind = resource.get('kind', '')
        if kind:
            kind_suffix = f" [{kind}]"
    
    if show_descriptions:
        desc = resource.get('description', 'N/A')
        print(f"{indent}{connector}{marker} {prefix}{resource_name:20s}{kind_suffix}{annotation} - {desc}")
    else:
        print(f"{indent}{connector}{marker} {prefix}{resource_name}{kind_suffix}{annotation}")
    
    # Get children (what depends on this resource)
    children = depends_on.get(resource_name, [])
    
    # If target is already printed, don't show it again as a child
    if target_printed:
        children = [(c, opt) for c, opt in children if c != target]
    
    # Filter children: only show if all their mandatory dependencies are satisfied
    # EXCEPT for the target resource which should always be shown
    def can_show_child(child_name: str) -> bool:
        """Check if a child can be shown (all its mandatory dependencies are satisfied)."""
        # Always show the target resource
        if child_name == target:
            return True
        child_deps = tree.get(child_name, {})
        all_mandatory_deps = set(child_deps.get('mandatory', []))
        # Child can be shown if all its mandatory dependencies are already visited
        return all_mandatory_deps.issubset(visited) or len(all_mandatory_deps) == 0
    
    # Filter children to only show those whose all dependencies are satisfied
    children = [(c, opt) for c, opt in children if can_show_child(c)]
    
    # For resources with multiple parents, show under the MOST SPECIFIC parent
    # The most specific parent is the one that is deepest in the dependency chain
    # We determine this by checking the depth (distance from root) of each parent
    def get_depth_from_root(resource: str, visited_set: Set[str]) -> int:
        """Get the depth of a resource from root (0 = root, 1 = depends on root, etc.)."""
        deps = tree.get(resource, {})
        mandatory_deps = deps.get('mandatory', [])
        if not mandatory_deps:
            return 0  # Root level
        
        # Find the maximum depth of all dependencies
        max_depth = 0
        for dep in mandatory_deps:
            if dep in visited_set:
                dep_depth = get_depth_from_root(dep, visited_set)
                max_depth = max(max_depth, dep_depth)
        return max_depth + 1
    
    def is_most_specific_parent(child_name: str) -> bool:
        """Check if this resource is the most specific parent for the child."""
        child_deps = tree.get(child_name, {})
        mandatory_deps = set(child_deps.get('mandatory', []))
        if resource_name not in mandatory_deps:
            return False  # This resource is not even a dependency of the child
        
        # Check if any other visited resource is also a dependency and is deeper
        this_depth = get_depth_from_root(resource_name, visited)
        for other_parent in visited:
            if other_parent == resource_name:
                continue
            if other_parent in mandatory_deps:
                other_depth = get_depth_from_root(other_parent, visited)
                if other_depth > this_depth:
                    return False  # other_parent is more specific (deeper in tree)
        
        return True
    
    # Filter to only show children where this is the most specific parent
    children = [(c, opt) for c, opt in children if is_most_specific_parent(c)]
    
    # Separate mandatory and optional children
    mandatory_children = [(c, False) for c, opt in children if not opt]
    optional_children = [(c, True) for c, opt in children if opt]
    
    # Sort children: prioritize those in longest path, then alphabetically
    if longest_path:
        mandatory_children.sort(key=lambda x: (x[0] not in longest_path, x[0] == target, x[0]))
        optional_children.sort(key=lambda x: (x[0] not in longest_path, x[0] == target, x[0]))
    else:
        mandatory_children.sort(key=lambda x: (x[0] == target, x[0]))
        optional_children.sort(key=lambda x: (x[0] == target, x[0]))
    
    # Calculate new indent
    new_indent = indent + ("    " if is_last else "│   ")
    
    # Combine all children: mandatory first, then optional (remove duplicates, keep first occurrence)
    seen = set()
    all_children = []
    for c, _ in mandatory_children:
        if c not in seen:
            seen.add(c)
            all_children.append((c, False))
    for c, _ in optional_children:
        if c not in seen:
            seen.add(c)
            all_children.append((c, True))
    
    # Also add this resource's own optional dependencies at the tail
    # (what this resource optionally depends on, shown with 🔹)
    resource_optional_deps = tree.get(resource_name, {}).get('optional', [])
    for opt_dep in sorted(resource_optional_deps):
        if opt_dep not in seen and opt_dep not in visited:
            seen.add(opt_dep)
            all_children.append((opt_dep, True))
    
    # Get "either" groups for this resource
    either_groups = tree.get(resource_name, {}).get('either', [])
    
    # Print all children
    for i, (child, is_opt_child) in enumerate(all_children):
        # Check if there are either groups after this child
        has_either = len(either_groups) > 0
        is_last_child = (i == len(all_children) - 1) and not has_either
        target_printed = print_tree_node(resources, child, tree, depends_on, visited, new_indent, is_last_child, is_opt_child, target, target_printed, longest_path, either_resources, show_descriptions, annotations, dependents_set, show_kind)
    
    # Print "either" groups at the tail with 🔶 icon
    for group_idx, either_group in enumerate(either_groups):
        is_last_group = (group_idx == len(either_groups) - 1)
        connector = "└── " if is_last_group else "├── "
        print(f"{new_indent}{connector}🔶 choose one:")
        
        group_indent = new_indent + ("    " if is_last_group else "│   ")
        for opt_idx, option in enumerate(either_group):
            is_last_opt = (opt_idx == len(either_group) - 1)
            opt_connector = "└── " if is_last_opt else "├── "
            # Add kind suffix if requested
            opt_kind_suffix = ""
            if show_kind:
                opt_resource = resources.get(option, {})
                opt_kind = opt_resource.get('kind', '')
                if opt_kind:
                    opt_kind_suffix = f" [{opt_kind}]"
            print(f"{group_indent}{opt_connector}{option}{opt_kind_suffix}")
    
    return target_printed

def get_dependents(resources: Dict, resource_name: str) -> List[str]:
    """
    Find resources that depend on the given resource (children/dependents).
    
    Returns resources that have the target in their mandatory requirements.
    """
    dependents = []
    for name, resource in resources.items():
        if name == resource_name:
            continue
        
        res_requires = resource.get('requires', {})
        for dep in res_requires.get('mandatory', []):
            if isinstance(dep, dict):
                dep_name = list(dep.keys())[0]
                if dep_name == resource_name:
                    dependents.append(name)
                    break
            elif dep == resource_name:
                dependents.append(name)
                break
    
    return sorted(dependents)


def get_all_dependents_recursive(resources: Dict, resource_name: str, collected: Set[str] = None) -> Set[str]:
    """
    Recursively find all resources that depend on the given resource (direct and transitive).
    """
    if collected is None:
        collected = set()
    
    direct_dependents = get_dependents(resources, resource_name)
    for dep in direct_dependents:
        if dep not in collected:
            collected.add(dep)
            get_all_dependents_recursive(resources, dep, collected)
    
    return collected


def main():
    if len(sys.argv) < 2:
        print("Usage: check_dependencies.py <resource_name> [--with-descriptions|-d] [--source] [--siblings] [--kind] [--debug]")
        print("\nOptions:")
        print("  <resource_name>        Resource to check dependencies for (required)")
        print("  --with-descriptions    Show resource descriptions in output")
        print("  -d                     Short form of --with-descriptions")
        print("  --source               Show only source dependencies (annotate transitive)")
        print("  --siblings             Include dependents in tree (what depends on target)")
        print("  --kind                 Show resource kind (e.g., oci://resource, oci://module)")
        print("  --debug                Show debug info: why resources are hidden (use with --source)")
        print("\nExamples:")
        print("  ./bin/check_dependencies.py compute_instance")
        print("  ./bin/check_dependencies.py bastion --with-descriptions")
        print("  ./bin/check_dependencies.py subnet -d")
        print("  ./bin/check_dependencies.py zone --source")
        print("  ./bin/check_dependencies.py compute_instance --source --debug")
        print("  ./bin/check_dependencies.py app3_config --kind")
        print("  ./bin/check_dependencies.py compute_instance --source --with-descriptions")
        print("  ./bin/check_dependencies.py app3_config --siblings")
        print("\nAvailable resources:")
        script_dir = Path(__file__).parent
        yaml_path = script_dir.parent / "doc" / "resource_dependencies.yaml"
        if yaml_path.exists():
            with open(yaml_path, 'r') as f:
                data = yaml.safe_load(f)
            resources = data.get('resources', {})
            for name in sorted(resources.keys()):
                print(f"  - {name}")
        sys.exit(1)
    
    resource_name = sys.argv[1]
    show_descriptions = '--with-descriptions' in sys.argv or '-d' in sys.argv
    direct_only = '--source' in sys.argv
    show_siblings = '--siblings' in sys.argv
    show_kind = '--kind' in sys.argv
    debug = '--debug' in sys.argv
    
    # Load YAML file
    script_dir = Path(__file__).parent
    yaml_path = script_dir.parent / "doc" / "resource_dependencies.yaml"
    
    if not yaml_path.exists():
        print(f"Error: {yaml_path} not found")
        sys.exit(1)
    
    resources = load_dependencies(yaml_path)
    
    if resource_name not in resources:
        print(f"Error: Resource '{resource_name}' not found in dependencies file")
        print(f"\nAvailable resources: {', '.join(sorted(resources.keys()))}")
        sys.exit(1)
    
    # Resolve dependencies
    mandatory, optional = resolve_dependencies(resources, resource_name)
    
    # Remove the resource itself from dependencies
    mandatory.discard(resource_name)
    optional.discard(resource_name)
    
    # Print results
    print_dependencies(resource_name, mandatory, optional, resources, show_descriptions, direct_only, debug, show_siblings, show_kind)

if __name__ == '__main__':
    main()
