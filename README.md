This is an example of a Terraform Configuration scenario that would require SSH
proxying.

It has a somewhat standard VPC setup with 3 public and 3 private subnets, and
an instance launched int the public and private zones.

You can manually SSH through the public instance to get to the private one, but
we'd like to add config to Terraform to allow it to be configure to do that for
provisioning.
