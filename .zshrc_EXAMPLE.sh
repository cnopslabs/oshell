# Prompt
plugins=(emoji)

function set_oci_prompt() {
  if [[ -z "${OCI_CLI_PROFILE}" ]]
  then
    export oci_prompt=""
  else
    if [[ -f $HOME/.oci/sessions/$OCI_CLI_PROFILE/session_status ]]
    then
      # OCI profile and session status file exists, so get session status
      oci_session_status=`cat ${HOME}/.oci/sessions/$OCI_CLI_PROFILE/session_status`

      if [[ "${oci_session_status}" == "valid" ]]
      then # Session IS valid
        if [[ -z "${OCI_COMPARTMENT}" ]]
        then # Compartment NOT set
          if [[ -z "${OCI_TENANCY_NAME}" ]]
          then # Tenancy AND Compartment NOT set
            export oci_prompt="${OCI_CLI_PROFILE}$emoji[recycling_symbol_unqualified]"
          else # Only tenancy IS set
            export oci_prompt="${OCI_CLI_PROFILE}$emoji[recycling_symbol_unqualified][${OCI_TENANCY_NAME}]"
          fi
        else
          # Tenancy AND Compartment IS set
          export oci_prompt="${OCI_CLI_PROFILE}$emoji[recycling_symbol_unqualified][${OCI_TENANCY_NAME}]${OCI_COMPARTMENT}"
        fi

      elif [[ "${oci_session_status}" == "expired" ]]
      then # Session IS NOT valid
        export oci_prompt=""
      else
        echo "Unable to determine OCI status"
      fi
    else
      export oci_prompt=""
    fi
  fi
}

precmd() { 
  vcs_info
  set_oci_prompt
}

# oshell initialization
source $HOME/github/cnopslabs/oshell/oshell/oshell.sh
