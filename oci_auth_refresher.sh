#!/bin/zsh
# shellcheck shell=bash disable=SC1071

# ───────────────────────────────────────────────────────────
# oci_auth_refresher.sh  •  v0.1.1
#
# Keeps an OCI CLI session alive by refreshing it shortly
# before it expires. Intended to be launched (nohup) from the
# wrapper script oshell.sh.
# ───────────────────────────────────────────────────────────

# Check if profile argument is provided, use DEFAULT if not
if [[ -z "$1" ]]; then
  echo "No profile name provided, using DEFAULT"
  OCI_CLI_PROFILE="DEFAULT"
else
  OCI_CLI_PROFILE=$1
fi

# Check if script is being run directly (not through nohup)
# If so, relaunch itself using nohup and exit
if [[ -z "$NOHUP" && -t 1 ]]; then
  echo "Launching OCI auth refresher in background for profile ${OCI_CLI_PROFILE}"
  export NOHUP=1
  # Use full path to script to ensure it's detectable by pgrep
  script_path=$(realpath "$0")
  nohup "$script_path" "$OCI_CLI_PROFILE" > /dev/null 2>&1 < /dev/null &
  pid=$!
  echo "Process started with PID $pid"
  echo "You can verify it's running with: pgrep -af oci_auth_refresher.sh"
  echo "Check logs at: ${HOME}/.oci/sessions/${OCI_CLI_PROFILE}/oci-auth-refresher_${OCI_CLI_PROFILE}.log"
  exit 0
fi

# Source common functions from oshell.sh if OSHELL_HOME is set
if [[ -n "$OSHELL_HOME" && -f "$OSHELL_HOME/oshell.sh" ]]; then
  # Source the configuration and helper functions
  # shellcheck disable=SC1090
  source <(grep -A 100 "^# Configuration" "$OSHELL_HOME/oshell.sh" | grep -B 100 "^function oci_authenticate" | grep -v "^function oci_authenticate")

  # Set paths using the sourced function
  set_profile_paths
else
  # Fallback to local definitions if oshell.sh can't be sourced
  # Configuration
  PREEMPT_REFRESH_TIME=60  # Attempt to refresh 60 sec before session expiration
  LOG_LOCATION="${HOME}/.oci/sessions/${OCI_CLI_PROFILE}/oci-auth-refresher_${OCI_CLI_PROFILE}.log"
  SESSION_STATUS_FILE="${HOME}/.oci/sessions/${OCI_CLI_PROFILE}/session_status"

  # Create session directory if it doesn't exist
  mkdir -p "${HOME}/.oci/sessions/${OCI_CLI_PROFILE}"

  # Helper function to log messages
  function log_message() {
    local message=$1
    echo "$(date '+%F %T'): $message" >> "$LOG_LOCATION" 2>&1 < /dev/null
  }
fi

# Helper function to convert date string to epoch time
function to_epoch() {
  local ts="$1"

  # Check if timestamp is empty
  if [[ -z "$ts" ]]; then
    log_message "Warning: Empty timestamp provided to to_epoch()"
    return 1
  fi

  # Log the timestamp we're trying to convert for debugging
  log_message "Converting timestamp: '${ts}' to epoch"

  if date --version >/dev/null 2>&1; then
    # GNU date (Linux) - more forgiving with formats
    if ! date -d "${ts}" +%s 2>/dev/null; then
      log_message "Error: GNU date failed to parse timestamp '${ts}'"
      return 1
    fi
  else
    # BSD date (macOS) - needs explicit format
    # Try different format patterns that might match the timestamp
    for fmt in "%Y-%m-%d %H:%M:%S" "%Y-%m-%d %T" "%Y-%m-%dT%H:%M:%S" "%Y-%m-%d"; do
      if date -j -f "$fmt" "${ts}" +%s 2>/dev/null; then
        return 0
      fi
    done

    # If we get here, all format attempts failed
    log_message "Error: Failed to parse timestamp '${ts}' with any known format"
    return 1
  fi
}

# Function to get the remaining duration of the current session
function get_remaining_session_duration() {
  log_message "Validating session for profile ${OCI_CLI_PROFILE}"

  if oci session validate --profile "$OCI_CLI_PROFILE" --local >> "$LOG_LOCATION" 2>&1; then
    log_message "Session is valid"
    oci_session_status="valid"
    echo "$oci_session_status" > "$SESSION_STATUS_FILE"

    # Get expiration timestamp
    local exp_ts
    local validate_output

    # Capture both stdout and stderr
    validate_output=$(oci session validate --profile "$OCI_CLI_PROFILE" --local 2>&1)
    log_message "Session validate output: '${validate_output}'"

    # Extract the expiration timestamp using a simple approach
    # The output format is "Session is valid until YYYY-MM-DD HH:MM:SS"
    log_message "Raw validate output: '$validate_output'"

    # Use a simple approach to extract the date and time
    exp_ts=$(echo "$validate_output" | sed -E 's/.*until ([0-9]{4}-[0-9]{2}-[0-9]{2} [0-9]{2}:[0-9]{2}:[0-9]{2}).*/\1/')

    # If the output is unchanged, it means the pattern didn't match
    if [[ "$exp_ts" == "$validate_output" ]]; then
      log_message "Warning: Could not extract expiration timestamp using sed"
      exp_ts=""
    fi

    # If still empty, try to extract just the date and time parts
    if [[ -z "$exp_ts" ]]; then
      log_message "Trying to extract date and time separately..."
      local date_part
      date_part=$(echo "$validate_output" | grep -o "[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}")
      local time_part
      time_part=$(echo "$validate_output" | grep -o "[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}")

      if [[ -n "$date_part" && -n "$time_part" ]]; then
        exp_ts="$date_part $time_part"
        log_message "Extracted date ($date_part) and time ($time_part) separately"
      else
        log_message "Failed to extract date and time separately"
      fi
    fi

    log_message "Session expiration timestamp: ${exp_ts}"

    # Verify that we have a valid-looking timestamp before proceeding
    if [[ -z "$exp_ts" || ! "$exp_ts" =~ [0-9]{4}-[0-9]{2}-[0-9]{2} ]]; then
      log_message "Error: Invalid or missing expiration timestamp format"
      log_message "Raw output was: ${validate_output}"
      oci_session_status="expired"
      echo "$oci_session_status" > "$SESSION_STATUS_FILE"
      remaining_time=0
      return
    fi

    # Calculate remaining time
    local exp_epoch
    if ! exp_epoch=$(to_epoch "${exp_ts}"); then
      log_message "Failed to convert expiration timestamp to epoch time"
      oci_session_status="expired"
      echo "$oci_session_status" > "$SESSION_STATUS_FILE"
      remaining_time=0
      return
    fi

    local now_epoch
    now_epoch=$(date +%s)
    remaining_time=$((exp_epoch - now_epoch))

    log_message "Remaining time: $((remaining_time/60)) min (${remaining_time}s)"
  else
    log_message "Session is expired"
    oci_session_status="expired"
    echo "$oci_session_status" > "$SESSION_STATUS_FILE"
    remaining_time=0
  fi
}

# Function to refresh the session
function refresh_session() {
  log_message "Refreshing session for ${OCI_CLI_PROFILE}"

  if oci session refresh --profile "$OCI_CLI_PROFILE" >> "$LOG_LOCATION" 2>&1; then
    log_message "Refresh successful"
    return 0
  else
    log_message "Refresh failed"
    oci_session_status="expired"
    echo "$oci_session_status" > "$SESSION_STATUS_FILE"
    return 1
  fi
}

# Initialize variables
oci_session_status="unknown"
remaining_time=0

# Initialize log file
log_message ""
log_message "───── OCI auth refresher started for profile ${OCI_CLI_PROFILE} ─────"

# Check if session directory exists
if [[ ! -d "${HOME}/.oci/sessions/${OCI_CLI_PROFILE}" ]]; then
  log_message "Missing session directory; user probably hasn't authenticated"
  log_message "Exiting."
  exit 1
fi

# Main loop
get_remaining_session_duration

while [[ "$oci_session_status" == "valid" ]]; do
  if (( remaining_time > PREEMPT_REFRESH_TIME )); then
    sleep_for=$((remaining_time - PREEMPT_REFRESH_TIME))
    log_message "Sleeping ${sleep_for}s before next refresh"
    sleep "$sleep_for"

    if ! refresh_session; then
      log_message "Exiting due to refresh failure"
      exit 1
    fi

    get_remaining_session_duration
  else
    log_message "Session too close to expiry; letting it lapse"
    oci_session_status="expired"
    echo "$oci_session_status" > "$SESSION_STATUS_FILE"
  fi
done

log_message "Session expired – refresher exiting"
exit 0
