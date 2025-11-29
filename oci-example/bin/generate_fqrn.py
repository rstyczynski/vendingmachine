#!/usr/bin/env python3
"""
Trivial script: Extract module names, render Jinja2 template.
"""

import re
import glob
from pathlib import Path

try:
    from jinja2 import Template
except ImportError:
    print("Error: jinja2 not installed. Run: pip install jinja2")
    exit(1)

def extract_modules():
    """Trivial extraction: just get module names."""
    project_root = Path(__file__).parent.parent
    
    data = {'shared_modules': [], 'apps': {}}
    
    # Shared modules - trivial: grep for module "name"
    shared_file = project_root / 'infra_network.tf'
    if shared_file.exists():
        content = shared_file.read_text()
        for name in re.findall(r'module\s+"([^"]+)"', content):
            # Trivial: check if for_each appears after module declaration
            mod_block = content[content.find(f'module "{name}"'):content.find('}', content.find(f'module "{name}"'))]
            var_name = {'compartments': 'compartment', 'vcns': 'vcn', 'subnets': 'subnet'}.get(name, name) + '_fqrns'
            data['shared_modules'].append({
                'name': name,
                'var_name': var_name,
                'for_each': 'for_each' in mod_block
            })
    
    # App modules - trivial: grep app*_main.tf files
    for app_file in sorted(glob.glob(str(project_root / 'app*_main.tf'))):
        app_key = Path(app_file).stem.replace('_main', '')  # app1_main.tf -> app1
        content = Path(app_file).read_text()
        data['apps'][app_key] = [
            {'name': m} for m in re.findall(r'module\s+"([^"]+)"', content) if m.startswith(app_key + '_')
        ]
    
    return data

def main():
    # Get project root (parent of bin/)
    project_root = Path(__file__).parent.parent
    template_path = project_root / 'templates' / 'terraform_fqrn.tf.j2'
    output_path = project_root / 'terraform_fqrn.tf'
    
    data = extract_modules()
    template = Template(template_path.read_text())
    output_path.write_text(template.render(**data))
    print('✓ Generated terraform_fqrn.tf')

if __name__ == '__main__':
    main()
