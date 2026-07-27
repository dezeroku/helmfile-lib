# helmfile lib

Shared building blocks for helmfile states: gateway routes and their policies,
Vault auth and secrets, and a few whole applications - all as values fragments
for [bjw-s app-template](https://github.com/bjw-s-labs/helm-charts) - plus the
terraform modules that set the matching Vault side up.

Built for the major version 5 of the chart.

## Using it

Check the lib out as a sibling of your helmfile directories, and give it one
file describing your cluster:

```
helmfile/
  cluster.yaml.gotmpl   <- your cluster's answers
  lib/                  <- this repo
  core/                 <- bases: ../lib/base.yaml.gotmpl
  services/             <-  "
```

Releases then opt into blocks by inheriting the templates, before `default` so
that a release's own values file always wins:

```yaml
  - name: metube
    chart: bjw-s-labs/app-template
    version: 5.0.1
    inherit:
      - template: metube
      - template: gateway
      - template: oidc-secret
      - template: default
```

Per-release settings live under `releaseConfig.<release>` in the state's
`environments:` block - routes, secrets and each application block's own knobs.

`DOMAIN` has to be set in the environment; everything is named after it.

## The Vault side

`terraform/` holds the other half of the same contract: the helmfile fragments
read secrets and OIDC clients out of Vault, and these modules are what put them
there. Keeping both in one repo means one version bump moves them together.

```hcl
module "metube" {
  source             = "../lib/terraform/service"
  name               = "metube"
  kubernetes_backend = vault_auth_backend.kubernetes_homeserver.path
  ...
}
```

- `terraform/service` - per service: k8s auth role, policy, kv-v2 secrets,
  optional OIDC client. Its `secrets_mount` / `secrets_path_prefix` /
  `identity_mount` defaults are the same values as `cluster.vault.*`, and have to
  stay that way.
- `terraform/user` - a Vault entity plus its userpass login and lldap user.

Because the whole lib is checked out at the same path in every repository, that
relative `source` resolves in all of them - a second state (a private repo, say)
uses the same module without vendoring it.

## Where to look

- `base.yaml.gotmpl` - the templates on offer, one comment each
- `cluster-defaults.yaml.gotmpl` - every key `cluster.yaml.gotmpl` can set
- `values/*.yaml.gotmpl` - one block each, documented in its header
- `terraform/*/variables.tf` - every module input, documented

Also, take a look at [the example cluster values file](https://github.com/dezeroku/homelab/blob/master/helmfile/cluster.yaml.gotmpl).
The repository itself, especially the `services` directory uses the `lib` helpers heavily.
