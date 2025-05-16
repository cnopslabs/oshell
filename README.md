# oshell

Helper shell utilities for OCI CLI and [oshiv](https://github.com/cnopslabs/oshiv)

## Prerequisites

### OCI CLI

[https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm)

### oshiv

[https://github.com/cnopslabs/oshiv#install-oshiv](https://github.com/cnopslabs/oshiv#install-oshiv)

## Install

### Clone this repo

Example:

```
git clone https://github.com/cnopslabs/oshell
```

### Configure Tenancy map file (Recommended)

Create an OCI tenancy mappings file. The tenancy map is informational only. It allows `oshiv` to quickly print the tenant and compartment details you use the most often.

You can use the [tenancy-map.yaml](tenancy-map.yaml) from this repo as a starter template.

```
cp tenancy-map.yaml $HOME/.oci
```

Update `tenancy-map.yaml` with the tenancies and compartments relative to your role.

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

### Add oshell to your ZSH shell initialization file `.zshrc`

Update your ZSH init file (`$HOME/.zshrc`) with:

```
export OSHELL_HOME=<PATH TO YOU LOCAL OSHELL GITHUB REPOSITORY>
source $OSHELL_HOME/oshell/oshell.sh
```

<details>

<summary>Example</summary>

```
source $HOME/github/cnopslab/oshell/oshell.sh
```

</details>

## Usage

### Auth to OCI

```
ociauth OC2
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

To set tenancy, run: ocisettenant <TENANT>
To set tenancy and compartment, run: ocisettenant <TENANT> <COMPARTMENT>
```

</details>

### Set up OCI environment variables for tenant and compartment

```
ocisettenant foo_prod_gov foo_gov_prod_dp
```

<details>

<summary>Output</summary>

```
Setting tenancy to ocid1.tenancy.oc2..abcdefghijklmnopqrstuvwxyz1357924680 via OCI_CLI_TENANCY environment variable
Setting compartment to foo_gov_prod_dp via oshiv
Tenancy name: foo_prod_gov
Tenancy ID: ocid1.tenancy.oc2..abcdefghijklmnopqrstuvwxyz135792468
Compartment: foo_gov_prod_dp
```

</details>

## Verify

```
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
