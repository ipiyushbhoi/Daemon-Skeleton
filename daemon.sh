#! /bin/bash

source constants.sh

CURRENT_PID=`${ECHO} $$`

function setup_daemon() 
{
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Entry: stop_daemon"
	local size_in_kilobytes=""
	local current_size=""

	#
	# Setup required log file and directories
	#

	if [ ! -d "${PROCESS_ID_DIRECTORY}" ]; then
		"${MKDIR}" "${PROCESS_ID_DIRECTORY}"
	fi
  
	if [ ! -f "${PROCESS_ID_FILE}" ]; then
		${TOUCH} "${PROCESS_ID_FILE}"
	fi

	if [ ! -f "${LOG_FILE}" ]; then
		${TOUCH} "${LOG_FILE}"
	else

		#
		# Check if log rotation is required.
		#

		current_size=`${DU} -b "${LOG_FILE}" | ${AWK} '{print $1}'`
		let size_in_kilobytes=${current_size}/1024
		if [ "${size_in_kilobytes}" -gt "${LOG_FILE_MAX_SIZE}" ]; then
			${MV} $LOG_FILE "$LOG_FILE.old"
			${TOUCH} "$LOG_FILE"
		fi
	fi
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Exit: stop_daemon"
}

function start_daemon()
{
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Entry: start_daemon"
  	# Start the daemon.
	# Make sure the directories are there.
	local stderr=""

	setup_daemon	
	check_daemon
	stderr=$?

	if [ "${stderr}" -eq 1 ]; then
		${ECHO} " * INFO: "${DAEMON_NAME}" is already running."
		exit 1
	fi

	${ECHO} " * Starting "${DAEMON_NAME}" with PID: ${CURRENT_PID}."
	${ECHO} "${CURRENT_PID}" > "${PROCESS_ID_FILE}"
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:*** `${DATE} +"%Y-%m-%d"`: Starting up ${DAEMON_NAME}."
        #${ECHO} "*** `${DATE} +%Y-%m-%d-%H-%M-%S`: Starting up ${DAEMON_NAME}" >> "$LOG_FILE"

	# Start the loop.
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Exit: start_daemon"
	loop
}

function stop_daemon() {
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Entry: stop_daemon"
	  # Stop the daemon.
	#if [[ `checkDaemon` == "0" ]]; then
	#	${ECHO} " * Error: "${DAEMON_NAME}" is not running."
	#	exit 1
	#fi

	check_daemon
	stderr=$?
	if [ "${stderr}" -eq 1 ]; then
		${ECHO} " * INFO: "${DAEMON_NAME}" is already running."
		exit 1
	fi

	${ECHO} " * Stopping "${DAEMON_NAME}""
        ${ECHO} "*** `${DATE} +%Y-%m-%d-%H-%M-%S`: ${DAEMON_NAME} stopped" >> "$LOG_FILE"

	if [[ ! -z `cat $PROCESS_ID_FILE` ]]; then
		${KILL} -9 `${CAT} "$PROCESS_ID_FILE"` &> /dev/null
	fi
	${RM} -f "$PROCESS_ID_FILE"
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Exit: stop_daemon"
}

function status_daemon() 
{
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Entry: status_daemon"
	# Query and return whether the daemon is running.
	check_daemon
	strerr=$?
	if [ "${stderr}" -eq 1 ]; then
		${ECHO} " * ${DAEMON_NAME} is running."
	else
		${ECHO} " * ${DAEMON_NAME} isn't running."
	fi

	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Exit: status_daemon"
	exit 0
}

function restart_daemon() 
{
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Entry: restart_daemon"

	check_daemon
	strerr=$?
	if [ "${stderr}" -eq 0 ]; then
		${ECHO} "${DAEMON_NAME} isn't running."
	fi

	stop_daemon
	start_daemon

	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Exit: restart_daemon"
}

function check_daemon()
{
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Entry: check_daemon"
	# Returns 1 if daemon is running else 0
	# Check to see if the daemon is running.
	# This is a different function than statusDaemon
	# so that we can use it other functions.

        stdout=`${PS} aux | ${GREP} "${CURRENT_PID}" | ${GREP} -v ${GREP} > /dev/null`
	stderr=$?
	if [ "${stdout}" -ne 0 ]; then
		return 1
	fi
	#log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:*** `${DATE} +%Y-%m-%d-%H-%M-%S`: ${DAEMON_NAME} is running with PID; restarting."
	log " *** `${DATE} +%Y-%m-%d-%H-%M-%S`:Exit: check_daemon"
	return 0
}

function loop()
{
	# This is the loop.
	now=`${DATE} +%s`
	${ECHO} "Now: $now" >> ${LOG_FILE}
	if [ -z $last ]; then
		last=`${DATE} +%s`
	fi
		
	# doCommands

	# Check to see how long we actually need to sleep for. If we want this to run
	# once a minute and it's taken more than a minute, then we should just run it
	# anyway.

	last=`${DATE} +%s`
	${ECHO} "Last: $now" >> ${LOG_FILE}

	# Set the sleep interval
	${ECHO} "Setting sleep of ${RUN_INTERVAL} seconds" >> "${LOG_FILE}"
	if [[ $((now-last+RUN_INTERVAL+1)) -gt $((RUN_INTERVAL)) ]]; then
		sleep $((now-last+RUN_INTERVAL))
	fi
	${ECHO} "Sleep over" >> "${LOG_FILE}"
	# Startover
        ${ECHO} "*** Starting loop again" >> "${LOG_FILE}"
	loop
}

function log()
{
	# Generic log function.

	${ECHO} "$1" >> "$LOG_FILE"
}

case "$1" in
	start)
		startDaemon
	;;
	stop)
		stopDaemon
	;;
	status)
		statusDaemon
	;;
	restart)
		restartDaemon
	;;
	*)
		${ECHO} "Error: usage $0 { start | stop | restart | status }"
		exit 1
esac
