# Zone

Prepare zone module. Zone is identified by FQRN.

Look into oci-examples/doc/resource_dependencies.yaml for fqrn schema information, argument and produced output's attributes.

## Ownership

Zone does not create subnet or bastion - these resources must exist in advance.

## Architecture

Follow all design patterns applied to other modules.

## Template

Add infra_zone template with add_zone script similar to add_compute.

Always add trailing newlines to template files.

## FQRN concatenation script

Follow fqrn_aggregation.md to update fqr aggregation script to handle this resource.


## Usage

add_zone ${name}

name parameter replaces infra_ prefix in the template file.
