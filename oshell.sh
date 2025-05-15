#!/bin/zsh

# Version: 0.1.0

CYAN='\033[0;96m'
YELLOW='\033[;33m'
UNSET_FMT=$(tput sgr0)
RED='\033[0;31m'

alias ociauth='oci_authenticate'
function oci_authenticate() {
  # Usage: ociauth <OCI_PROFILE>
  # Examples: 
  #   ociauth OC2
  #   ociauth OC1-Chicago

  # Display tenancies / regions to help with OCI session auth selection
  oshiv info
  echo ""

  if [[ -z "${1}" ]]
  # Using DEFAULT profile as profile not explicitly passed
  then
    echo "Using profile: ${CYAN}DEFAULT${UNSET_FMT}\n"
    oci session authenticate --profile-name DEFAULT

    if [[ $? -ne 0 ]]
    then
      echo "OCI authentication failed"
      return
    else
      # Reset environment variables 
      unset OCI_CLI_TENANCY OCI_TENANCY_NAME OCI_COMPARTMENT CID OCI_CLI_REGION
      echo "Setting OCI Profile to DEFAULT"
      export OCI_CLI_PROFILE=DEFAULT
    fi
  else
    echo "Using profile: ${CYAN}${1}${UNSET_FMT}\n"
    oci session authenticate --profile-name $1

    if [[ $? -ne 0 ]]
    then
      echo "OCI authentication failed"
      return
    else
      unset OCI_CLI_TENANCY OCI_TENANCY_NAME OCI_COMPARTMENT CID OCI_CLI_REGION
      echo "Setting OCI Profile to ${1}"
      export OCI_CLI_PROFILE=$1
    fi
  fi

  # Check for existing OCI auth refresher processes for profile
  echo "Checking for existing oci_auth_refresher.sh for profile ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT}\n"

  REFRESHER_LOG_FILE="${HOME}/Library/Logs/oci-auth-refresher_${OCI_CLI_PROFILE}.log"

  # Find all refresher processes (for all OCI profiles)
  for r_pid in $(pgrep -f oci_auth_refresher.sh)
  do
    # Get profile of OCI profile of PID
    r_oci_profile=$(ps -p $r_pid -o command | grep -v COMMAND | awk '{print $3}')
    if [[ $LOGLEVEL == "DEBUG" ]]
    then
      echo "Existing refresher process:"
      echo "  PID: ${r_pid}"
      echo "  PROFILE: ${r_oci_profile}\n"
    fi

    # Check if PID's profile is current shell's profile
    if [[ $OCI_CLI_PROFILE == $r_oci_profile ]]
    then
      # 
      echo "Existing refresher process found for the ${OCI_CLI_PROFILE} profile, killing process and restarting..."
      echo date >> $REFRESHER_LOG_FILE
      echo "Killing process due to new OCI auth for profile ${OCI_CLI_PROFILE}" >> $REFRESHER_LOG_FILE
      kill -9 $r_pid
      echo "expired" > ${HOME}/.oci/sessions/$OCI_CLI_PROFILE/session_status
      echo ""
      # Explicitly redirect all standard streams to protect the Python interpreter (oci cli) from crashing when the terminal closes
      nohup "${OSHELL_HOME}/oci_auth_refresher.sh" $OCI_CLI_PROFILE > /dev/null 2>&1 < /dev/null &
      
      sleep 1
      oshiv info
      return
    fi
  done

  # No existing refresh processes were found for profile, start a new one
  echo "No existing refresher process found for profile ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT}"
  echo "Running oci_auth_refresher.sh for profile ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT} in the background\n"
  # Explicitly redirect all standard streams to protect the Python interpreter (oci cli) from crashing when the terminal closes
  nohup "${OSHELL_HOME}/oci_auth_refresher.sh" $OCI_CLI_PROFILE > /dev/null 2>&1 < /dev/null &
  sleep 1
  oshiv info
}

alias ocisettenancy='oci_set_tenancy'
function oci_set_tenancy() {
  # Usage: oci_set_tenancy TENANCY_NAME COMPARTMENT_NAME
  tenancy_name=$1
  compartment_name=$2

  if [[ -n "${tenancy_name}" ]]
  then
    echo "Setting tenancy to ${YELLOW}${tenancy_name}${UNSET_FMT} via ${YELLOW}OCI_TENANCY_NAME${UNSET_FMT} environment variable"
    export OCI_TENANCY_NAME=$tenancy_name
  else
    echo "Error: Tenancy name required"
    return
  fi
  
  if [[ -n "${compartment_name}" ]]
  then
    echo "Setting compartment to ${YELLOW}${compartment_name}${UNSET_FMT} via ${YELLOW}OCI_COMPARTMENT${UNSET_FMT} environment variable"
    export OCI_COMPARTMENT=$compartment_name
  fi

  echo ""
  oshiv config
}

alias ocienv='oci_env_print'
function oci_env_print () {
  env | egrep "OCI_|CID"
}

alias ociclear='oci_env_clear'
function oci_env_clear() {
  unset OCI_CLI_TENANCY OCI_TENANCY_NAME OCI_COMPARTMENT CID OCI_CLI_REGION
}

alias ocistat='oci_auth_status'
function oci_auth_status() {
  # Check status of current session per $OCI_CLI_PROFILE
  oci session validate --local

  # Check status of OCI auth refresher
  # Find all refresher processes (for all OCI profiles)
  for r_pid in $(pgrep -f oci_auth_refresher.sh)
  do
    # Get profile of OCI profile of PID
    r_oci_profile=$(ps -p $r_pid -o command | grep -v COMMAND | awk '{print $3}')
    if [[ $LOGLEVEL == "DEBUG" ]]
    then
      echo "Existing refresher process:"
      echo "  PID: ${r_pid}"
      echo "  PROFILE: ${r_oci_profile}\n"
    fi

    # Check if PID's profile is current shell's profile
    if [[ $OCI_CLI_PROFILE == $r_oci_profile ]]
    then
      proc_for_profile=$r_pid
      break
    fi
  done

  if [[ -z "${proc_for_profile}" ]]
  then
    echo "No existing OCI auth refresher process found for profile: ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT}"
  else
    echo "OCI auth refresher process for profile ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT} is ${proc_for_profile}"
  fi
}

alias ociset='set_oci_cli_profile'
function set_oci_cli_profile() {
  # TODO: Check of valid profile: Does it exist? Is the session expired?
  echo "Setting OCI_CLI_PROFILE to ${1}"
  export OCI_CLI_PROFILE=$1

  echo ""
  oshiv info
}

alias ocilistprofiles='list_oci_cli_profiles'
function list_oci_cli_profiles() {
  echo "${CYAN}Profiles:${UNSET_FMT}"
  for i in $( ls -1 $HOME/.oci/sessions/*/session_status )
  do
    session_status=`cat $i`
    profile_name=`echo $i | awk -F"/" '{print $6}'`

    if [[ "${session_status}" == "expired" ]]
    then
      echo "${profile_name} (${RED}${session_status}${UNSET_FMT})"
    else
      echo "${profile_name}"
    fi
  done
}
