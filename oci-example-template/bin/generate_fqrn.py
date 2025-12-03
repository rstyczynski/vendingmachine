#!/usr/bin/env python3
"""
Extract module names from Terraform files and output to YAML.
"""

import re
import glob
import sys
import yaml
from pathlib import Path

def extract_modules():
    """Trivial extraction: just get module names."""
    project_root = Path(__file__).parent.parent
    
    data = {'shared_modules': [], 'apps': {}}
    
    # Shared modules - scan all infra_*.tf files
    shared_files = sorted(glob.glob(str(project_root / 'infra_*.tf')))
    shared_files = [Path(f) for f in shared_files]
    
    for shared_file in shared_files:
        if shared_file.exists():
            content = shared_file.read_text()
            for name in re.findall(r'module\s+"([^"]+)"', content):
                # Check if for_each appears after module declaration
                mod_block = content[content.find(f'module "{name}"'):content.find('}', content.find(f'module "{name}"'))]
                # Automatically derive variable name from module name: module_name -> module_name_fqrns
                var_name = f'{name}_fqrns'
                data['shared_modules'].append({
                    'name': name,
                    'var_name': var_name,
                    'for_each': 'for_each' in mod_block
                })
    
    # Application modules - scan all {prefix}_*.tf files (e.g., app1_nsg.tf, myapp_compute.tf, etc.)
    # Group files by their prefix (everything before the first underscore)
    app_files = {}
    for app_file_path in sorted(glob.glob(str(project_root / '*_*.tf'))):
        app_file = Path(app_file_path)
        # Skip infrastructure files
        if app_file.name.startswith('infra_') or app_file.name.startswith('terraform_'):
            continue
        
        # Extract prefix from filename (e.g., app1_nsg.tf -> app1, myapp_compute.tf -> myapp)
        stem = app_file.stem
        if '_' in stem:
            app_key = stem.split('_')[0]
        else:
            continue
        
        if app_key not in app_files:
            app_files[app_key] = []
        app_files[app_key].append(app_file)
    
    # Process all files for each application prefix
    for app_key, files in app_files.items():
        modules = []
        for app_file in files:
            content = Path(app_file).read_text()
            # Find modules that start with the same prefix
            modules.extend([
                {'name': m} for m in re.findall(r'module\s+"([^"]+)"', content) if m.startswith(app_key + '_')
            ])
        if modules:  # Only add if we found modules
            data['apps'][app_key] = modules
    
    return data

def main():
    data = extract_modules()
    
    # Output YAML to stdout
    yaml.dump(data, sys.stdout, default_flow_style=False, sort_keys=False)
    return 0

if __name__ == '__main__':
    sys.exit(main())
