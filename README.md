# oshell
[![CI](https://github.com/cnopslabs/oshell/actions/workflows/ci.yml/badge.svg)](https://github.com/cnopslabs/oshell/actions/workflows/ci.yml)

Helper shell utilities for OCI CLI and [oshiv](https://github.com/cnopslabs/oshiv). This tool simplifies working with multiple OCI tenancies, compartments, and profiles.

## Features

- Authenticate to OCI with different profiles
- Automatic session refreshing to maintain authentication
- Easy switching between tenancies and compartments
- Manage OCI environment variables
- Shell prompt integration showing current OCI context

## Prerequisites

### OCI CLI

The Oracle Cloud Infrastructure Command Line Interface (OCI CLI) is required.

[Install OCI CLI](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

### oshiv

oshiv is a companion tool that provides simplified OCI resource management.

[Install oshiv](https://github.com/cnopslabs/oshiv#install-oshiv)

## Installation

### 1. Clone this repository

```bash
git clone https://github.com/cnopslabs/oshell
```

### 2. Configure Tenancy Map (Recommended)

Create an OCI tenancy mappings file. The tenancy map allows `oshiv` to quickly print the tenant and compartment details you use most often.

```bash
cp tenancy-map.yaml $HOME/.oci
```

Update `$HOME/.oci/tenancy-map.yaml` with your tenancies and compartments.

<details>

<summary>Example tenancy map</summary>

```yaml
---
- environment: My Foo Dev Env
  tenancy: foo_dev
  tenancy_id: ocid1.tenancy.oc1..abcdefghijklmnopqrstuvwxyz1234567890
  realm: OC1
  compartments: foo_dev_dp foo_dev_cp dev_sec_ops
  regions: us-chicago-1 us-ashburn-1

- environment: My Bar Dev Env
  tenancy: bar_dev
  tenancy_id: ocid1.tenancy.oc1..abcdefghijklmnopqrstuvwxyz0987654321
  realm: OC1
  compartments: bar_dev_data_plane dev_sec_ops
  regions: us-chicago-1

- environment: My Foo Production Env
  tenancy: bar_prod
  tenancy_id: ocid1.tenancy.oc1..abcdefghijklmnopqrstuvwxyz5678901234
  realm: OC1
  compartments: foo_data_plane dev_sec_ops
  regions: us-chicago-1 us-ashburn-1

- environment: My Foo QA Gov Env
  tenancy: foo_qa_gov
  tenancy_id: ocid1.tenancy.oc2..abcdefghijklmnopqrstuvwxyz5432109876
  realm: OC2
  compartments: foo_gov_qa_cp foo_gov_qa_dp
  regions: us-ashburn-1

- environment: My Foo Prod Gov Env
  tenancy: foo_prod_gov
  tenancy_id: ocid1.tenancy.oc2..abcdefghijklmnopqrstuvwxyz1357924680
  realm: OC2
  compartments: foo_gov_prod_cp foo_gov_prod_dp
  regions: us-ashburn-1 us-phoenix-1
```

</details>

### 3. Add oshell to your ZSH configuration

Update your ZSH initialization file (`$HOME/.zshrc`) with:

```bash
# Set the path to your oshell installation
export OSHELL_HOME=/path/to/oshell
source $OSHELL_HOME/oshell.sh
```

<details>
<summary>Example .zshrc configuration</summary>

```bash
# oshell configuration
export OSHELL_HOME=$HOME/github/cnopslabs/oshell
source $OSHELL_HOME/oshell.sh
```

For shell prompt integration, see the included `.zshrc_EXAMPLE.sh` file.
</details>

## Usage

oshell provides several commands to manage your OCI authentication and environment:

| Command | Alias | Description |
|---------|-------|-------------|
| `oci_authenticate [profile]` | `ociauth` | Authenticate to OCI with the specified profile |
| `oci_auth_logout` | `ociexit` | Log out of the current OCI session |
| `oci_set_profile <profile>` | `ociset` | Set the current OCI profile |
| `oci_set_tenancy <tenancy> [compartment]` | `ocisettenancy` | Set the current tenancy and optional compartment |
| `oci_env_print` | `ocienv` | Display OCI environment variables |
| `oci_env_clear` | `ociclear` | Clear OCI environment variables |
| `oci_auth_status` | `ocistat` | Check the status of the current OCI session |
| `oci_list_profiles` | `ocilistprofiles` | List all available OCI profiles |

### Authenticate to OCI

```bash
# Authenticate with a specific profile
ociauth OC2

# Authenticate with the DEFAULT profile
ociauth
```

<details>

<summary>Output</summary>

```
ENVIRONMENT            TENANCY       REALM  COMPARTMENTS                       REGIONS
My Foo Dev Env         foo_dev       OC1    foo_dev_dp foo_dev_cp dev_sec_ops  us-chicago-1 us-ashburn-1
My Bar Dev Env         bar_dev       OC1    bar_dev_data_plane dev_sec_ops     us-chicago-1
My Foo Production Env  bar_prod      OC1    foo_data_plane dev_sec_ops         us-chicago-1 us-ashburn-1
My Foo QA Gov Env      foo_qa_gov    OC2    foo_gov_qa_dp foo_gov_qa_cp        us-ashburn-1
My Foo Prod Gov Env    foo_prod_gov  OC2    foo_gov_prod_dp foo_gov_prod_cp    us-ashburn-1 us-phoenix-1

Using profile: OC2

Enter a region by index or name(e.g.
1: af-johannesburg-1, 2: ap-chiyoda-1, 3: ap-chuncheon-1, 4: ap-chuncheon-2, 5: ap-dcc-canberra-1,
6: ap-dcc-gazipur-1, 7: ap-hyderabad-1, 8: ap-ibaraki-1, 9: ap-melbourne-1, 10: ap-mumbai-1,
11: ap-osaka-1, 12: ap-seoul-1, 13: ap-seoul-2, 14: ap-singapore-1, 15: ap-singapore-2,
16: ap-suwon-1, 17: ap-sydney-1, 18: ap-tokyo-1, 19: ca-montreal-1, 20: ca-toronto-1,
21: eu-amsterdam-1, 22: eu-crissier-1, 23: eu-dcc-dublin-1, 24: eu-dcc-dublin-2, 25: eu-dcc-milan-1,
26: eu-dcc-milan-2, 27: eu-dcc-rating-1, 28: eu-dcc-rating-2, 29: eu-dcc-zurich-1, 30: eu-frankfurt-1,
31: eu-frankfurt-2, 32: eu-jovanovac-1, 33: eu-madrid-1, 34: eu-madrid-2, 35: eu-marseille-1,
36: eu-milan-1, 37: eu-paris-1, 38: eu-stockholm-1, 39: eu-zurich-1, 40: il-jerusalem-1,
41: me-abudhabi-1, 42: me-abudhabi-2, 43: me-abudhabi-3, 44: me-abudhabi-4, 45: me-alain-1,
46: me-dcc-doha-1, 47: me-dcc-muscat-1, 48: me-dubai-1, 49: me-jeddah-1, 50: me-riyadh-1,
51: mx-monterrey-1, 52: mx-queretaro-1, 53: sa-bogota-1, 54: sa-santiago-1, 55: sa-saopaulo-1,
56: sa-valparaiso-1, 57: sa-vinhedo-1, 58: uk-cardiff-1, 59: uk-gov-cardiff-1, 60: uk-gov-london-1,
61: uk-london-1, 62: us-ashburn-1, 63: us-chicago-1, 64: us-gov-ashburn-1, 65: us-gov-chicago-1,
66: us-gov-phoenix-1, 67: us-langley-1, 68: us-luke-1, 69: us-phoenix-1, 70: us-saltlake-2,
71: us-sanjose-1, 72: us-somerset-1, 73: us-thames-1): 68
    Please switch to newly opened browser window to log in!
    You can also open the following URL in a web browser window to continue:
https://login.us-luke-1.oraclegovcloud.com/v1/oauth2/authorize?action=login&client_id=iaas_console&response_type=token+id_token&nonce=OBFUSCATED&scope=openid&public_key=OBFUSCATED&redirect_uri=http%3A%2F%2Flocalhost%3A8181
    Completed browser authentication process!
Config written to: /Users/dan/.oci/config

    Try out your newly created session credentials with the following example command:

    oci iam region list --config-file /Users/dan/.oci/config --profile OC2 --auth security_token

Setting OCI Profile to OC2
Checking for existing oci_auth_refresher.sh for profile OC2

No existing refresher process found for profile OC2
Running oci_auth_refresher.sh for profile OC2 in the background

[2] 68827

ENVIRONMENT            TENANCY       REALM  COMPARTMENTS                       REGIONS
My Foo Dev Env         foo_dev       OC1    foo_dev_dp foo_dev_cp dev_sec_ops  us-chicago-1 us-ashburn-1
My Bar Dev Env         bar_dev       OC1    bar_dev_data_plane dev_sec_ops     us-chicago-1
My Foo Production Env  bar_prod      OC1    foo_data_plane dev_sec_ops         us-chicago-1 us-ashburn-1
My Foo QA Gov Env      foo_qa_gov    OC2    foo_gov_qa_dp foo_gov_qa_cp        us-ashburn-1
My Foo Prod Gov Env    foo_prod_gov  OC2    foo_gov_prod_dp foo_gov_prod_cp    us-ashburn-1 us-phoenix-1

To set Tenancy, Compartment, or Region export the OCI_TENANCY_NAME, OCI_COMPARTMENT, or OCI_CLI_REGION environment variables.

Or if using oshell, run:
oci_set_tenancy TENANCY_NAME
oci_set_tenancy TENANCY_NAME COMPARTMENT_NAME
```

</details>

### Set Tenancy and Compartment

Set the current tenancy and optionally a compartment:

```bash
# Set just the tenancy
ocisettenancy foo_prod_gov

# Set both tenancy and compartment
ocisettenancy foo_prod_gov foo_gov_prod_dp
```

<details>
<summary>Output</summary>

```
Setting tenancy to foo_prod_gov via OCI_TENANCY_NAME environment variable
Setting compartment to foo_gov_prod_dp via OCI_COMPARTMENT environment variable

Tenancy name: foo_prod_gov
Tenancy ID: ocid1.tenancy.oc2..abcdefghijklmnopqrstuvwxyz135792468
Compartment: foo_gov_prod_dp
```
</details>

### Switch Between Profiles

```bash
# Set the active profile
ociset OC2
```

### Check Session Status

```bash
# Check if your current session is valid
ocistat
```

### List Available Profiles

```bash
# List all profiles and their status
ocilistprofiles
```

### Manage Environment Variables

```bash
# Display all OCI-related environment variables
ocienv

# Clear OCI environment variables (except profile)
ociclear
```

### Log Out

```bash
# Terminate the current session
ociexit
```

## Using with oshiv

After setting up your tenancy and compartment with oshell, you can use oshiv to manage OCI resources:

```bash
# List instances matching "home" in their name
oshiv inst -f home
```

<details>
<summary>Output</summary>

```
2 matches
Tenancy(Compartment): foo_prod_gov(foo_gov_prod_dp)
Name: inst-foo-app1
ID: ocid1.instance.oc2.us-luke-1.abcdefghiklmnopqrsuvwxyz54321
Private IP: 192.168.123.456 FD: FD-1 AD: bKwM:us-luke-1-ad-1
Shape: VM.Standard.E5.Flex Mem: 8 vCPUs: 8
State: RUNNING
Created: 2025-04-08 17:07:26.298 +0000 UTC
Subnet ID: ocid1.subnet.oc2.us-luke-1.abcdefghiklmnopqrsuvwxyz0987654321

Name: inst-foo-app2
ID: ocid1.instance.oc2.us-luke-1.abcdefghiklmnopqrsuvwxyz12345
Private IP: 192.168.123.457 FD: FD-2 AD: bKwM:us-luke-1-ad-1
Shape: VM.Standard.E5.Flex Mem: 8 vCPUs: 8
State: RUNNING
Created: 2025-04-08 17:07:26.232 +0000 UTC
Subnet ID: ocid1.subnet.oc2.us-luke-1.abcdefghiklmnopqrsuvwxyz0987654321
```
</details>

## Shell Integration

oshell can integrate with your ZSH prompt to show your current OCI context. See the included `.zshrc_EXAMPLE.sh` file for an example configuration.

When properly configured, your prompt will show:
- Current OCI profile
- Tenancy (if set)
- Compartment (if set)

## How It Works

oshell includes an authentication refresher that runs in the background to keep your OCI sessions active. The refresher automatically refreshes your session before it expires, so you don't have to re-authenticate manually.
