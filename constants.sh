#! /bin/bash

DAEMON_NAME="${1}"

#
# PLATFORM VARIABLES
#

ECHO=/usr/bin/echo
TOUCH=/usr/bin/touch
MKDIR=/usr/bin/mkdir
KILL=/usr/bin/kill
AWK=/usr/bin/awk
DU=/usr/bin/du
DATE=/usr/bin/date
PS=/usr/bin/ps
CAT=/usr/bin/cat
RM=/usr/bin/rm
GREP=/usr/bin/grep

#
# FILE/DIR PATHS
#

ROOT_DIRECTORY="/root"
PROCESS_ID_DIRECTORY="${ROOT_DIRECTORY}/${DAEMON_NAME}"
PROCESS_ID_FILE="${PROCESS_ID_DIRECTORY}/${DAEMON_NAME}.pid"
LOG_FILE="${PROCESS_ID_DIRECTORY}/${DAEMON_NAME}.log"

#
# CONSTANTS
#

LOG_FILE_MAX_SIZE=1024
RUN_INTERVAL=60
