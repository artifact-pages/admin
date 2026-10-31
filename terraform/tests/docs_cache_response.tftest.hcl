mock_provider "cloudflare" {
  mock_data "cloudflare_zone" {
    defaults = {
      name = "artifact-pages.dev"
    }
  }
}

run "docs_cache_response" {
  command = plan

  variables {
    cloudflare_account_id  = "00000000000000000000000000000000"
    cloudflare_zone_id     = "00000000000000000000000000000000"
    public_hostname        = "artifact-pages.dev"
    preview_retention_days = 7
  }

  assert {
    condition     = cloudflare_ruleset.docs_cache_response.phase == "http_response_cache_settings" && cloudflare_ruleset.docs_cache_response.kind == "zone"
    error_message = "The docs rule must own the zone response-cache phase."
  }

  assert {
    condition     = length(cloudflare_ruleset.docs_cache_response.rules) == 1 && cloudflare_ruleset.docs_cache_response.rules[0].expression == "(http.host eq \"artifact-pages.dev\" and starts_with(http.request.uri.path, \"/_artifacts/ja/\") and (http.response.code eq 200 or http.response.code eq 304))"
    error_message = "The rule must target only successful Japanese docs artifact responses on the production host."
  }

  assert {
    condition     = cloudflare_ruleset.docs_cache_response.rules[0].action == "set_cache_control" && cloudflare_ruleset.docs_cache_response.rules[0].action_parameters.s_maxage.operation == "set" && cloudflare_ruleset.docs_cache_response.rules[0].action_parameters.s_maxage.value == 3600 && cloudflare_ruleset.docs_cache_response.rules[0].action_parameters.s_maxage.cloudflare_only == true
    error_message = "The rule must set only Cloudflare's shared cache lifetime to one hour."
  }
}
