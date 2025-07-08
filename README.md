# oshell
[![CI](https://github.com/cnopslabs/oshell/actions/workflows/ci.yml/badge.svg)](https://github.com/cnopslabs/oshell/actions/workflows/ci.yml)

Helper shell utilities for OCI CLI and [oshiv](https://github.com/cnopslabs/oshiv). This tool simplifies working with multiple OCI tenancies, compartments, and profiles.

![oshell setup demonstration](assets/oshell-setup.gif)

---

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
   - [OCI CLI](#oci-cli)
   - [oshiv](#oshiv)
- [Installation](#installation)
   - [1. Clone this repository](#1-clone-this-repository)
   - [2. Configure Tenancy Map (Recommended)](#2-configure-tenancy-map-recommended)
   - [3. Add oshell to your ZSH configuration](#3-add-oshell-to-your-zsh-configuration)
- [Usage](#usage)
   - [Commands List](#commands-list)
   - [Authenticate to OCI](#authenticate-to-oci)
   - [Set Tenancy and Compartment](#set-tenancy-and-compartment)
   - [Switch Between Profiles](#switch-between-profiles)
   - [Check Session Status](#check-session-status)
   - [List Available Profiles](#list-available-profiles)
   - [Manage Environment Variables](#manage-environment-variables)
   - [Log Out](#log-out)
- [Using with oshiv](#using-with-oshiv)
- [Shell Integration](#shell-integration)
- [Authentication Lifecycle Management](#authentication-lifecycle-management)
   - [Authentication Process](#authentication-process)
   - [Session Maintenance](#session-maintenance)
   - [Terminating Sessions](#terminating-sessions)
   - [Logs and Monitoring](#logs-and-monitoring)
- [Troubleshooting and Setup Fix](#troubleshooting-and-setup-fix)

---

## Features

- Authenticate to OCI with different profiles
- Automatic session refreshing to maintain authentication
- Easy switching between tenancies and compartments
- Manage OCI environment variables
- Shell integration showing current OCI context

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
source "$OSHELL_HOME/oshell.sh"
```

<details>
<summary>Example .zshrc configuration</summary>

```bash
# oshell configuration
# Replace /path/to/oshell with the actual path where you installed oshell
export OSHELL_HOME=/path/to/oshell
source "$OSHELL_HOME/oshell.sh"
```

For shell prompt integration, see the included `.zshrc_EXAMPLE.sh` file.
</details>

## Usage

oshell provides several commands to manage your OCI authentication and environment:

| Command | Alias | Description |
|---------|-------|-------------|
| `oci_authenticate [profile]` | `ociauth` | Authenticate to OCI with the specified profile |
| `oci_auth_logout [profile]` | `ociexit [profile]` | Log out of the current OCI session or terminate a specific profile's background refresher |
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
# Terminate the current active profile
ociexit

# Terminate a specific profile (even if it's not the active one)
ociexit PROFILE_NAME
```

For more details on session termination and background refresher management, see the [Terminating Sessions](#terminating-sessions) section.

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

> **Warning:** This is a beta feature and may cause issues with your existing prompt and ZSH initialization.

---

## Authentication Lifecycle Management

oshell provides a complete lifecycle management for OCI authentication:

### Authentication Process

1. **Authentication Initiation**: When you run `ociauth [profile]`, oshell authenticates with OCI using the specified profile (or DEFAULT if none is provided).

2. **Background Refresher**: After successful authentication, oshell automatically starts a background process (`oci_auth_refresher.sh`) that keeps your session alive by refreshing it before it expires.

3. **Multiple Profiles**: You can authenticate with multiple profiles simultaneously. Each profile gets its own background refresher process.

### Session Maintenance

- The background refresher continuously monitors your session's expiration time.
- It automatically refreshes the session shortly before it expires (default: 60 seconds).
- This happens silently in the background, allowing you to work without interruption.
- You can check the status of your session with `ocistat`.

### Terminating Sessions

The `ociexit` command has been enhanced to provide better control over session termination:

```bash
# Terminate the current active profile
ociexit

# Terminate a specific profile (even if it's not the active one)
ociexit PROFILE_NAME
```

When you run `ociexit`:

1. It terminates the background refresher process for the specified profile.
2. If terminating the current active profile, it also:
   - Attempts to terminate the OCI session using the `oci session terminate` command
   - Clears the OCI_CLI_PROFILE environment variable

Note: The command has been improved to handle various edge cases gracefully:
- If no background refresher is found for the profile, it will display a clear message indicating no active refresher was found
- If a background refresher is terminated but session termination fails, it will still report success for the primary operation
- When no active session exists, the command provides helpful guidance instead of misleading error messages
- Session termination errors are logged but only displayed to the user when relevant to the operation

This allows you to:
- Log out completely from your current profile
- Terminate background refreshers for other profiles without switching to them
- Manage multiple authentication sessions efficiently

### Logs and Monitoring

- Each profile's refresher logs are stored at: `$HOME/.oci/sessions/PROFILE_NAME/oci-auth-refresher_PROFILE_NAME.log`
- You can check if a refresher is running with: `pgrep -af oci_auth_refresher.sh`
- The session status is stored at: `$HOME/.oci/sessions/PROFILE_NAME/session_status`

#### Log File Contents

The log file contains detailed information about the authentication refresher's activities:

- Session validation attempts and results
- Refresh operations and their outcomes
- Session expiration timestamps and remaining time calculations
- Error messages and troubleshooting information

All profiles (DEFAULT and custom profiles) now have consistent logging behavior, making it easier to troubleshoot issues across different profiles. Each profile's log follows the same format and includes the same level of detail.

When troubleshooting issues with authentication or session management, checking these logs is often the first step to understanding what's happening behind the scenes.

---

## Troubleshooting and Setup Fix

This section helps resolve common issues related to `oci_auth_refresher.sh` not starting or running correctly.

### Common Problems

1. **`oci_auth_refresher.sh` Process Not Found**  
   After running `pgrep -af oci_auth_refresher.sh`, if it's empty, the refresher process is not running.

2. **Exit Code 127**  
   This indicates the `oci_auth_refresher.sh` script could not be found or executed. The issue could be:
    - Incorrect setup of the `$OSHELL_HOME` environment variable.
    - Missing or improperly configured `oci_auth_refresher.sh`.
    - The script doesn't have execute permissions.

---

### Steps to Fix

#### **1. Verify `$OSHELL_HOME`**
The `OSHELL_HOME` environment variable must point to the directory containing `oci_auth_refresher.sh`.

1. Check the value of `$OSHELL_HOME`:
   ```bash
   echo "$OSHELL_HOME"
   ```

2. If it's not set or is incorrect, set it to the directory where `oshell` is installed. For example:
   ```bash
   export OSHELL_HOME=/path/to/oshell
   ```

3. Add this line to your `.zshrc` so the change persists:
   ```bash
   export OSHELL_HOME=/path/to/oshell
   ```

---

#### **2. Check Refresher Script Location**
Verify that `oci_auth_refresher.sh` exists in the `$OSHELL_HOME` directory:

```bash
ls -l "${OSHELL_HOME}/oci_auth_refresher.sh"
```

- If the file is missing, download or pull the latest version of this repository.
- If the file is present but not executable, make sure it has the correct permissions:
  ```bash
  chmod +x "${OSHELL_HOME}/oci_auth_refresher.sh"
  ```

---

#### **3. Debug the `oci_auth_refresher.sh` Manually**
Run the refresher script directly to see if it works:

```bash
# With a specific profile name
nohup "${OSHELL_HOME}/oci_auth_refresher.sh" <profile-name> &

# Or without a profile name (will use DEFAULT)
nohup "${OSHELL_HOME}/oci_auth_refresher.sh" &
```

- Replace `<profile-name>` with your OCI profile name if you want to use a specific profile.
- If no profile name is provided, the script will use "DEFAULT".
- If this fails with an error, check your OCI setup and logs.

---

#### **4. Check for Running Processes**
After running the refresher script or authenticating using `ociauth`, verify the process is running:

```bash
pgrep -af oci_auth_refresher.sh
```

If no results are shown, try the script troubleshooting steps again.

---

#### **5. Inspect Logs**
If the refresher fails to start or exits prematurely, review the log file for details:

```bash
cat ${HOME}/.oci/sessions/<profile-name>/oci-auth-refresher_<profile-name>.log
```

Replace `<profile-name>` with the appropriate profile (e.g., `DEFAULT`).

---

#### **6. OCI CLI and Dependencies**
Ensure OCI CLI is properly installed and available in your `PATH`. Check your OCI CLI version:

```bash
oci --version
```

If the OCI CLI is not installed, follow the [installation guide](https://docs.oracle.com/en-us/iaas/Content/API/SDKDocs/cliinstall.htm).

---

### Example Workflow to Fix Refresher Issues

1. Verify the `$OSHELL_HOME` environment variable:
   ```bash
   echo "$OSHELL_HOME"
   export OSHELL_HOME=/path/to/oshell
   ```

2. Ensure `oci_auth_refresher.sh` exists and is executable:
   ```bash
   ls -l "${OSHELL_HOME}/oci_auth_refresher.sh"
   chmod +x "${OSHELL_HOME}/oci_auth_refresher.sh"
   ```

3. Authenticate using `ociauth`:
   ```bash
   ociauth DEFAULT
   ```

4. Check the refresher process:
   ```bash
   pgrep -af oci_auth_refresher.sh
   ```

5. Review logs for more details:
   ```bash
   cat ${HOME}/.oci/sessions/DEFAULT/oci-auth-refresher_DEFAULT.log
   ```

By following these steps, most common issues with the `oci_auth_refresher.sh` process should be resolved.
