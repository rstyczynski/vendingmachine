# change compartment
moved {
  from = module.app4_compute_instances["instance://vm_demo/demo/app4_instance"]
  to = module.app4_compute_instances["instance://vm_demo/demo2/app4_instance"]
}
