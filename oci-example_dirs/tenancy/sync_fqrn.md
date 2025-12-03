# Sync FQRN

**NOTE**: I do not want to 

Navigate trough directories under `tenency`

Directory path under `tenency` is a "compartment path".

In each directory locate assignments in maps of FQRN resource to its definition.

```text
bastions = {
  "bastion://vm_demo/demo/demo_bastion" = {
```

Each occurrence like this process by replacing "vm_demo/demo" to "compartment path". Update only the keys (FQRN assignments), not the values (references to other resources).

Keep in master_index.md file mapping:

```csv
resource, old_fqrn, current fqrn
```
