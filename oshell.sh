#!/bin/zsh

# Version: 0.1.0

# Color definitions for terminal output
CYAN='\033[0;96m'
YELLOW='\033[;33m'
UNSET_FMT=$(tput sgr0)
RED='\033[0;31m'

# Log file for the OCI authentication refresher
REFRESHER_LOG_FILE="${HOME}/Library/Logs/oci-auth-refresher_${OCI_CLI_PROFILE}.log"

# Helper function to find OCI auth refresher process for a specific profile
function find_oci_auth_refresher_process() {
  local profile=$1
  local found_pid=""

  # Find all refresher processes (for all OCI profiles)
  for r_pid in $(pgrep -f oci_auth_refresher.sh)
  do
    # Get profile of OCI profile of PID
    r_oci_profile=$(ps -p "$r_pid" -o command | grep -v COMMAND | awk '{print $3}')
    if [[ $LOGLEVEL == "DEBUG" ]]
    then
      echo "Existing refresher process:"
      echo "  PID: ${r_pid}"
      echo "  PROFILE: ${r_oci_profile}\n"
    fi

    # Check if PID's profile is the requested profile
    if [[ "$profile" == "$r_oci_profile" ]]
    then
      found_pid=$r_pid
      break
    fi
  done

  echo $found_pid
}

# Helper function to start OCI auth refresher process
function start_oci_auth_refresher() {
  local profile=$1
  local restart=$2

  if [[ $restart == "true" ]]
  then
    echo "Existing refresher process found for the ${profile} profile, killing process and restarting..."
    echo date >> $REFRESHER_LOG_FILE
    echo "Killing process due to new OCI auth for profile ${profile}" >> $REFRESHER_LOG_FILE
    kill -9 $(find_oci_auth_refresher_process $profile)
    echo "expired" > ${HOME}/.oci/sessions/$profile/session_status
    echo ""
  else
    echo "No existing refresher process found for profile ${CYAN}$profile${UNSET_FMT}"
    echo "Running oci_auth_refresher.sh for profile ${CYAN}$profile${UNSET_FMT} in the background\n"
  fi

  # Explicitly redirect all standard streams to protect the Python interpreter (oci cli) from crashing when the terminal closes
  nohup "${OSHELL_HOME}/oci_auth_refresher.sh" $profile > /dev/null 2>&1 < /dev/null &
  sleep 1
}

alias ociauth='oci_authenticate'
function oci_authenticate() {
  # Usage: ociauth <OCI_PROFILE>
  # Examples: 
  #   ociauth OC2
  #   ociauth OC1-Chicago

  # Display tenancies / regions to help with OCI session auth selection
  oshiv info
  echo ""

  local profile_name=""

  if [[ -z "${1}" ]]
  then
    # Using DEFAULT profile as profile not explicitly passed
    profile_name="DEFAULT"
    echo "Using profile: ${CYAN}${profile_name}${UNSET_FMT}\n"
    oci session authenticate --profile-name $profile_name
  else
    profile_name=$1
    echo "Using profile: ${CYAN}${profile_name}${UNSET_FMT}\n"
    oci session authenticate --profile-name $profile_name
  fi

  if [[ $? -ne 0 ]]
  then
    echo "OCI authentication failed"
    return 1
  else
    # Reset environment variables 
    unset OCI_CLI_TENANCY OCI_TENANCY_NAME OCI_COMPARTMENT CID OCI_CLI_REGION
    echo "Setting OCI Profile to ${profile_name}"
    export OCI_CLI_PROFILE=$profile_name
  fi

  # Check for existing OCI auth refresher processes for profile
  echo "Checking for existing oci_auth_refresher.sh for profile ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT}\n"

  local refresher_pid=$(find_oci_auth_refresher_process $OCI_CLI_PROFILE)

  if [[ -n "$refresher_pid" ]]
  then
    start_oci_auth_refresher $OCI_CLI_PROFILE "true"
  else
    start_oci_auth_refresher $OCI_CLI_PROFILE "false"
  fi

  oshiv info
}

alias ociexit='oci_auth_logout'
function oci_auth_logout() {
  # Logs you out of current session (i.e., the session to which your OCI_CLI_PROFILE var is set)
  if [[ -z "${OCI_CLI_PROFILE}" ]]
  then
    echo "No active OCI profile found. Nothing to log out from."
    return 0
  fi

  local refresher_pid=$(find_oci_auth_refresher_process $OCI_CLI_PROFILE)

  if [[ -n "$refresher_pid" ]]
  then
    echo date >> $REFRESHER_LOG_FILE
    echo "Existing refresher process found for the ${OCI_CLI_PROFILE} profile, killing process."
    kill -9 $refresher_pid
    echo "expired" > ${HOME}/.oci/sessions/$OCI_CLI_PROFILE/session_status
  fi

  # Terminate the OCI session
  oci session terminate

  if [[ $? -eq 0 ]]
  then
    echo "Successfully logged out from OCI profile: ${CYAN}${OCI_CLI_PROFILE}${UNSET_FMT}"
    return 0
  else
    echo "Failed to terminate OCI session for profile: ${CYAN}${OCI_CLI_PROFILE}${UNSET_FMT}"
    return 1
  fi
}

alias ocisettenancy='oci_set_tenancy'
function oci_set_tenancy() {
  # Usage: oci_set_tenancy TENANCY_NAME [COMPARTMENT_NAME]
  # Sets the OCI_TENANCY_NAME and optionally OCI_COMPARTMENT environment variables
  # Examples:
  #   oci_set_tenancy foo_prod_gov
  #   oci_set_tenancy foo_prod_gov foo_gov_prod_dp

  local tenancy_name=$1
  local compartment_name=$2

  if [[ -z "${tenancy_name}" ]]
  then
    echo "Error: Tenancy name required"
    echo "Usage: ocisettenancy <tenancy_name> [compartment_name]"
    return 1
  fi

  echo "Setting tenancy to ${YELLOW}${tenancy_name}${UNSET_FMT} via ${YELLOW}OCI_TENANCY_NAME${UNSET_FMT} environment variable"
  export OCI_TENANCY_NAME=$tenancy_name

  if [[ -n "${compartment_name}" ]]
  then
    echo "Setting compartment to ${YELLOW}${compartment_name}${UNSET_FMT} via ${YELLOW}OCI_COMPARTMENT${UNSET_FMT} environment variable"
    export OCI_COMPARTMENT=$compartment_name
  fi

  echo ""
  oshiv config
  return 0
}

alias ocienv='oci_env_print'
function oci_env_print() {
  # Displays all OCI-related environment variables
  # This includes variables starting with OCI_ and the CID variable

  echo "OCI Environment Variables:"
  local oci_vars=$(env | egrep "OCI_|CID")

  if [[ -z "$oci_vars" ]]
  then
    echo "  No OCI environment variables set"
    return 0
  else
    echo "$oci_vars"
    return 0
  fi
}

alias ociclear='oci_env_clear'
function oci_env_clear() {
  # Clears all OCI-related environment variables except OCI_CLI_PROFILE
  # This allows you to keep your authenticated profile while changing tenancy/compartment/region

  local profile=$OCI_CLI_PROFILE

  echo "Clearing OCI environment variables..."
  unset OCI_CLI_TENANCY OCI_TENANCY_NAME OCI_COMPARTMENT CID OCI_CLI_REGION

  # Keep the profile if it was set
  if [[ -n "$profile" ]]
  then
    export OCI_CLI_PROFILE=$profile
    echo "Kept OCI_CLI_PROFILE=$profile"
  fi

  echo "Done"
  return 0
}

alias ocistat='oci_auth_status'
function oci_auth_status() {
  # Check status of current session per $OCI_CLI_PROFILE
  if [[ -z "${OCI_CLI_PROFILE}" ]]
  then
    echo "No active OCI profile found. Set a profile with ociset <profile_name>."
    return 0
  fi

  echo "Checking session status for profile: ${CYAN}${OCI_CLI_PROFILE}${UNSET_FMT}"
  oci session validate --local

  local exit_code=$?
  if [[ $exit_code -ne 0 ]]
  then
    echo "Session for profile ${CYAN}${OCI_CLI_PROFILE}${UNSET_FMT} is ${RED}invalid${UNSET_FMT}"
  fi

  # Check status of OCI auth refresher
  local refresher_pid=$(find_oci_auth_refresher_process $OCI_CLI_PROFILE)

  if [[ -z "${refresher_pid}" ]]
  then
    echo "No existing OCI auth refresher process found for profile: ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT}"
  else
    echo "OCI auth refresher process for profile ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT} is ${refresher_pid}"
  fi

  return $exit_code
}

alias ociset='oci_set_profile'
function oci_set_profile() {
  # Usage: ociset <profile_name>
  # Sets the OCI_CLI_PROFILE environment variable and displays tenancy information

  if [[ -z "${1}" ]]
  then
    echo "Error: Profile name required"
    echo "Usage: ociset <profile_name>"
    return 1
  fi

  local profile_name=$1

  # Check if the profile exists
  if [[ ! -d "${HOME}/.oci/sessions/${profile_name}" ]]
  then
    echo "Warning: Profile ${CYAN}${profile_name}${UNSET_FMT} does not exist or has not been authenticated"
    echo "You may need to run: ociauth ${profile_name}"
  fi

  echo "Setting OCI_CLI_PROFILE to ${CYAN}${profile_name}${UNSET_FMT}"
  export OCI_CLI_PROFILE=$profile_name

  # Update the refresher log file path with the new profile
  REFRESHER_LOG_FILE="${HOME}/Library/Logs/oci-auth-refresher_${OCI_CLI_PROFILE}.log"

  echo ""
  oshiv info
}

alias ocilistprofiles='oci_list_profiles'
function oci_list_profiles() {
  # Lists all OCI profiles and their status (valid or expired)
  # Profiles are stored in $HOME/.oci/sessions/

  local sessions_dir="$HOME/.oci/sessions"

  if [[ ! -d "$sessions_dir" ]]
  then
    echo "No OCI sessions directory found at $sessions_dir"
    echo "You may need to authenticate first with: ociauth <profile_name>"
    return 0
  fi

  local profile_count=0
  echo "${CYAN}Profiles:${UNSET_FMT}"

  # Use find instead of ls to handle the case when no profiles exist
  for status_file in $(find "$sessions_dir" -name "session_status" 2>/dev/null)
  do
    local session_status=$(cat "$status_file")
    local profile_name=$(echo "$status_file" | awk -F"/" '{print $6}')
    profile_count=$((profile_count + 1))

    # Highlight the current profile
    if [[ "$profile_name" == "$OCI_CLI_PROFILE" ]]
    then
      if [[ "${session_status}" == "expired" ]]
      then
        echo "* ${profile_name} (${RED}${session_status}${UNSET_FMT}) [current]"
      else
        echo "* ${profile_name} [current]"
      fi
    else
      if [[ "${session_status}" == "expired" ]]
      then
        echo "  ${profile_name} (${RED}${session_status}${UNSET_FMT})"
      else
        echo "  ${profile_name}"
      fi
    fi
  done

  if [[ $profile_count -eq 0 ]]
  then
    echo "  No profiles found"
  fi

  return 0
}
