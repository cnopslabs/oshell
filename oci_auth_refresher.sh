#!/bin/zsh

# Version: 0.1.0

OCI_PROFILE=$1
PREEMPT_REFRESH_TIME=60  # Attempt to refresh 60 sec before session expiration
LOG_LOCATION="${HOME}/Library/Logs/oci-auth-refresher_${1}.log"

function get_remaining_session_duration() {
  date >> $LOG_LOCATION 2>&1 < /dev/null
  echo "Checking if session is valid for profile ${1}" >> $LOG_LOCATION 2>&1 < /dev/null
  oci session validate --profile $1 --local >> $LOG_LOCATION 2>&1 < /dev/null

  if [[ $? -eq 0 ]]
  then
    echo "Session is valid" >> $LOG_LOCATION 2>&1 < /dev/null
    oci_session_status="valid"
    echo $oci_session_status > ${HOME}/.oci/sessions/$1/session_status

    echo "Determining remaining session duration" >> $LOG_LOCATION 2>&1 < /dev/null
    session_expiration_date_time=$(oci session validate --profile $1 --local 2>&1 | awk '{print $5, $6}')
    echo "DEBUG: session_expiration_date_time: ${session_expiration_date_time}"

    session_expiration_date_time_epoch=`date -j -f "%Y-%m-%d %H:%M:%S" "${session_expiration_date_time}" +%s`
    current_epoch=`date '+%s'`
    remaining_time=$(($session_expiration_date_time_epoch-$current_epoch))
    remaining_time_min=$(($remaining_time/60))

    echo "Remaining time: ${remaining_time_min} minutes (${remaining_time} seconds)" >> $LOG_LOCATION 2>&1 < /dev/null
  else
    echo "Session is expired" >> $LOG_LOCATION 2>&1 < /dev/null
    oci_session_status="expired"
    echo $oci_session_status > ${HOME}/.oci/sessions/$1/session_status
  fi
}

function refresh_session () {
  date >> $LOG_LOCATION 2>&1 < /dev/null
  echo "Attempting to refresh session for profile ${1}" >> $LOG_LOCATION 2>&1 < /dev/null
  oci session refresh --profile $1 >> $LOG_LOCATION 2>&1 < /dev/null

  if [[ $? -eq 0 ]]
  then
    echo "Refresh successful" >> $LOG_LOCATION 2>&1 < /dev/null
  else
    echo "Refresh failed, exiting..." >> $LOG_LOCATION 2>&1 < /dev/null
    oci_session_status="expired"
    echo $oci_session_status > ${HOME}/.oci/sessions/$1/session_status
    exit 1
  fi
}

echo "---" >> $LOG_LOCATION 2>&1 < /dev/null
date >> $LOG_LOCATION 2>&1 < /dev/null
echo "Initiating OCI session refresher for profile ${OCI_PROFILE}" >> $LOG_LOCATION 2>&1 < /dev/null

get_remaining_session_duration $OCI_PROFILE

while [ $oci_session_status != "expired" ]
do
  if [[ $remaining_time -gt $PREEMPT_REFRESH_TIME ]]
  then
    sleep_time=$(($remaining_time-$PREEMPT_REFRESH_TIME))
    sleep_time_min=$(($sleep_time/60))
    echo "Sleeping for ${sleep_time_min} minutes (${sleep_time} seconds)\n" >> $LOG_LOCATION 2>&1 < /dev/null
    sleep $sleep_time

    refresh_session $OCI_PROFILE

    get_remaining_session_duration $OCI_PROFILE
  else
    echo "Unable to continue the refresh process, exiting" >> $LOG_LOCATION 2>&1 < /dev/null
    oci_session_status="expired"
    echo $oci_session_status > ${HOME}/.oci/sessions/$OCI_PROFILE/session_status
    exit 0
  fi
done

# TODO: add total duration timer and allow passing as input
