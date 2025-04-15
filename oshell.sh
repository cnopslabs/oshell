#!/bin/zsh

CYAN='\033[0;96m'
YELLOW_ITALICS='\033[1;33m'
UNSET=$(tput sgr0)

alias ocienv='oci_env_print'
function oci_env_print () {
  env | egrep "OCI_|CID"
}

alias ocienvclear='oci_env_clear'
function oci_env_clear() {
  unset CID OCI_CLI_TENANCY
}

alias ocit='list_oci_tenants'
function list_oci_tenants() {
  oshiv info

  echo ""
  echo "To set tenancy, run: ${YELLOW}ocisettenant <TENANT>${NORMAL}"
  echo "To set tenancy and compartment, run: ${YELLOW}ocisettenant <TENANT> <COMPARTMENT>${NORMAL}"
}

alias ociauth='oci_authenticate'
function oci_authenticate() {
  # Usage: ociauth <OCI_PROFILE>
  # Examples: 
  #   ociauth OC2
  #   ociauth OC1-Chicago

  oshiv info
  echo ""

  # Use DEFAULT profile if profile not explicitly passed
  if [[ -z "${1}" ]]
  then
    echo "Using profile: ${CYAN}DEFAULT${UNSET}\n"
    oci session authenticate --profile-name DEFAULT

    if [[ $? -ne 0 ]]
    then
      echo "OCI authentication failed"
      exit 1
    else
      unset OCI_COMPARTMENT_NAME CID OCI_COMPARTMENT_ID OCI_CLI_TENANCY OCI_TENANCY_NAME
      echo "Setting OCI Profile to DEFAULT"
      export OCI_CLI_PROFILE=DEFAULT
    fi
  else
    echo "Using profile: ${CYAN}${1}${UNSET}\n"
    oci session authenticate --profile-name $1

    if [[ $? -ne 0 ]]
    then
      echo "OCI authentication failed"
      exit 1
    else
      unset OCI_COMPARTMENT_NAME CID OCI_COMPARTMENT_ID OCI_CLI_TENANCY OCI_TENANCY_NAME
      echo "Setting OCI Profile to ${1}"
      export OCI_CLI_PROFILE=$1
    fi
  fi

  # Check for existing OCI auth refresher processes for profile
  echo "Checking for existing oci_auth_refresher.sh for profile ${CYAN}$OCI_CLI_PROFILE${UNSET}\n"

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
      echo "Killing process due to new OCI auth for profile ${OCI_CLI_PROFILE}" >> $REFRESHER_LOG_FILE
      kill -9 $r_pid
      echo ""
      nohup "${OSHELL_HOME}/oci_auth_refresher.sh" $OCI_CLI_PROFILE > $REFRESHER_LOG_FILE 2>&1 &
      
      sleep 1
      list_oci_tenants
      exit 0
    fi
  done

  # No existing refresh processes were found for profile, start a new one
  echo "No existing refresher process found for profile ${CYAN}$OCI_CLI_PROFILE${UNSET}"
  echo "Running oci_auth_refresher.sh for profile ${CYAN}$OCI_CLI_PROFILE${UNSET} in the background\n"
  nohup "${OSHELL_HOME}/oci_auth_refresher.sh" $OCI_CLI_PROFILE > $REFRESHER_LOG_FILE 2>&1 &
  sleep 1
  list_oci_tenants
}

alias ocistat='oci_auth_status'
function oci_auth_status() {
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
    echo "No existing OCI auth refresher process found for profile ${CYAN}$OCI_CLI_PROFILE${UNSET}"
  else
    echo "OCI auth refresher process for profile ${CYAN}$OCI_CLI_PROFILE${UNSET} is ${proc_for_profile}"
  fi
}

alias ocisettenant='oci_set_tenant'
function oci_set_tenant() {
  oci_tenancy_id=`oshiv info -l $1`
  export OCI_TENANCY_NAME=$1

  oci_env_clear
  echo "Setting tenancy to ${oci_tenancy_id} via OCI_CLI_TENANCY environment variable"
  export OCI_CLI_TENANCY=$oci_tenancy_id

  if [[ ! -z "${2}" ]]
  then
    echo "Setting compartment to ${2} via oshiv"
    oshiv compart -s $2
  fi

  oshiv config
}

alias ocilist='list_oci_cli_profiles'
function list_oci_cli_profile() {
  echo "Profiles:"
  for i in $( ls -1 $HOME/.oci/sessions/*/session_status )
  do
    session_status=`cat $i`
    profile_name=`echo $i | awk -F"/" '{print $6}'`

    if [[ "${session_status}" == "valid" ]]
    then
      echo $profile_name
    fi
  done
}

alias ociset='set_oci_cli_profile'
function set_oci_cli_profile() {
  echo "Setting OCI_CLI_PROFILE to ${1}"
  export OCI_CLI_PROFILE=$1

  list_oci_tenants
}
