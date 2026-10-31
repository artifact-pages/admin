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
  # Public Terraform Registry package generated from the monorepo (IMP-38).
  source  = "artifact-pages/artifact-pages/cloudflare"
  version = "0.2.0"

  account_id             = var.cloudflare_account_id
  zone_id                = data.cloudflare_zone.target.zone_id
  bucket_name            = var.r2_bucket_name
  public_hostname        = var.public_hostname
  preview_retention_days = var.preview_retention_days
  connect_custom_domain  = var.connect_custom_domain
  registry_reader        = var.registry_reader
  waf_custom_rules       = var.waf_custom_rules
}

# This resource owns the entire zone-level http_response_cache_settings phase.
# Add any other rules for that phase here rather than in another ruleset.
resource "cloudflare_ruleset" "docs_cache_response" {
  zone_id = data.cloudflare_zone.target.zone_id
  name    = "Artifact Pages docs cache response"
  kind    = "zone"
  phase   = "http_response_cache_settings"

  rules = [{
    ref         = "docs_artifacts_edge_ttl"
    description = "Cache successful Japanese docs artifacts at Cloudflare for one hour"
    expression  = "(http.host eq \"artifact-pages.dev\" and starts_with(http.request.uri.path, \"/_artifacts/ja/\") and (http.response.code eq 200 or http.response.code eq 304))"
    action      = "set_cache_control"
    action_parameters = {
      s_maxage = {
        operation       = "set"
        value           = 3600
        cloudflare_only = true
      }
    }
  }]
}
