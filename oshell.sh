#!/bin/zsh
# shellcheck shell=bash disable=SC1071


# Version: 0.1.0

# Color definitions for terminal output
CYAN='\033[0;96m'
YELLOW='\033[;33m'
# Check if TERM is set before using tput
if [[ -n "$TERM" ]]; then
  UNSET_FMT=$(tput sgr0)
else
  UNSET_FMT='\033[0m'
fi
RED='\033[0;31m'

# Configuration
PREEMPT_REFRESH_TIME=60  # Attempt to refresh 60 sec before session expiration
LOG_LOCATION="${HOME}/.oci/sessions/${OCI_CLI_PROFILE}/oci-auth-refresher_${OCI_CLI_PROFILE}.log"
SESSION_STATUS_FILE="${HOME}/.oci/sessions/${OCI_CLI_PROFILE}/session_status"

# Ensure session directory exists
mkdir -p "${HOME}/.oci/sessions/${OCI_CLI_PROFILE}"

# Helper function to log messages
function log_message() {
  local message=$1
  echo "$(date): $message" >> "$LOG_LOCATION" 2>&1 < /dev/null
}

# Helper function to find OCI auth refresher process for a specific profile
function find_oci_auth_refresher_process() {
  local profile=$1
  local found_pid=""

  for r_pid in $(pgrep -f oci_auth_refresher.sh)
  do
    r_oci_profile=$(ps -p "$r_pid" -o command | grep -v COMMAND | awk '{print $3}')
    if [[ $LOGLEVEL == "DEBUG" ]]; then
      log_message "Existing refresher process: PID=$r_pid, PROFILE=$r_oci_profile"
    fi
    if [[ "$profile" == "$r_oci_profile" ]]; then
      found_pid=$r_pid
      break
    fi
  done

  echo "$found_pid"
}

function start_oci_auth_refresher() {
  local profile=$1
  local restart=$2

  if [[ $restart == "true" ]]; then
    log_message "Existing refresher process found for ${profile}, restarting..."
    kill -9 "$(find_oci_auth_refresher_process "$profile")"
    # Set session status file path for this profile
    local profile_session_status="${HOME}/.oci/sessions/${profile}/session_status"
    echo "expired" > "$profile_session_status"
  else
    log_message "Starting new refresher process for ${profile}"
  fi

  nohup "${OSHELL_HOME}/oci_auth_refresher.sh" "$profile" > /dev/null 2>&1 < /dev/null &
  sleep 1
}

alias ociauth='oci_authenticate'
function oci_authenticate() {
  oshiv info
  echo ""

  local profile_name="${1:-DEFAULT}"
  printf "Using profile: %s%s%s\n" "${CYAN}" "${profile_name}" "${UNSET_FMT}"

  if ! oci session authenticate --profile-name "$profile_name"; then
    echo "OCI authentication failed"
    return 1
  fi

  unset OCI_CLI_TENANCY OCI_TENANCY_NAME OCI_COMPARTMENT CID OCI_CLI_REGION
  echo "Setting OCI Profile to ${profile_name}"
  export OCI_CLI_PROFILE=$profile_name

  log_message "Checking for existing refresher process for $OCI_CLI_PROFILE"
  local refresher_pid
  refresher_pid=$(find_oci_auth_refresher_process "$OCI_CLI_PROFILE")

  if [[ -n "$refresher_pid" ]]; then
    start_oci_auth_refresher "$OCI_CLI_PROFILE" "true"
  else
    start_oci_auth_refresher "$OCI_CLI_PROFILE" "false"
  fi

  oshiv info
}

alias ociexit='oci_auth_logout'
function oci_auth_logout() {
  if [[ -z "${OCI_CLI_PROFILE}" ]]; then
    echo "No active OCI profile found. Nothing to log out from."
    return 0
  fi

  local refresher_pid
  refresher_pid=$(find_oci_auth_refresher_process "$OCI_CLI_PROFILE")
  if [[ -n "$refresher_pid" ]]; then
    log_message "Killing refresher process for profile ${OCI_CLI_PROFILE}"
    kill -9 "$refresher_pid"
    echo "expired" > "$SESSION_STATUS_FILE"
  fi

  if oci session terminate; then
    echo "Successfully logged out from OCI profile: ${CYAN}${OCI_CLI_PROFILE}${UNSET_FMT}"
  else
    echo "Failed to terminate OCI session for profile: ${CYAN}${OCI_CLI_PROFILE}${UNSET_FMT}"
    return 1
  fi
}

alias ocisettenancy='oci_set_tenancy'
function oci_set_tenancy() {
  local tenancy_name=$1
  local compartment_name=$2

  if [[ -z "${tenancy_name}" ]]; then
    echo "Error: Tenancy name required"
    echo "Usage: ocisettenancy <tenancy_name> [compartment_name]"
    return 1
  fi

  echo "Setting tenancy to ${YELLOW}${tenancy_name}${UNSET_FMT} via ${YELLOW}OCI_TENANCY_NAME${UNSET_FMT}"
  export OCI_TENANCY_NAME=$tenancy_name

  if [[ -n "${compartment_name}" ]]; then
    echo "Setting compartment to ${YELLOW}${compartment_name}${UNSET_FMT} via ${YELLOW}OCI_COMPARTMENT${UNSET_FMT}"
    export OCI_COMPARTMENT=$compartment_name
  fi

  echo ""
  oshiv config
  return 0
}

alias ocienv='oci_env_print'
function oci_env_print() {
  echo "OCI Environment Variables:"
  local oci_vars
  oci_vars=$(env | grep -E "OCI_|CID")

  if [[ -z "$oci_vars" ]]; then
    echo "  No OCI environment variables set"
  else
    echo "$oci_vars"
  fi

  return 0
}

alias ociclear='oci_env_clear'
function oci_env_clear() {
  local profile=$OCI_CLI_PROFILE

  echo "Clearing OCI environment variables..."
  unset OCI_CLI_TENANCY OCI_TENANCY_NAME OCI_COMPARTMENT CID OCI_CLI_REGION

  if [[ -n "$profile" ]]; then
    export OCI_CLI_PROFILE=$profile
    echo "Kept OCI_CLI_PROFILE=$profile"
  fi

  echo "Done"
  return 0
}

alias ocistat='oci_auth_status'
function oci_auth_status() {
  if [[ -z "${OCI_CLI_PROFILE}" ]]; then
    echo "No active OCI profile found. Set a profile with ociset <profile_name>."
    return 0
  fi

  echo "Checking session status for profile: ${CYAN}${OCI_CLI_PROFILE}${UNSET_FMT}"
  oci session validate --local
  local exit_code=$?

  if [[ $exit_code -ne 0 ]]; then
    echo "Session for profile ${CYAN}${OCI_CLI_PROFILE}${UNSET_FMT} is ${RED}invalid${UNSET_FMT}"
  fi

  local refresher_pid
  refresher_pid=$(find_oci_auth_refresher_process "$OCI_CLI_PROFILE")

  if [[ -z "${refresher_pid}" ]]; then
    echo "No existing OCI auth refresher process found for profile: ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT}"
  else
    echo "OCI auth refresher process for profile ${CYAN}$OCI_CLI_PROFILE${UNSET_FMT} is ${refresher_pid}"
  fi

  return $exit_code
}

alias ociset='oci_set_profile'
function oci_set_profile() {
  if [[ -z "${1}" ]]; then
    echo "Error: Profile name required"
    echo "Usage: ociset <profile_name>"
    return 1
  fi

  local profile_name=$1

  if [[ ! -d "${HOME}/.oci/sessions/${profile_name}" ]]; then
    echo "Warning: Profile ${CYAN}${profile_name}${UNSET_FMT} does not exist or has not been authenticated"
    echo "You may need to run: ociauth ${profile_name}"
  fi

  echo "Setting OCI_CLI_PROFILE to ${CYAN}${profile_name}${UNSET_FMT}"
  export OCI_CLI_PROFILE=$profile_name
  LOG_LOCATION="${HOME}/.oci/sessions/${OCI_CLI_PROFILE}/oci-auth-refresher_${OCI_CLI_PROFILE}.log"
  SESSION_STATUS_FILE="${HOME}/.oci/sessions/${OCI_CLI_PROFILE}/session_status"

  # Ensure session directory exists
  mkdir -p "${HOME}/.oci/sessions/${OCI_CLI_PROFILE}"

  echo ""
  oshiv info
}

alias ocilistprofiles='oci_list_profiles'
function oci_list_profiles() {
  local sessions_dir="$HOME/.oci/sessions"

  if [[ ! -d "$sessions_dir" ]]; then
    echo "No OCI sessions directory found at $sessions_dir"
    echo "You may need to authenticate first with: ociauth <profile_name>"
    return 0
  fi

  local profile_count=0
  echo "${CYAN}Profiles:${UNSET_FMT}"

  # Store status files in an array to avoid subshell issues
  mapfile -t status_files < <(find "$sessions_dir" -name "session_status" 2>/dev/null)

  # Process each status file
  for status_file in "${status_files[@]}"
  do
    local session_status
    session_status=$(cat "$status_file")
    local profile_name
    profile_name=$(echo "$status_file" | awk -F"/" '{print $6}')
    profile_count=$((profile_count + 1))

    if [[ "$profile_name" == "$OCI_CLI_PROFILE" ]]; then
      if [[ "$session_status" == "expired" ]]; then
        echo "* ${profile_name} (${RED}${session_status}${UNSET_FMT}) [current]"
      else
        echo "* ${profile_name} [current]"
      fi
    else
      if [[ "$session_status" == "expired" ]]; then
        echo "  ${profile_name} (${RED}${session_status}${UNSET_FMT})"
      else
        echo "  ${profile_name}"
      fi
    fi
  done

  if [[ $profile_count -eq 0 ]]; then
    echo "  No profiles found"
  fi

  return 0
}
