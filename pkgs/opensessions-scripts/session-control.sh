#! /usr/bin/env bash

# Nuno Silva <nuno.silva@rnl.tecnico.ulisboa.pt>
# 2015-09


# Bridge entre PAM session e logsession.php.
# Envia logins, logouts e hard-reset das maquinas.
# Deve ser chamado em eventos de login e logout pelo PAM,
#  no arranque do PC com "boot" no primeiro argumento,
#  e quando o PC desliga com "shutdown" no primeiro argumento.
# O script assume que o PAM define varias variaveis de ambiente e usa-as
#  para obter as informacoes que necessita (PAM_USER, etc)
#
# session_control.sh [boot|shutdown]


# OS where the script is running on
OS="Linux"

# location of the logsession.php script
LOGSESSION_HOST=rnl.tecnico.ulisboa.pt
LOGSESSION_URL="https://$LOGSESSION_HOST/logsession"

# report errors to this email
ERROR_EMAIL="robots@rnl.tecnico.ulisboa.pt"

ERROR_SUBJECT="[Opensessions]"


# user and password for curl
# netrc syntax:
# machine [HOST] login [USER] password [PASSWORD]
NETRC_FILE="/etc/open-sessions/netrc"

# used when logging to syslog
TAG=session_control.sh

# dont want other users to read files we create
umask 0077

DATE=$(date +%Y-%m-%d_%H-%M-%S)

# sendmail is in /usr/sbin; curl, logger and id are in /usr/bin
# PAM does not define PATH
export PATH=$PATH:/usr/sbin/:/usr/bin/

# PAM_USER is not set when the script runs on boot
if test -z "$PAM_USER"; then
    USER_ID="$USER"
else
    # users can login using "name.lastname" or something instead of istxxxxxx
    # "id -u --name" gives the istxxxxxx
    USER_ID=$(id -u --name "$PAM_USER")
fi

# send error emails. send_email [subject sufix] [body]
function send_email {
    echo "send_email: subject_sufix: '$1', body: '$2'"

    echo -e "\
From: ${USER_ID:-user-not-set}@$(hostname --fqdn)
To: $ERROR_EMAIL
Subject: $ERROR_SUBJECT $1\n
$2
\n$VAR_VALUES
" | sendmail $ERROR_EMAIL 2>&1
}

# logs an error to syslog. Sends an email if [mail?] is defined.
# logError [message] [mail?]
function logError {
    logger -p auth.err -t $TAG "$1"
    echo "Error: $1"
    if test -n "$2"; then
        send_email "$TAG error" "$1"
    fi
}

# logs an info to syslog
function logInfo {
    logger -p auth.info -t $TAG "$1"
    echo "Info: $1"
}

# check and wait for a connection to $LOGSESSION_HOST
function wait_net {
    local time_started=$SECONDS
    for i in {1..240}; do
        if ping -c1 -w5 -q $LOGSESSION_HOST &>/dev/null; then
            local time_took=$(( SECONDS - time_started ))
            logInfo "net online after ${time_took}s"
            return 0
        fi
        sleep 1 # ping may take only a few ms if we have no dns
    done

    local time_took=$(( SECONDS - time_started ))
    logError "Couldn't reach $LOGSESSION_HOST after ${time_took}s"
    return 1
}


# sends a request to logSession.php
# arguments: $1: type
function send_request {
    # ver logsession.php para documentacao dos parametros do POST
    local time_started=$SECONDS
    HTTP_CODE=$(curl --netrc-file "$NETRC_FILE"\
     --max-time 120\
     --write-out '%{http_code}' --silent\
     --form-string service="$PAM_SERVICE"\
     --form-string user="$USER_ID"\
     --form-string type="$1"\
     --form-string tty="$PAM_TTY"\
     --form-string session_id="$SESSION_ID"\
     --form-string os="$OS"\
     $LOGSESSION_URL -o "/dev/null")

    ret=$?
    local time_took=$(( SECONDS - time_started )) # number of seconds curl took to run
    if test $ret -eq 0; then
        if test $HTTP_CODE -ne "200"; then
            logError "request failed after ${time_took}s, http $HTTP_CODE, user=$USER_ID, pam_user=$PAM_USER, type=$1" mail
        else
            logInfo "request sent in ${time_took}s, http $HTTP_CODE, user=$USER_ID, pam_user=$PAM_USER, type=$1"
        fi
    else
        logError "curl failed after ${time_took}s with exit code $ret" mail
    fi
}

function get_sessionid() {
    # 2018-09: XDG_SESSION_ID started giving letters... using sessionid now
    # 2018-11: /proc/self/sessionid is the same for every session on ubuntu -.-
    #          convert XDG_SESSION_ID to a number 32 bit number. Let's also
    #          add the user ID to prevent problems like this in the future.
    local hash=$(sha1sum <<<"$XDG_SESSION_ID $USER_ID")
    # This needs to fit in a 32-bit INT in the database...
    # convert it to decimal using only the first 7 hex chars (28-bit).
    echo $((0x0${hash:0:7}))
}

############### some more complicated variables ###############

SESSION_ID=$(get_sessionid) # also depends on USER_ID
logInfo "derived SESSION_ID='$SESSION_ID' from XDG_SESSION_ID='$XDG_SESSION_ID' USER_ID='$USER_ID'"

# PAM_TTY may give '/dev/tty2' .. we want just 'tty2'
if [[ "$PAM_TTY" = *"/"* ]]; then
	PAM_TTY="$(basename "$PAM_TTY")"
fi

# used for error emails and for debugging
VAR_VALUES="$(
    echo "1='$1'";
    echo "service='$PAM_SERVICE'";
    echo "user='$USER_ID'";
    echo "pam_user='$PAM_USER'";
    echo "pam_type='$PAM_TYPE'";
    echo "tty='$PAM_TTY'";
    echo "session_id='$SESSION_ID'";
    echo "os='$OS'";
    echo "hostname='$(hostname)'";
)"

############### script starts here ###############

echo -n 'pwd: '
pwd

if test "$1" = "boot"; then
    logInfo "on boot"
    wait_net
    send_request "boot"
elif test "$1" = "shutdown"; then
    logInfo "on shutdown"
    send_request "shutdown"
elif test "$1" = "clean"; then
    logInfo "clean"
    send_request "clean"
else
    echo "$VAR_VALUES"

    # Ignore root logins via ssh
    if [ "$USER_ID" = "root" ] && [ "$PAM_SERVICE" = "sshd" ]; then
      exit 0
    fi

    case "$PAM_TYPE" in
        "open_session")
            test -n "$HOME" && ls "$HOME" &> /dev/null
            if test -z "$HOME" || test -d "$HOME"; then
                # 2018-11: send the request anyway if HOME is empty (happens on ttys on ubuntu -.-)
                send_request "login"
            else
                # HOME does not exist when AFS is not activated (and login will fail anyway)
                logError "ignoring login because HOME=$HOME does not exist"
            fi
            # For debugging. This is safe because we have a safe umask set.
            { echo $DATE; env; echo; } >> /tmp/.$TAG.$USER_ID.env
        ;;
        "close_session")
            send_request "logout"
        ;;
        *)
            send_request "$PAM_TYPE"
        ;;
    esac
fi

exit 0
# vim: set et:ts=4:sw=4:
