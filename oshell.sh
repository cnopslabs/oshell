#!/bin/zsh
# shellcheck shell=bash disable=SC1071

# Version: 0.1.1

# Color definitions for terminal output
CYAN='\033[0;96m'
YELLOW='\033[;33m'
RED='\033[0;31m'

if [[ -n "$TERM" ]]; then
  UNSET_FMT=$(tput sgr0)
else
  UNSET_FMT='\033[0m'
fi

# Configuration
export PREEMPT_REFRESH_TIME=60  # Attempt to refresh 60 sec before session expiration

# Path variables (will be updated dynamically once OCI_CLI_PROFILE is set)
LOG_LOCATION=""
SESSION_STATUS_FILE=""

# Set dynamic session paths after profile is set
function set_profile_paths() {
  LOG_LOCATION="${HOME}/.oci/sessions/${OCI_CLI_PROFILE}/oci-auth-refresher_${OCI_CLI_PROFILE}.log"
  SESSION_STATUS_FILE="${HOME}/.oci/sessions/${OCI_CLI_PROFILE}/session_status"
  mkdir -p "${HOME}/.oci/sessions/${OCI_CLI_PROFILE}"
}

# Helper function to log messages
function log_message() {
  local message=$1
  # Check if LOG_LOCATION is set and the directory exists
  if [[ -n "$LOG_LOCATION" && -d "$(dirname "$LOG_LOCATION")" ]]; then
    echo "$(date '+%F %T'): $message" >> "$LOG_LOCATION" 2>&1 < /dev/null
  else
    # If we can't log to file, just print to stderr for debugging
    >&2 echo "log_message: $(date '+%F %T'): $message"
  fi
}

# Helper function to find OCI auth refresher process for a specific profile
function find_oci_auth_refresher_process() {
  local profile=$1
  local found_pid=""

  for r_pid in $(pgrep -f oci_auth_refresher.sh); do
    r_oci_profile=$(ps -p "$r_pid" -o command | grep -v COMMAND | awk '{print $3}')
    [[ $LOGLEVEL == "DEBUG" ]] && log_message "Existing refresher process: PID=$r_pid, PROFILE=$r_oci_profile"
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
    echo "expired" > "$SESSION_STATUS_FILE"
  else
    log_message "Starting new refresher process for ${profile}"
  fi

  # Ensure OSHELL_HOME is exported so oci_auth_refresher.sh can source common functions
  export OSHELL_HOME="${OSHELL_HOME:-$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)}"
  log_message "Oshell home: ${OSHELL_HOME}"
  nohup "${OSHELL_HOME}/oci_auth_refresher.sh" "$profile" > /dev/null 2>&1 < /dev/null &
  sleep 1
}

alias ociauth='oci_authenticate'
function oci_authenticate() {
  oci_tenancy_map "$@"
  echo ""

  local profile_name="${1:-DEFAULT}"
  echo -e "Using profile: ${CYAN}${profile_name}${UNSET_FMT}"

  if ! oci session authenticate --profile-name "$profile_name"; then
    echo "OCI authentication failed"
    return 1
  fi

  unset OCI_CLI_TENANCY OCI_TENANCY_NAME OCI_COMPARTMENT CID OCI_CLI_REGION
  echo "Setting OCI Profile to ${profile_name}"
  export OCI_CLI_PROFILE=$profile_name
  set_profile_paths

  log_message "Checking for existing refresher process for $OCI_CLI_PROFILE"
  local refresher_pid
  refresher_pid=$(find_oci_auth_refresher_process "$OCI_CLI_PROFILE")

  if [[ -n "$refresher_pid" ]]; then
    start_oci_auth_refresher "$OCI_CLI_PROFILE" "true"
  else
    start_oci_auth_refresher "$OCI_CLI_PROFILE" "false"
  fi

  oci_tenancy_map "$@"
}

alias ociexit='oci_auth_logout'
function oci_auth_logout() {
  local profile_name="${1:-$OCI_CLI_PROFILE}"

  if [[ -z "${profile_name}" ]]; then
    echo "No active OCI profile found. Nothing to log out from."
    return 0
  fi

  # Temporarily set OCI_CLI_PROFILE to the provided profile for path setting
  local original_profile="$OCI_CLI_PROFILE"
  export OCI_CLI_PROFILE="$profile_name"
  set_profile_paths

  # Check if a refresher process exists and terminate it
  local refresher_pid
  refresher_pid=$(find_oci_auth_refresher_process "$profile_name")
  local refresher_terminated=false

  if [[ -n "$refresher_pid" ]]; then
    echo "Killing refresher process for profile ${CYAN}${profile_name}${UNSET_FMT}"
    log_message "Killing refresher process for profile ${profile_name}"
    kill -9 "$refresher_pid"
    echo "Successfully terminated background refresher for profile: ${CYAN}${profile_name}${UNSET_FMT}"
    refresher_terminated=true
  else
    echo "No background refresher found for profile: ${CYAN}${profile_name}${UNSET_FMT}"
  fi

  # Always attempt to terminate the session if we're working with the current active profile
  if [[ "$profile_name" == "$original_profile" ]]; then
    log_message "Attempting to terminate OCI session for profile ${profile_name}"

    # Capture the output of the command in a variable
    local terminate_output
    terminate_output=$(oci session terminate --profile "$profile_name" 2>&1)
    local terminate_status=$?

    # Log the output
    log_message "OCI session terminate output: ${terminate_output}"

    if [[ $terminate_status -eq 0 ]]; then
      log_message "Successfully terminated OCI session for profile ${profile_name}"
      echo "Successfully logged out from OCI profile: ${CYAN}${profile_name}${UNSET_FMT}"
    else
      log_message "Failed to terminate OCI session for profile ${profile_name} (exit code: ${terminate_status})"
      # Only show error message if we didn't terminate a refresher process
      if [[ "$refresher_terminated" != "true" ]]; then
        echo "Note: No active background refresher was found for this profile."
        echo "If you're trying to terminate an OCI session, please ensure you have an active session first."
      fi
    fi

    # Clear the environment variable after logout attempt
    unset OCI_CLI_PROFILE
  else
    # Restore the original profile if we were just killing a background refresher
    export OCI_CLI_PROFILE="$original_profile"
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
  oci_config_print
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

# Display OCI tenancy map with formatted colors
alias ocimap='oci_tenancy_map'
function oci_tenancy_map() {
  local tenancy_map_path="${HOME}/.oci/tenancy-map.yaml"

  if [[ ! -f "$tenancy_map_path" ]]; then
    echo "⚠️ Cannot find tenancy map at: $tenancy_map_path" >&2
    return 1
  fi

  if ! command -v yq >/dev/null 2>&1; then
    echo -e "⚠️ 'yq' is required to render your tenancy map. To install run:\nbrew install yq" >&2
    return 1
  fi

  # Color definitions
  local BLUE='\033[1;34m'
  local YELLOW='\033[0;33m'
  local RESET='\033[0m'

  # Header row
  printf "${BLUE}%-28s %-28s %-7s %-35s %-s${RESET}\n" "ENVIRONMENT" "TENANCY" "REALM" "COMPARTMENTS" "REGIONS"

  # Read each row using yq and print formatted output
  yq -r '.[] | [.environment, .tenancy, .realm, .compartments, .regions] | @tsv' "$tenancy_map_path" | \
  while IFS=$'\t' read -r env tenancy realm comp regions; do
    printf "${YELLOW}%-28s${RESET} %-28s %-7s %-35s %s\n" "$env" "$tenancy" "$realm" "$comp" "$regions"
  done

  # Footer message
    printf "\nTo set Tenancy, Compartment, or Region export the \033[0;33mOCI_TENANCY_NAME\033[0m, \033[0;33mOCI_COMPARTMENT\033[0m, or \033[0;33mOCI_CLI_REGION\033[0m environment variables.\n\n"

    printf "Or if using oshell, run:\n"
    printf "oci_set_tenancy \033[0;33mTENANCY_NAME\033[0m\n"
    printf "oci_set_tenancy \033[0;33mTENANCY_NAME COMPARTMENT_NAME\033[0m\n"
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

  set_profile_paths

  # Check if the profile directory exists
  if [[ ! -d "${HOME}/.oci/sessions/${OCI_CLI_PROFILE}" ]]; then
    echo "Profile directory for ${CYAN}${OCI_CLI_PROFILE}${UNSET_FMT} does not exist."
    echo "You may need to authenticate first with: ociauth ${OCI_CLI_PROFILE}"
    return 1
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

  export OCI_CLI_PROFILE=$profile_name
  set_profile_paths

  if [[ ! -d "${HOME}/.oci/sessions/${profile_name}" ]]; then
    echo "Warning: Profile ${CYAN}${profile_name}${UNSET_FMT} does not exist or has not been authenticated"
    echo "You may need to run: ociauth ${profile_name}"
  fi

  echo "Setting OCI_CLI_PROFILE to ${CYAN}${profile_name}${UNSET_FMT}"
  echo ""
  oci_tenancy_map "$@"
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

  # Get all profile directories
  local profile_dirs=()
  while IFS= read -r line; do
    profile_dirs+=("$line")
  done < <(find "$sessions_dir" -mindepth 1 -maxdepth 1 -type d 2>/dev/null)

  for profile_dir in "${profile_dirs[@]}"; do
    local profile_name
    profile_name=$(basename "$profile_dir")
    profile_count=$((profile_count + 1))

    # Check if session_status file exists
    local session_status="unknown"
    if [[ -f "$profile_dir/session_status" ]]; then
      session_status=$(cat "$profile_dir/session_status")
    fi

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
# ---------- Color & helper ----------
YELLOW='\033[0;33m'
RESET='\033[0m'

print_kv() {        # key-value with yellow value
  printf "%-14s: ${YELLOW}%s${RESET}\n" "$1" "$2"
}

# Resolve default compartment from tenancy-map.yaml
lookup_tenancy_info() {
  local tname=$1 field=$2
  [[ -z "$tname" ]] && return        # nothing to look up
  command -v yq >/dev/null 2>&1 || return

  # Use grep to check if the tenancy exists in the YAML file
  if ! grep -q "tenancy: $tname" "$HOME/.oci/tenancy-map.yaml"; then
    echo "Warning: Tenancy '$tname' not found in tenancy-map.yaml. Please check your tenancy-map.yaml file." >&2
    return
  fi

  # Get the requested field using grep and awk for better reliability
  local result
  if [[ "$field" == "compartments" ]]; then
    # Extract the compartments for the specified tenancy
    result=$(grep -A 4 "tenancy: $tname" "$HOME/.oci/tenancy-map.yaml" | grep "compartments" | awk '{$1=""; print $0}' | xargs)
  else
    # Use yq for other fields
    # shellcheck disable=SC2016  # $tn and $f are jq variables, not shell variables
    result=$(yq -r --arg tn "$tname" --arg f "$field" \
      'map(select(.tenancy == $tn))[0][$f] // ""' \
      "$HOME/.oci/tenancy-map.yaml" 2>/dev/null)
  fi

  echo "$result"
}

oci_config_print() {
  local tenancy_name=${OCI_TENANCY_NAME:-}
  local compartment=${OCI_COMPARTMENT:-}

  # If no compartment is set, try to get it from the tenancy map
  [[ -n "$tenancy_name" && -z "$compartment" ]] \
    && compartment=$(lookup_tenancy_info "$tenancy_name" compartments)

  print_kv "Tenancy name" "${tenancy_name:-<unset>}"
  print_kv "Compartment"  "${compartment:-<unset>}"
}
