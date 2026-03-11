# keycloak-realm module

This module manages an opinionated Keycloak realm definition so lower environments can be reproduced without manual console work. It assumes the master realm already exists along with credentials that Terraform can use when calling the Keycloak admin API.

## Features

- Creates or updates a realm with the supplied identifier and basic metadata.
- Allows additional realm attributes (for example `frontendUrl`) to be configured declaratively.

## Required Providers

- `mrparkers/keycloak` `>= 4.2.0`

The parent module must configure the provider (URL, credentials, realm=master) and pass it via `providers` when instantiating this module.

## Example

```hcl
data "aws_ssm_parameter" "kc_admin_user" {
  name            = "/agentruntime/dev/keycloak/admin_user"
  with_decryption = true
}

data "aws_ssm_parameter" "kc_admin_password" {
  name            = "/agentruntime/dev/keycloak/admin_password"
  with_decryption = true
}

provider "keycloak" {
  alias    = "dev_master"
  url      = "https://auth-dev.agentruntime.io"
  realm    = "master"
  username = data.aws_ssm_parameter.kc_admin_user.value
  password = data.aws_ssm_parameter.kc_admin_password.value
}

module "keycloak_realm" {
  source = "../../modules/keycloak-realm"

  providers = {
    keycloak = keycloak.dev_master
  }

  realm_id     = "agentruntime-dev"
  display_name = "AgentRuntime Dev"
  frontend_url = "https://auth-dev.agentruntime.io"
  attributes   = {}
}
```

The Keycloak provider still logs in using the credentials defined above; ensure the referenced account retains realm-administrator privileges.

