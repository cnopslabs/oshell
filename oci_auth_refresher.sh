#!/bin/zsh

# Version: 0.1.0
# OCI Authentication Refresher
# This script keeps an OCI session active by refreshing it before it expires

# Check if profile argument is provided
if [[ -z "$1" ]]
then
  echo "Error: OCI profile name required"
  echo "Usage: $0 <profile_name>"
  exit 1
fi

# Configuration
OCI_PROFILE=$1
PREEMPT_REFRESH_TIME=60  # Attempt to refresh 60 sec before session expiration
LOG_LOCATION="${HOME}/Library/Logs/oci-auth-refresher_${OCI_PROFILE}.log"
SESSION_STATUS_FILE="${HOME}/.oci/sessions/${OCI_PROFILE}/session_status"

# Helper function to log messages
function log_message() {
  local message=$1
  echo "$(date): $message" >> $LOG_LOCATION 2>&1 < /dev/null
}

# Function to get the remaining duration of the current session
function get_remaining_session_duration() {
  local profile=$1

  log_message "Checking if session is valid for profile ${profile}"
  oci session validate --profile $profile --local >> $LOG_LOCATION 2>&1 < /dev/null
  local validate_result=$?

  if [[ $validate_result -eq 0 ]]
  then
    log_message "Session is valid"
    oci_session_status="valid"
    echo $oci_session_status > $SESSION_STATUS_FILE

    log_message "Determining remaining session duration"
    local session_expiration_date_time=$(oci session validate --profile $profile --local 2>&1 | awk '{print $5, $6}')
    log_message "Session expiration date/time: ${session_expiration_date_time}"

    # Convert expiration time to epoch seconds
    local session_expiration_date_time_epoch=$(date -j -f "%Y-%m-%d %H:%M:%S" "${session_expiration_date_time}" +%s)
    local current_epoch=$(date '+%s')
    remaining_time=$(($session_expiration_date_time_epoch-$current_epoch))
    local remaining_time_min=$(($remaining_time/60))

    log_message "Remaining time: ${remaining_time_min} minutes (${remaining_time} seconds)"
  else
    log_message "Session is expired"
    oci_session_status="expired"
    echo $oci_session_status > $SESSION_STATUS_FILE
  fi
}

# Function to refresh the session
function refresh_session() {
  local profile=$1

  log_message "Attempting to refresh session for profile ${profile}"
  oci session refresh --profile $profile >> $LOG_LOCATION 2>&1 < /dev/null
  local refresh_result=$?

  if [[ $refresh_result -eq 0 ]]
  then
    log_message "Refresh successful"
    return 0
  else
    log_message "Refresh failed, exiting..."
    oci_session_status="expired"
    echo $oci_session_status > $SESSION_STATUS_FILE
    return 1
  fi
}

# Initialize log file
log_message "---"
log_message "Initiating OCI session refresher for profile ${OCI_PROFILE}"

# Check if session directory exists
if [[ ! -d "${HOME}/.oci/sessions/${OCI_PROFILE}" ]]
then
  log_message "Error: Session directory for profile ${OCI_PROFILE} does not exist"
  log_message "You may need to authenticate first with: oci session authenticate --profile-name ${OCI_PROFILE}"
  exit 1
fi

# Main loop
get_remaining_session_duration $OCI_PROFILE

while [[ $oci_session_status != "expired" ]]
do
  if [[ $remaining_time -gt $PREEMPT_REFRESH_TIME ]]
  then
    # Calculate sleep time (refresh before expiration)
    sleep_time=$(($remaining_time-$PREEMPT_REFRESH_TIME))
    sleep_time_min=$(($sleep_time/60))
    log_message "Sleeping for ${sleep_time_min} minutes (${sleep_time} seconds)"
    sleep $sleep_time

    # Refresh the session
    refresh_session $OCI_PROFILE
    if [[ $? -ne 0 ]]
    then
      log_message "Exiting due to refresh failure"
      exit 1
    fi

    # Check the new session duration
    get_remaining_session_duration $OCI_PROFILE
  else
    log_message "Remaining time too short to continue the refresh process, exiting"
    oci_session_status="expired"
    echo $oci_session_status > $SESSION_STATUS_FILE
    exit 0
  fi
done

log_message "Session expired, exiting"
exit 0
