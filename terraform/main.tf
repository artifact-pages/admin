# Guard: refuse any zone other than the production zone, so a shell holding
# verification credentials cannot plan changes here by mistake.
data "cloudflare_zone" "target" {
  zone_id = var.cloudflare_zone_id

  lifecycle {
    postcondition {
      condition     = self.name == var.expected_zone_name
      error_message = "cloudflare_zone_id does not belong to the production zone artifact-pages.dev."
    }
  }
}

module "artifact_pages" {
  # Pin the generated module package to the tag synced from the monorepo (IMP-64).
  source = "git::https://github.com/artifact-pages/terraform-cloudflare-artifact-pages.git?ref=v0.1.0"

  account_id             = var.cloudflare_account_id
  zone_id                = data.cloudflare_zone.target.zone_id
  bucket_name            = var.r2_bucket_name
  public_hostname        = var.public_hostname
  preview_retention_days = var.preview_retention_days
  connect_custom_domain  = var.connect_custom_domain
  registry_reader        = var.registry_reader
  waf_custom_rules       = var.waf_custom_rules
}
