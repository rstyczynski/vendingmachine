# Terraform to build terraform

Template directory contains set of files with common prefix with resource terraform files in template format.

Terraform gets list of resources with parameters to perform templatefile transformation writing transformed files into destination directory.

Example:

Template:
templates/infra_zone.tf.j2
templates/infra_zone.tfvars.j2

Product:
$PWD/infra_zone.tf
$PWD/infra_zone.tfvars
