# Subspace DNS

This holds DNS records that are not tied to the resources maintained in the repository.

## How to add a new DNS record?

A new DNS record can be added to records.tf. Here is an example

```
resource "cloudflare_dns_record" "name_of_the_resource" {
  content = "value_of_the_record"
  name    = "name_of_the_resource"
  comment = "comment explaining the record existence"
  proxied = true/false
  tags    = []
  ttl     = 3600
  type    = "CNAME"
  zone_id = data.cloudflare_zone.zone_name.id
  settings = {}
}
```

1. Copy the above example to <domain_name>.tf
2. Update the example resource to meet your requirements.
3. Submit the change as a PR to infra.
4. Infra team will deploy the change and merge the PR.

## How to remove a record?

1. Remove the record from the records.tf
2. Submit the change as a PR to infra repo
3. Infra team will deploy the change and merge the PR.

## How to update existing record?

1. Find the record in the records.tf
2. Update the resource(s) you wish to update
3. Submit the changes as a PR to infra.
4. Infra team will deploy the changes and merge the PR.
