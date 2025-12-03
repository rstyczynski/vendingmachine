# Master Index - FQRN Mapping

Tracks FQRN changes when synchronizing compartment paths.

## team1

Replaced `vm_demo/demo` → `team1`

```csv
resource_type,old_fqrn,current_fqrn
compartment,cmp:///vm_demo/demo,cmp:///team1
vcn,vcn://vm_demo/demo/demo_vcn,vcn://team1/demo_vcn
subnet,sub://vm_demo/demo/demo_vcn/subnet,sub://team1/demo_vcn/subnet
bastion,bastion://vm_demo/demo/demo_bastion,bastion://team1/demo_bastion
log_group,log_group://vm_demo/demo/demo_log_group,log_group://team1/demo_log_group
zone,zone://vm_demo/demo/infra,zone://team1/infra
nsg,nsg://vm_demo/demo/demo_vcn/ssh,nsg://team1/demo_vcn/ssh
nsg,nsg://vm_demo/demo/demo_vcn/app2_web,nsg://team1/demo_vcn/app2_web
instance,instance://vm_demo/demo/app1_instance,instance://team1/app1_instance
```

## Sync Date

- **team1**: 2024-12-01

