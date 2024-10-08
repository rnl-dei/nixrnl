#!/usr/bin/env bash

url="$1"
repo_path="$2"
email_dest="$3"
hook_script="$4"

pull_hook="${repo_path}/.pull_hooks.sh"
hooks_file=${hook_script:-$pull_hook}
email_dest="${email_dest:-root}"

email_subject="[git-hook] ${HOSTNAME}:${repo_path}"

function try_hook_warning() {
    type hook_warning >/dev/null && hook_warning "$1\n$2"
}

function log_info() {
    logger -t git-web-hook-script -p daemon.info "$1"
}

function email() {
    echo -e "Subject:${email_subject} - $1\n\n$1\n$2\n$3\n$4\n" | sendmail "$email_dest"
}

# $1 -> Outputs to log, email subject and email body
# $2 -> Only outputs to email body
function error() {
    logger -t git-web-hook-script -p daemon.notice "$1"
    email "$@"
    try_hook_warning "$@"
}

function modified_repo() {
    git status | grep "modified:" >/dev/null
}

function diverged_repo() {
    git status | grep "have diverged" >/dev/null
}

function ahead_repo() {
    git status | grep "Your branch is ahead" >/dev/null
}

function detached_head_at() {
    git status | grep "HEAD detached at" >/dev/null
}

function detached_head_from() {
    git status | grep "HEAD detached from" >/dev/null
}

function updated_pull() {
    echo "$1" | grep "Updating" >/dev/null
}

function get_head() {
    git rev-parse HEAD
}

##### Initial checks #####

if [[ ! -d ${repo_path} ]]; then
    error "Directory '${repo_path}' not found."
    exit 1
fi

cd "$repo_path" || exit 1

##### Clone repository if directory is empty #####
if [[ -z $(ls -A) ]]; then
    if ! git clone "$url" .; then
        error "Error cloning repository."
        exit 1
    fi
fi

use_hook=false
if [[ -f ${hooks_file} ]]; then
    log_info "source $(realpath "${hooks_file}")"

    # shellcheck disable=SC1090
    if source "${hooks_file}"; then
        use_hook=true
    else
        error "Error sourcing hooks_file ${hooks_file}"
    fi
fi

if [[ $use_hook == true ]]; then
    # hook_pre_pull cannot be run inside a subshell so that variables defined in the function hook
    # can be accessed in the post_pull function hook
    if ! hook_pre_pull; then
        hook_output=$(hook_pre_pull)
        error "Error in hook_pre_pull(). Not updating repository." \
            "\nhook_pre_pull() output in ${hooks_file}:\n${hook_output}"
        exit 1
    fi
fi

if modified_repo; then
    error "The repository has modified files, someone dun goofed. Not fetching repository." \
        "Run 'git checkout .' in the repo to fix this. Will erase the local changes!" \
        "\n'git status' output:\n$(git status)"
    exit 1
fi

last_good_commit=$(get_head)

##### git fetch #####

fetch_output=$(git fetch 2>&1)

# shellcheck disable=SC2181
if [[ $? != 0 ]]; then
    error "Error while fetching the repository. Maybe the URL has changed?" \
        "\n'git fetch' output:\n${fetch_output}"
    exit 1
fi

if diverged_repo || ahead_repo; then
    error "The repository has local commits, someone dun goofed. Not pulling repository." \
        "Run 'git reset --hard origin/master' in the repo to fix this. Will erase the local commits!\n\n'git status' output:\n$(git status)"
    exit 1
fi

##### git pull #####

if detached_head_at; then
    log_info "Repository HEAD was detached, checking out 'master' before pulling."
    git checkout master &>/dev/null
fi

log_info "git pull on $repo_path"
pull_output=$(git pull 2>&1)

# shellcheck disable=SC2181
if [[ $? != 0 ]]; then
    error "Error while pulling the repository." \
        "\n'git pull' output:\n${pull_output}"
    exit 1
fi

if [[ $use_hook == true ]]; then

    hook_output=$(hook_post_pull)

    # shellcheck disable=SC2181
    if [[ $? != 0 ]]; then

        # Hook failed, revert to previous commit

        git checkout "$last_good_commit" &>/dev/null

        # Only warn if there was new changes in the pull

        if updated_pull "$pull_output"; then
            error "Error in hook_post_pull(), reverting to previous commit." \
                "Previous commit is ($last_good_commit). Commit again to fix this." \
                "\nhook_post_pull() output in ${hooks_file}:\n${hook_output}"
        fi

        # Run hook again to restart services or whatever after reverting the commit

        hook_output=$(hook_post_pull)

        # shellcheck disable=SC2181
        if [[ $? != 0 ]]; then
            error "WTF, error in hook_post_pull() after reverting to previous supposedly good commit." \
                "Previous supposedly good commit is ${last_good_commit}. Commit again to fix this or check manually what has happened." \
                "\nhook_post_pull() output in ${hooks_file}:\n${hook_output}"
        fi

    fi
fi
