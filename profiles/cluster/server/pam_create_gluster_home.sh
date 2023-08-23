#!/bin/bash
CLUSTER_BASE_HOME=/mnt/cirrus
USERS_FOLDER=$CLUSTER_BASE_HOME/users
script_name=pam_create_gluster_home

# either open_session or close_session
action=$PAM_TYPE

# users can login using "name.lastname" or something instead of istxxxxxx
# "id -i --name" gives the istxxxxxx
user=$(id -u --name "$PAM_USER")
group=$(id -g --name "$user")

DEBUG=yes

error() {
  # -s: also sends the msg to stderr
  logger -t $script_name -s -p user.err -- "$@"
}

debug() {
  if [ "$DEBUG" = "yes" ]; then
    echo "$(date +'%F %T'): $@" >&2
  fi
}

gen_glusterhome() {
  # Format: /mnt/cirrus/users/Y/Z/istxxxxyz
  Y="$(echo "$user" | rev | cut -c 2)"
  Z="$(echo "$user" | rev | cut -c 1)"
  echo -n "$USERS_FOLDER/$Y/$Z/$user"
}

if test $EUID -ne 0; then
  error "must be run as root (euid=$EUID)"
  exit 0
fi

# When someone with an IST ID has logged in, try creating their gluster home
if [ "$action" = "open_session" ] && [[ "$user" =~ ^ist[0-9]+$ ]]; then
  if ! test -w "$CLUSTER_BASE_HOME"; then
    error "can not write to $CLUSTER_BASE_HOME. Is it mounted?"
    exit 0 # 0 so pam does not fail
  fi

  if ! test -e "$USERS_FOLDER"; then
    error "users folder ($USERS_FOLDER) does not exist. Is it mounted?"
    exit 0 # 0 so pam does not fail
  fi

  glusterhome="$(gen_glusterhome)"

  # Only create/set permissions for $glusterhome when it doesn't already exist
  if ! test -d "$glusterhome"; then
    debug "Creating gluster home ($glusterhome) for user $user"
    if mkdir -p $glusterhome; then
      chown $user:$group $glusterhome || error "chown failed for $user:$group $glusterhome"
      chmod 0770 $glusterhome || error "chmod failed for $glusterhome"
    else
      error "could not create gluster home for '$user' in '$glusterhome'"
    fi
  fi
else
  debug "User $user is not entitled to a gluster home or is logging out"
fi

debug "End"
exit 0
