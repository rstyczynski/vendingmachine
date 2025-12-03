# Wrapper module that handles compartment creation level by level
# This hides the complexity of creating nested compartments from the user

# Compute all compartment levels from FQRNs (including intermediate levels)
locals {
  # Normalize compartment FQRNs: remove leading slashes after cmp://
  # Example: "cmp:///vm_demo/demo" -> "cmp://vm_demo/demo"
  normalized_compartment_fqrns = {
    for fqrn, config in var.compartments :
    "cmp://${join("/", [for s in split("/", trimprefix(fqrn, "cmp://")) : s if s != ""])}" => config
  }

  # Pre-compute path segments for each normalized FQRN (needed before all_compartment_fqrns)
  compartment_path_segments = {
    for fqrn in keys(local.normalized_compartment_fqrns) :
    fqrn => [for s in split("/", trimprefix(fqrn, "cmp://")) : s if s != ""]
  }

  # Extract all intermediate compartment paths from normalized FQRNs
  # Example: "cmp://vm_demo/demo" -> ["cmp://vm_demo", "cmp://vm_demo/demo"]
  all_compartment_fqrns = merge([
    for fqrn, config in local.normalized_compartment_fqrns : {
      # Generate all intermediate FQRNs for this path
      # Use pre-computed path segments (defined above)
      for i in range(1, length(local.compartment_path_segments[fqrn]) + 1) :
      "cmp://${join("/", slice(local.compartment_path_segments[fqrn], 0, i))}" => {
        description   = i == length(local.compartment_path_segments[fqrn]) ? config.description : "Intermediate compartment level"
        enable_delete = i == length(local.compartment_path_segments[fqrn]) ? config.enable_delete : false
      }
    }
  ]...)

  # Pre-compute path segments for ALL FQRNs (normalized + intermediates)
  # This must be computed after all_compartment_fqrns, so we compute it for all keys
  compartment_path_segments_all = {
    for fqrn in keys(local.all_compartment_fqrns) :
    fqrn => [for s in split("/", trimprefix(fqrn, "cmp://")) : s if s != ""]
  }

  # Compute parent FQRN for each compartment
  compartment_parent_fqrns = {
    for fqrn in keys(local.all_compartment_fqrns) : fqrn => (
      length(local.compartment_path_segments_all[fqrn]) > 1 ? (
        "cmp://${join("/", slice(local.compartment_path_segments_all[fqrn], 0, length(local.compartment_path_segments_all[fqrn]) - 1))}"
      ) : (
        null  # Root-level compartment (depth 1)
      )
    )
  }

  # Compute depth for each compartment (for ordering)
  # Depth = number of path segments after cmp:// (normalized, excluding empty strings)
  compartment_depths = {
    for fqrn in keys(local.all_compartment_fqrns) : fqrn => length(local.compartment_path_segments_all[fqrn])
  }
}

# Create compartments level by level to avoid dependency cycles
# Level 1 compartments (directly under tenancy)
module "compartment_level_1" {
  source   = "../compartment"
  for_each = {
    for fqrn, config in local.all_compartment_fqrns : fqrn => config
    if local.compartment_depths[fqrn] == 1
  }

  tenancy_ocid          = var.tenancy_ocid
  parent_compartment_id = var.tenancy_ocid
  name                  = each.key
  description           = each.value.description
  enable_delete         = each.value.enable_delete
}

# Level 2 compartments (under level 1)
module "compartment_level_2" {
  source   = "../compartment"
  for_each = {
    for fqrn, config in local.all_compartment_fqrns : fqrn => config
    if local.compartment_depths[fqrn] == 2
  }

  tenancy_ocid = var.tenancy_ocid
  # Parent is always at level 1
  parent_compartment_id = module.compartment_level_1[local.compartment_parent_fqrns[each.key]].id
  name                  = each.key
  description           = each.value.description
  enable_delete         = each.value.enable_delete

  depends_on = [module.compartment_level_1]
}

# Level 3 compartments
module "compartment_level_3" {
  source   = "../compartment"
  for_each = {
    for fqrn, config in local.all_compartment_fqrns : fqrn => config
    if local.compartment_depths[fqrn] == 3
  }

  tenancy_ocid = var.tenancy_ocid
  # Parent is at level 1 or 2
  parent_compartment_id = (
    local.compartment_depths[local.compartment_parent_fqrns[each.key]] == 1 ? (
      module.compartment_level_1[local.compartment_parent_fqrns[each.key]].id
    ) : (
      module.compartment_level_2[local.compartment_parent_fqrns[each.key]].id
    )
  )
  name         = each.key
  description  = each.value.description
  enable_delete = each.value.enable_delete

  depends_on = [
    module.compartment_level_1,
    module.compartment_level_2
  ]
}

# Helper local to resolve compartment OCIDs from levels 1-3
locals {
  compartment_ocid_by_fqrn_levels_1_3 = merge(
    { for k, v in module.compartment_level_1 : k => v.id },
    { for k, v in module.compartment_level_2 : k => v.id },
    { for k, v in module.compartment_level_3 : k => v.id }
  )
}

# Level 4 compartments
module "compartment_level_4" {
  source   = "../compartment"
  for_each = {
    for fqrn, config in local.all_compartment_fqrns : fqrn => config
    if local.compartment_depths[fqrn] == 4
  }

  tenancy_ocid = var.tenancy_ocid
  # Parent is at level 1, 2, or 3
  parent_compartment_id = (
    contains(keys(local.compartment_ocid_by_fqrn_levels_1_3), local.compartment_parent_fqrns[each.key]) ? (
      local.compartment_ocid_by_fqrn_levels_1_3[local.compartment_parent_fqrns[each.key]]
    ) : (
      var.tenancy_ocid
    )
  )
  name         = each.key
  description  = each.value.description
  enable_delete = each.value.enable_delete

  depends_on = [
    module.compartment_level_1,
    module.compartment_level_2,
    module.compartment_level_3
  ]
}

# Helper local to resolve compartment OCIDs from levels 1-4
locals {
  compartment_ocid_by_fqrn_levels_1_4 = merge(
    local.compartment_ocid_by_fqrn_levels_1_3,
    { for k, v in module.compartment_level_4 : k => v.id }
  )
}

# Level 5 compartments
module "compartment_level_5" {
  source   = "../compartment"
  for_each = {
    for fqrn, config in local.all_compartment_fqrns : fqrn => config
    if local.compartment_depths[fqrn] == 5
  }

  tenancy_ocid = var.tenancy_ocid
  # Parent is at level 1, 2, 3, or 4
  parent_compartment_id = (
    contains(keys(local.compartment_ocid_by_fqrn_levels_1_4), local.compartment_parent_fqrns[each.key]) ? (
      local.compartment_ocid_by_fqrn_levels_1_4[local.compartment_parent_fqrns[each.key]]
    ) : (
      var.tenancy_ocid
    )
  )
  name         = each.key
  description  = each.value.description
  enable_delete = each.value.enable_delete

  depends_on = [
    module.compartment_level_1,
    module.compartment_level_2,
    module.compartment_level_3,
    module.compartment_level_4
  ]
}

# Helper local to resolve compartment OCIDs from levels 1-5
locals {
  compartment_ocid_by_fqrn_levels_1_5 = merge(
    local.compartment_ocid_by_fqrn_levels_1_4,
    { for k, v in module.compartment_level_5 : k => v.id }
  )
}

# Level 6 compartments (maximum depth in OCI)
module "compartment_level_6" {
  source   = "../compartment"
  for_each = {
    for fqrn, config in local.all_compartment_fqrns : fqrn => config
    if local.compartment_depths[fqrn] == 6
  }

  tenancy_ocid = var.tenancy_ocid
  # Parent is at level 1, 2, 3, 4, or 5
  parent_compartment_id = (
    contains(keys(local.compartment_ocid_by_fqrn_levels_1_5), local.compartment_parent_fqrns[each.key]) ? (
      local.compartment_ocid_by_fqrn_levels_1_5[local.compartment_parent_fqrns[each.key]]
    ) : (
      var.tenancy_ocid
    )
  )
  name         = each.key
  description  = each.value.description
  enable_delete = each.value.enable_delete

  depends_on = [
    module.compartment_level_1,
    module.compartment_level_2,
    module.compartment_level_3,
    module.compartment_level_4,
    module.compartment_level_5
  ]
}

