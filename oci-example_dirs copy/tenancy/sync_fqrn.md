# Sync FQRN

Navigate trough directories under `tenency`

Directory path under `tenency` is a "compartment path".

In each directory locate assignments in maps of FQRN resource to its definition.

```text
bastions = {
  "bastion://vm_demo/demo/demo_bastion" = {
```

Each occurrence like this process by replacing "vm_demo/demo" to "compartment path".

Keep in master_index.md file mapping:

```csv
resource, old_fqrn, current fqrn
```
