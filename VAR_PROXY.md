# Variable proxy

Variables are never passed directly to module or any other TF code that a proxy layer.

Variable proxy layer transforms variables into locals that are used by module or any other TF code.

Proxy layer may be modified by user to augment variables as necessary having access ot HCL methods.

Keep proxy logic in file *_var2hcl.tf

Proxied variables name *_var2hcl

