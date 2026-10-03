# artifact-pages-admin

Production admin repository for <https://artifact-pages.dev>, the public Git Artifact Pages deployment. It uses the released [Git Artifact Pages](https://github.com/tasuku43/git-artifact-pages) packages the same way any adopter does:

| Part | Here | Consumes |
| --- | --- | --- |
| Registry: which sites exist and which repository may publish each | `artifact-pages.yaml` | `tasuku43/git-artifact-pages/actions/admin@v0.1.2` |
| Web app deployment | `.github/workflows/app-deploy.yml` (manual) | The web bundle pinned by the same Action version |
| Infrastructure: R2 bucket, custom domain, routing, cache, CSP and WAF rules | `terraform/` | `terraform-cloudflare-artifact-pages` at a reviewed commit, moving to the Terraform Registry |

The sites' content lives in their own repositories. `guide` and `architecture` are published from [artifact-pages-docs](https://github.com/tasuku43/artifact-pages-docs).

## Registry

Edit `artifact-pages.yaml`. A pull request runs a dry-run and shows the planned changes in the job summary. Merging to `main` applies them. The file always lists the complete site set: removing a site there unregisters it and deletes its published content.

## App deployment

Run **App deploy** manually from the Actions tab. It defaults to a dry-run. Upgrading the Action version in this repository never deploys the app by itself.

## Infrastructure

Terraform is run by the operator from a workstation:

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars   # then set the real WAF allowlist
mise exec -- terraform init
mise exec -- terraform plan -out=../.local/terraform/plan.tfplan
mise exec -- terraform apply ../.local/terraform/plan.tfplan
```

`terraform/mise.toml` loads `CLOUDFLARE_API_TOKEN` (Terraform token: zone `artifact-pages.dev` rules, DNS and R2 management) from `~/.config/artifact-pages/production.env`. State is local in the ignored `.local/terraform/`. A zone guard fails the plan for any zone other than `artifact-pages.dev`.

## Secrets

The workflows read these three repository-level secrets, shared by the `plan` (dry-run) and `production` environments:

| Secret | Cloudflare permission |
| --- | --- |
| `CF_R2_ACCESS_KEY_ID`, `CF_R2_SECRET_ACCESS_KEY` | R2 key pair for bucket `artifact-pages` (Workers R2 Storage Bucket Item Write) |
| `CF_API_TOKEN` | Cache Purge on zone `artifact-pages.dev` |

While the owner is the only writer, a same-repository PR can reach write credentials; before adding collaborators, give `plan` a read-only R2 key pair as an environment secret, and limit `production` to `main`.
