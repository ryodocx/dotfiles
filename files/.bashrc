#!/usr/bin/env bash
################################################################################
# asdf
. ~/.asdf/asdf.sh
. ~/.asdf/completions/asdf.bash
################################################################################
# Prompt
PS1='\[\e[0;32m\]$(date "+%Y/%m/%d %H:%M:%S") \u@\h \w\[\e[m\]\n\$ '

function _prompte_command() {
    exitCode="$?"
    if [ ! $exitCode = 0 ]; then
        echo -e "\e[1;31m[ExitCode=$exitCode]\e[m" >&2
    fi
    history -a
    echo $(pwd) >>~/.cd_history
}
PROMPT_COMMAND="_prompte_command"
################################################################################
# History
unset HISTCONTROL
export HISTSIZE=5000
export HISTTIMEFORMAT='%F %T '
(
    list=$(cat ~/.cd_history | awk '!a[$0]++')
    echo "${list}" >~/.cd_history
) &
################################################################################
# Bash Completion
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion # mac
[ -f /usr/share/bash-completion/bash_completion ] && . /usr/share/bash-completion/bash_completion
[ -f /etc/bash_completion ] && . /etc/bash_completion # linux
for script in ~/.bash_completion_local/*; do
    . $script
done
for script in /etc/profile.d/*.sh; do
    if [ -f $script ]; then
        . $script
    fi
done

# # gcloud # TODO
# source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc
# source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc
# source az.completion.sh
################################################################################
# direnv
if type direnv &>/dev/null; then
    eval "$(direnv hook bash)"
fi
################################################################################
# alias
alias ll='ls -n'
alias relogin='exec $SHELL -l'
################################################################################
# peco

# cd
function peco-cd() {
    local filtered=$(find . -type d -name '.git' -prune -o -type d 2>/dev/null | grep -vE "^\.$" | peco --query "${READLINE_LINE}" | head -n 1)
    if [ -n "${filtered}" ]; then
        READLINE_LINE="cd ${filtered## }"
        READLINE_POINT=$((3 + ${#filtered}))
    fi
}
bind -x '"\C- ": peco-cd'

# cd-history
function peco-cd-history() {
    local filtered=$(cat ~/.cd_history | reverse | awk '!a[$0]++' | peco --query "${READLINE_LINE}" | head -n 1)
    if [ -n "${filtered}" ]; then
        READLINE_LINE="cd ${filtered## }"
        READLINE_POINT=$((3 + ${#filtered}))
    fi
}

# history
function peco-history() {
    local cmd=$(HISTTIMEFORMAT= history | awk '{$1="";print}' | reverse | awk '!a[$0]++' | peco --query "${READLINE_LINE}" | head -n 1)
    READLINE_LINE="${cmd## }"
    READLINE_POINT=${#cmd}
}
bind -x '"\C-r": peco-history'

# ghq
function peco-ghq() {
    local filtered=$(ghq list --full-path | peco --query "${READLINE_LINE}" | head -n 1)
    if [ -n "${filtered}" ]; then
        READLINE_LINE="cd ${filtered## }"
        READLINE_POINT=$((3 + ${#filtered}))
    fi
}
bind -x '"\C-g": peco-ghq'

# git-log
function peco-gitlog() {
    local filtered=$(git log --no-merges --date=short --pretty='format:%h %cd %an%d %s' | peco --query "${READLINE_LINE}" | head -n 1 | cut -d" " -f1)
    if [ -n "${filtered}" ]; then
        git show ${filtered}
    fi
}

# peco's commands
function peco-peco() {
    local filtered=$(compgen -c | grep -E '^peco-.+$' | grep -vE '^peco-peco$' | peco --query "${READLINE_LINE}" | head -n 1)
    if [ -n "${filtered}" ]; then
        eval ${filtered}
    fi
}
bind -x '"\C-n": peco-peco'
################################################################################
wait
################################################################################
