# Production Terraform

This root stores production state remotely in R2 bucket `artifact-pages-tfstate`, key `admin-production`, with conditional state locking. The S3 backend reads the `[artifact-pages-tfstate]` profile from `~/.config/artifact-pages/tfstate-aws-credentials`; the profile is generated from `~/.config/artifact-pages/tfstate.env` using the safe procedure in the workspace `ops/OPS-004` note. Do not source that R2 env file into Terraform: its `AWS_*` variables can also be selected by the AWS provider. Keep provider and backend credentials separate.

Run from this directory so mise loads the production variables:

```sh
mise exec terraform@1.16.4 -- terraform init
mise exec terraform@1.16.4 -- terraform plan
```

Use a checkout with this remote backend configuration before planning. A stale clone with the former local backend can plan against obsolete local state. Review every production plan; apply remains an owner step.

## Japanese docs edge cache

The response rule caches successful `/_artifacts/ja/` HTML, CSS, and JS at
Cloudflare for one hour without changing the browser cache policy. Updated or
deleted content may remain visible for up to one hour, and the site index's
five-second cache can temporarily disagree with the content. A Cloudflare purge
cannot clear content already stored in a browser cache. Removing the rule alone
does not guarantee that existing Cloudflare cache entries are cleared.

In an emergency, an administrator with Cloudflare zone purge permission can
purge the affected prefix and verify the result; alternatively, wait for the
TTL to expire and verify the result. This procedure has not been verified. The
current tokens do not have purge permission.
