# Prompt configuration for OCI integration
plugins=(emoji)

# Function to set the OCI prompt based on current profile, tenancy, and compartment
function set_oci_prompt() {
  # If no OCI profile is set, don't show anything in the prompt
  if [[ -z "${OCI_CLI_PROFILE}" ]]
  then
    export oci_prompt=""
    return
  fi

  local session_status_file="$HOME/.oci/sessions/$OCI_CLI_PROFILE/session_status"

  # Check if the session status file exists
  if [[ -f $session_status_file ]]
  then
    # OCI profile and session status file exists, so get session status
    local oci_session_status=$(cat ${session_status_file})

    if [[ "${oci_session_status}" == "valid" ]]
    then 
      # Session IS valid - build the prompt based on what's set
      if [[ -z "${OCI_COMPARTMENT}" ]]
      then 
        # Compartment NOT set
        if [[ -z "${OCI_TENANCY_NAME}" ]]
        then 
          # Neither tenancy nor compartment set
          export oci_prompt="${OCI_CLI_PROFILE}${emoji[recycling_symbol_unqualified]}"
        else 
          # Only tenancy IS set
          export oci_prompt="${OCI_CLI_PROFILE}${emoji[recycling_symbol_unqualified]}[${OCI_TENANCY_NAME}]"
        fi
      else
        # Both tenancy AND compartment are set
        export oci_prompt="${OCI_CLI_PROFILE}${emoji[recycling_symbol_unqualified]}[${OCI_TENANCY_NAME}]${OCI_COMPARTMENT}"
      fi
    elif [[ "${oci_session_status}" == "expired" ]]
    then 
      # Session is expired - don't show in prompt
      export oci_prompt=""
    else
      # Unknown status
      echo "Unable to determine OCI status"
      export oci_prompt=""
    fi
  else
    # No session status file - don't show in prompt
    export oci_prompt=""
  fi
}

# Run set_oci_prompt before each command
precmd() { 
  set_oci_prompt
}

# oshell initialization - update this path to match your installation
# Replace /path/to/oshell with the actual path where you installed oshell
export OSHELL_HOME=/path/to/oshell
source $OSHELL_HOME/oshell.sh

# Available oshell commands:
# ociauth <profile>       - Authenticate to OCI with the specified profile
# ociexit                 - Log out of the current OCI session
# ociset <profile>        - Set the current OCI profile
# ocisettenancy <t> [c]   - Set the current tenancy and optional compartment
# ocienv                  - Display OCI environment variables
# ociclear                - Clear OCI environment variables
# ocistat                 - Check the status of the current OCI session
# ocilistprofiles         - List all available OCI profiles
