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

def print_dependencies(resource_name: str, mandatory: Set[str], optional: Set[str], resources: Dict, show_descriptions: bool = False, direct_only: bool = False, debug: bool = False, show_siblings: bool = False, show_kind: bool = False, show_type: bool = False):
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
    # Track which resources require each resource and whether those requirements are optional
    # Structure: {resource: {requirer: is_optional}}
    requirement_sources = {}
    # Also track resources that are provided by other resources
    provided_resources = {}
    # First pass: collect all "either" resources to know which resources are optional
    all_either_resources = set()
    optional_resources = set()  # Resources that are in "either" groups
    for node_name, node_data in tree.items():
        either_res = node_data.get('either_resources', set())
        all_either_resources.update(either_res)
        for either_group in node_data.get('either', []):
            for opt in either_group:
                optional_resources.add(opt)
    
    # Second pass: build depends_on and requirement_sources
    # Mark requirements from optional resources as optional
    for node_name, node_data in tree.items():
        is_node_optional = node_name in optional_resources
        for dep in node_data.get('mandatory', []):
            if dep not in depends_on:
                depends_on[dep] = []
            depends_on[dep].append((node_name, False))
            # Track that this is a requirement
            # If the requirer is optional, mark the requirement as optional
            if dep not in requirement_sources:
                requirement_sources[dep] = {}
            requirement_sources[dep][node_name] = is_node_optional  # True if requirer is optional
        # Also track optional dependencies for determining if a resource should be optional
        for dep in node_data.get('optional', []):
            if dep not in requirement_sources:
                requirement_sources[dep] = {}
            requirement_sources[dep][node_name] = True
        # Track "either" resources as optional (they're choices)
        # Also track what resources in "either" groups require - those should be optional too
        for either_group in node_data.get('either', []):
            for opt in either_group:
                if opt not in requirement_sources:
                    requirement_sources[opt] = {}
                requirement_sources[opt][node_name] = True  # Either groups are optional
                # Also track what this "either" option requires - those should also be optional
                # because the "either" option itself is optional
                opt_resource = resources.get(opt, {})
                opt_requires = opt_resource.get('requires', {})
                for opt_dep in opt_requires.get('mandatory', []):
                    if isinstance(opt_dep, dict):
                        opt_dep_name = list(opt_dep.keys())[0]
                        if opt_dep_name != 'either':
                            if opt_dep_name not in requirement_sources:
                                requirement_sources[opt_dep_name] = {}
                            # Mark as optional because it's required by an optional "either" option
                            requirement_sources[opt_dep_name][opt] = True
                    else:
                        if opt_dep not in requirement_sources:
                            requirement_sources[opt_dep] = {}
                        # Mark as optional because it's required by an optional "either" option
                        requirement_sources[opt_dep][opt] = True
        # Collect either resources
        either_res = node_data.get('either_resources', set())
        all_either_resources.update(either_res)
        # Optional deps are NOT added to depends_on - they're shown under their parent with 🔹
    
    # Also add resources that are provided by other resources to depends_on
    # and track who actually requires them
    for res_name, res_data in resources.items():
        provides_list = res_data.get('provides', [])
        for provided in provides_list:
            # Add provided resource as a child of the provider
            # (if contract provides realm, realm depends on contract, so realm is child of contract)
            if res_name not in depends_on:
                depends_on[res_name] = []
            if (provided, False) not in depends_on[res_name]:
                depends_on[res_name].append((provided, False))
            # Track that this resource provides the other
            if provided not in provided_resources:
                provided_resources[provided] = []
            provided_resources[provided].append(res_name)
    
    # Also add target resource to depends_on if it has dependencies
    if resource_name in tree:
        for dep in tree[resource_name].get('mandatory', []):
            if dep not in depends_on:
                depends_on[dep] = []
            depends_on[dep].append((resource_name, False))
            # Track requirement
            if dep not in requirement_sources:
                requirement_sources[dep] = {}
            requirement_sources[dep][resource_name] = False
        # Track optional deps for requirement tracking
        for dep in tree[resource_name].get('optional', []):
            if dep not in requirement_sources:
                requirement_sources[dep] = {}
            requirement_sources[dep][resource_name] = True
        # Track either groups
        for either_group in tree[resource_name].get('either', []):
            for opt in either_group:
                if opt not in requirement_sources:
                    requirement_sources[opt] = {}
                requirement_sources[opt][resource_name] = True
    
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
            
            # First, check what this resource provides (before adding self-provision)
            provides_list = res_data.get('provides', [])
            for provided in provides_list:
                if provided not in annotations:
                    annotations[provided] = f"(provided by {res_name})"
            
            # Trace its requirements (both mandatory and optional) to find transitive provides
            requires = res_data.get('requires', {})
            for item in requires.get('mandatory', []):
                if isinstance(item, dict):
                    if 'either' not in item:
                        req = list(item.keys())[0]
                        trace_provides(req, visited)
                else:
                    trace_provides(item, visited)
            
            # Also trace optional requirements
            for item in requires.get('optional', []):
                if isinstance(item, dict):
                    if 'either' not in item:
                        req = list(item.keys())[0]
                        trace_provides(req, visited)
                else:
                    trace_provides(item, visited)
        
        # First trace from the target resource itself (to capture what it provides)
        trace_provides(resource_name, set())
        
        # Then trace from all direct deps
        for dep in direct_mandatory | direct_optional | direct_either_flat:
            trace_provides(dep, set())
        
        # After tracing all provides relationships, add self-provision for resources
        # that aren't provided by anything else
        for res_name in resources.keys():
            if res_name not in annotations:
                annotations[res_name] = f"(provided by {res_name})"
        
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
            target_printed = print_tree_node(resources, root, tree, depends_on, visited.copy(), "", is_last_root, False, resource_name, target_printed, longest_path, all_either_resources, show_descriptions, annotations, dependents_set, show_kind, show_type, requirement_sources)
    
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
    show_kind: bool = False,
    show_type: bool = False,
    requirement_sources: Dict = None
) -> bool:
    """Recursively print a tree node showing dependencies top to bottom. Returns True if target was printed."""
    if either_resources is None:
        either_resources = set()
    if annotations is None:
        annotations = {}
    if dependents_set is None:
        dependents_set = set()
    if requirement_sources is None:
        requirement_sources = {}
    
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
    
    # Check if this resource is only needed by optional paths
    # If it's only required by optional resources, mark it as optional
    # This applies even if the resource is provided by a mandatory resource
    if not is_optional and resource_name in requirement_sources:
        all_optional = True
        for requirer, is_opt in requirement_sources[resource_name].items():
            if not is_opt:
                all_optional = False
                break
        if all_optional and len(requirement_sources[resource_name]) > 0:
            is_optional = True
    
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
    
    # Build type suffix if requested
    type_suffix = ""
    if show_type:
        res_type = resource.get('type', '')
        if res_type:
            type_suffix = f" <{res_type}>"
    
    if show_descriptions:
        desc = resource.get('description', 'N/A')
        print(f"{indent}{connector}{marker} {prefix}{resource_name:20s}{kind_suffix}{type_suffix}{annotation} - {desc}")
    else:
        print(f"{indent}{connector}{marker} {prefix}{resource_name}{kind_suffix}{type_suffix}{annotation}")
    
    # Get children (what depends on this resource)
    children = depends_on.get(resource_name, [])
    
    # If target is already printed, don't show it again as a child
    if target_printed:
        children = [(c, opt) for c, opt in children if c != target]
    
    # Filter children: only show if all their mandatory dependencies are satisfied
    # EXCEPT for the target resource which should always be shown
    # Also show children that are in the longest path to target
    def can_show_child(child_name: str) -> bool:
        """Check if a child can be shown (all its mandatory dependencies are satisfied)."""
        # Always show the target resource
        if child_name == target:
            return True
        # Always show resources in the longest path to target
        if longest_path and child_name in longest_path:
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
    def get_depth_from_root(resource: str, visited_set: Set[str], depth_visited: Set[str] = None) -> int:
        """Get the depth of a resource from root (0 = root, 1 = depends on root, etc.)."""
        if depth_visited is None:
            depth_visited = set()
        # Prevent infinite recursion
        if resource in depth_visited:
            return 0
        depth_visited.add(resource)
        
        deps = tree.get(resource, {})
        mandatory_deps = deps.get('mandatory', [])
        if not mandatory_deps:
            return 0  # Root level
        
        # Find the maximum depth of all dependencies
        max_depth = 0
        for dep in mandatory_deps:
            if dep in visited_set:
                dep_depth = get_depth_from_root(dep, visited_set, depth_visited.copy())
                max_depth = max(max_depth, dep_depth)
        return max_depth + 1
    
    def is_most_specific_parent(child_name: str) -> bool:
        """Check if this resource is the most specific parent for the child."""
        child_deps = tree.get(child_name, {})
        mandatory_deps = set(child_deps.get('mandatory', []))
        
        # Check if this child is provided by another resource
        # If so, it should ONLY appear under its provider (not under other parents)
        # UNLESS the child has other mandatory dependencies besides the provider
        provider = None
        for res_name, res_data in resources.items():
            if child_name in res_data.get('provides', []):
                provider = res_name
                break
        
        if provider is not None:
            # This child is provided by 'provider'
            # Check if child has dependencies besides the provider
            other_deps = mandatory_deps - {provider}
            
            if not other_deps:
                # Child only depends on provider (or has no deps) - show under provider only
                if provider == resource_name:
                    return True  # We ARE the provider
                elif provider in tree:
                    return False  # Provider is in tree, will show there
            # else: Child has other dependencies, use normal logic
        
        # Not a provided resource (or has other deps) - use normal logic
        if resource_name not in mandatory_deps:
            return False  # This resource is not even a dependency of the child
        
        # Check if another parent of the child is in the longest path to target
        # If so, prefer that parent over this one
        if longest_path and resource_name not in longest_path:
            for other_parent in mandatory_deps:
                if other_parent == resource_name:
                    continue
                if other_parent in longest_path and other_parent in tree:
                    # other_parent is in the path to target, prefer it
                    return False
        
        # Check if this resource is provided by another resource
        # If so, prefer non-provided siblings as parents for the child
        is_this_provided = any(resource_name in res_data.get('provides', []) for res_data in resources.values())
        
        # Check if there's another non-provided sibling that is also a parent of the child
        # and would be a better parent (same level but not provided)
        if is_this_provided:
            for other_parent in mandatory_deps:
                if other_parent == resource_name:
                    continue
                # Is other_parent NOT provided?
                is_other_provided = any(other_parent in res_data.get('provides', []) for res_data in resources.values())
                if not is_other_provided and other_parent in tree:
                    # other_parent is not provided and is in tree - it's a better parent
                    return False
            
            # All other parents are also provided - check which one is in longest path
            # Prefer the one in the longest path
            if longest_path:
                this_in_path = resource_name in longest_path
                for other_parent in mandatory_deps:
                    if other_parent == resource_name:
                        continue
                    other_in_path = other_parent in longest_path
                    if other_in_path and not this_in_path:
                        # other_parent is in path, this is not - prefer other_parent
                        return False
                    elif this_in_path and other_in_path:
                        # Both in path - prefer the one that comes later (more specific)
                        try:
                            this_idx = longest_path.index(resource_name)
                            other_idx = longest_path.index(other_parent)
                            if other_idx > this_idx:
                                return False
                        except ValueError:
                            pass
        
        this_resource_deps = tree.get(resource_name, {})
        this_resource_mandatory = set(this_resource_deps.get('mandatory', []))
        
        # Check if any other VISITED resource is also a dependency and is more specific
        # Only filter if the more specific parent was already visited (so child was shown there)
        for other_parent in visited:
            if other_parent == resource_name:
                continue
            if other_parent in mandatory_deps:
                # If this resource depends on other_parent, then this resource is more specific
                if other_parent in this_resource_mandatory:
                    continue  # This resource is more specific, don't filter out
                # Check if other_parent depends on this resource (making other_parent more specific)
                other_parent_deps = tree.get(other_parent, {})
                other_parent_mandatory = set(other_parent_deps.get('mandatory', []))
                if resource_name in other_parent_mandatory:
                    return False  # other_parent is more specific and was already visited
        
        return True
    
    # Filter to only show children where this is the most specific parent
    children = [(c, opt) for c, opt in children if is_most_specific_parent(c)]
    
    # Check if children should be marked as optional based on requirement_sources
    # If a resource is only required by optional resources, mark it as optional
    processed_children = []
    for c, opt in children:
        # If already marked as optional, keep it
        if opt:
            processed_children.append((c, True))
        # Otherwise, check if it's only required by optional resources
        elif c in requirement_sources:
            all_optional = True
            for requirer, is_opt in requirement_sources[c].items():
                if not is_opt:
                    all_optional = False
                    break
            if all_optional and len(requirement_sources[c]) > 0:
                processed_children.append((c, True))
            else:
                processed_children.append((c, False))
        else:
            processed_children.append((c, False))
    
    # Separate mandatory and optional children
    mandatory_children = [(c, False) for c, opt in processed_children if not opt]
    optional_children = [(c, True) for c, opt in processed_children if opt]
    
    # Check which children are provided by this resource
    resource_provides = set(resources.get(resource_name, {}).get('provides', []))
    
    # Sort children so that:
    # 1. Optional children NOT provided (top)
    # 2. Optional dependencies OF this resource
    # 3. ALL provided children (optional AND mandatory) - they belong to this resource
    # 4. Mandatory children NOT provided, NOT in path to target
    # 5. Mandatory children in path to target (leads to target)
    # 6. Target resource at very bottom
    child_names = set(c for c, _ in mandatory_children + optional_children)
    def get_child_priority(child_tuple):
        child_name, is_opt = child_tuple
        # Check how many other children depend on this child
        child_deps = tree.get(child_name, {}).get('mandatory', [])
        # Count how many siblings are parents of this child
        parents_among_siblings = sum(1 for dep in child_deps if dep in child_names)
        is_provided = child_name in resource_provides
        is_target_resource = (child_name == target)
        is_in_path = longest_path and child_name in longest_path
        # Priority order:
        # 0 = optional NOT provided (top)
        # 1 = provided (both optional and mandatory) - belong to this resource
        # 2 = mandatory NOT provided, NOT in path to target
        # 3 = mandatory in path to target (leads to target)
        # 4 = target resource (very bottom)
        if is_target_resource:
            group = 4
        elif is_in_path and not is_opt:
            group = 3
        elif is_provided:
            group = 1
        elif is_opt:
            group = 0
        else:
            group = 2
        return (group, parents_among_siblings, child_name)
    
    mandatory_children.sort(key=get_child_priority)
    optional_children.sort(key=get_child_priority)
    
    # Calculate new indent
    new_indent = indent + ("    " if is_last else "│   ")
    
    # Combine all children in proper order
    seen = set()
    all_children = []
    
    # First: Optional children NOT provided by this resource
    for c, _ in optional_children:
        if c not in seen and c not in resource_provides:
            seen.add(c)
            all_children.append((c, True))
    
    # Second: This resource's own optional dependencies (what this resource optionally needs)
    resource_optional_deps = tree.get(resource_name, {}).get('optional', [])
    for opt_dep in sorted(resource_optional_deps):
        if opt_dep not in seen and opt_dep not in visited:
            seen.add(opt_dep)
            all_children.append((opt_dep, True))
    
    # Third: ALL provided children (optional and mandatory) - they belong to this resource
    for c, opt in optional_children + mandatory_children:
        if c not in seen and c in resource_provides:
            seen.add(c)
            all_children.append((c, opt))
    
    # Fourth: Mandatory children NOT provided and NOT target
    for c, _ in mandatory_children:
        if c not in seen and c != target:
            seen.add(c)
            all_children.append((c, False))
    
    # Fifth: Target resource at very bottom
    for c, _ in mandatory_children:
        if c not in seen and c == target:
            seen.add(c)
            all_children.append((c, False))
    
    # Get "either" groups for this resource
    either_groups = tree.get(resource_name, {}).get('either', [])
    
    # Filter out children that are already visited (won't be printed)
    # Also filter out children that will be shown under a sibling (more specific parent or provider)
    def will_be_shown_under_sibling(child_name: str) -> bool:
        """Check if this child will be shown under a sibling instead of here."""
        child_deps = tree.get(child_name, {}).get('mandatory', [])
        child_names_set = set(c for c, _ in all_children)
        for sibling in child_names_set:
            if sibling == child_name:
                continue
            # Is sibling a dependency of child? (sibling is more specific parent)
            if sibling in child_deps:
                return True
            # Does sibling provide this child? (child will be shown under sibling)
            sibling_provides = resources.get(sibling, {}).get('provides', [])
            if child_name in sibling_provides:
                return True
        return False
    
    printable_children = [(c, opt) for c, opt in all_children 
                          if c not in visited and not will_be_shown_under_sibling(c)]
    
    # Print all children
    for i, (child, is_opt_child) in enumerate(printable_children):
        # Check if there are either groups after this child
        has_either = len(either_groups) > 0
        is_last_child = (i == len(printable_children) - 1) and not has_either
        target_printed = print_tree_node(resources, child, tree, depends_on, visited, new_indent, is_last_child, is_opt_child, target, target_printed, longest_path, either_resources, show_descriptions, annotations, dependents_set, show_kind, show_type, requirement_sources)
    
    # Print "either" groups at the tail with 🔶 icon
    for group_idx, either_group in enumerate(either_groups):
        is_last_group = (group_idx == len(either_groups) - 1)
        connector = "└── " if is_last_group else "├── "
        print(f"{new_indent}{connector}🔶 choose one:")
        
        group_indent = new_indent + ("    " if is_last_group else "│   ")
        for opt_idx, option in enumerate(either_group):
            is_last_opt = (opt_idx == len(either_group) - 1)
            opt_connector = "└── " if is_last_opt else "├── "
            opt_resource = resources.get(option, {})
            # Add kind suffix if requested
            opt_kind_suffix = ""
            if show_kind:
                opt_kind = opt_resource.get('kind', '')
                if opt_kind:
                    opt_kind_suffix = f" [{opt_kind}]"
            # Add type suffix if requested
            opt_type_suffix = ""
            if show_type:
                opt_type = opt_resource.get('type', '')
                if opt_type:
                    opt_type_suffix = f" <{opt_type}>"
            # Add annotation if available
            opt_annotation = annotations.get(option, "")
            if opt_annotation:
                opt_annotation = f" {opt_annotation}"
            print(f"{group_indent}{opt_connector}{option}{opt_kind_suffix}{opt_type_suffix}{opt_annotation}")
    
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
        print("Usage: check_dependencies.py [options] <resource_name>")
        print("\nOptions:")
        print("  <resource_name>        Resource to check dependencies for (required)")
        print("  --with-descriptions    Show resource descriptions in output")
        print("  -d                     Short form of --with-descriptions")
        print("  --source               Show only source dependencies (annotate transitive)")
        print("  --siblings             Include dependents in tree (what depends on target)")
        print("  --kind                 Show resource kind (e.g., oci://resource, oci://module)")
        print("  --type                 Show resource type (e.g., bin/terraform, config/yaml)")
        print("  --debug                Show debug info: why resources are hidden (use with --source)")
        print("\nExamples:")
        print("  ./bin/check_dependencies.py compute_instance")
        print("  ./bin/check_dependencies.py bastion --with-descriptions")
        print("  ./bin/check_dependencies.py subnet -d")
        print("  ./bin/check_dependencies.py zone --source")
        print("  ./bin/check_dependencies.py --source --with-descriptions vcn")
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
    
    # Parse arguments: find resource name (first non-flag argument) and flags
    known_flags = {'--with-descriptions', '-d', '--source', '--siblings', '--kind', '--type', '--debug'}
    resource_name = None
    for arg in sys.argv[1:]:
        if arg not in known_flags:
            resource_name = arg
            break
    
    if not resource_name:
        print("Error: Resource name is required")
        print("Usage: check_dependencies.py [options] <resource_name>")
        sys.exit(1)
    
    show_descriptions = '--with-descriptions' in sys.argv or '-d' in sys.argv
    direct_only = '--source' in sys.argv
    show_siblings = '--siblings' in sys.argv
    show_kind = '--kind' in sys.argv
    show_type = '--type' in sys.argv
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
    print_dependencies(resource_name, mandatory, optional, resources, show_descriptions, direct_only, debug, show_siblings, show_kind, show_type)

if __name__ == '__main__':
    main()
