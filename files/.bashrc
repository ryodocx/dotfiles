#!/usr/bin/env bash
################################################################################
# asdf
ASDFINSTALLS=~/.asdf/installs
. ~/.asdf/asdf.sh
. ~/.asdf/completions/asdf.bash
################################################################################
# Prompt
PS1="\W \$ "
function _prompte_command() {
    history -a
    echo $(pwd) >> ~/.cd_history
}
PROMPT_COMMAND="_prompte_command"
################################################################################
# History
export HISTSIZE=5000
export HISTTIMEFORMAT='%F %T '
################################################################################
# Bash Completion
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion # mac
[ -f /etc/bash_completion ] && . /etc/bash_completion                     # linux
for f in ~/.bash_completion_local/*; do
    . $f
done

# terraform
complete -C terraform terraform
# kubectl
. <(kubectl completion bash)

# aws
# complete -C aws_completer aws
# # gcloud # TODO
# source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/completion.bash.inc
# source /usr/local/Caskroom/google-cloud-sdk/latest/google-cloud-sdk/path.bash.inc
# az #TODO

# go
_go_completion() {
    cur="${COMP_WORDS[COMP_CWORD]}"
    case "${COMP_WORDS[COMP_CWORD - 1]}" in
    "go")
        comms="bug build clean doc env fix fmt generate get install list mod run test tool version vet"
        COMPREPLY=($(compgen -W "${comms}" -- ${cur}))
        ;;
    *)
        files=$(find ${PWD} -mindepth 1 -maxdepth 1 -type f -iname "*.go" -exec basename {} \;)
        dirs=$(find ${PWD} -mindepth 1 -maxdepth 1 -type d -not -name ".*" -exec basename {} \;)
        repl="${files} ${dirs}"
        COMPREPLY=($(compgen -W "${repl}" -- ${cur}))
        ;;
    esac
    return 0
}
complete -F _go_completion go
################################################################################
# env
export PATH=$PATH:~/.bin
# export EDITOR=code # VSCode
# Go
export GOROOT=${ASDFINSTALLS}/golang/1.12/go
export GOPATH=~/go
export GO111MODULE=on
export PATH=$PATH:${GOPATH}/bin
# gcloud
export CLOUDSDK_PYTHON=${ASDFINSTALLS}/python/2.7.15/bin/python
# krew: Package manager for "kubectl plugins" https://krew.dev
export PATH=$PATH:~/.krew/bin
################################################################################
# direnv
eval "$(direnv hook bash)"
################################################################################
# alias
alias relogin='exec $SHELL -l'
################################################################################
# peco

# cd
function peco-cd() {
    local filtered=$(find . -type d -name '.git' -prune -o -type d 2>/dev/null | grep -vE "^\.$" | peco)
    if [ -n "${filtered}" ]; then
        cd ${filtered}
    fi
}

# cd-history
function peco-cd-history() {
    local filtered=$(cat ~/.cd_history | sort | uniq | peco)
    if [ -n "${filtered}" ]; then
        cd ${filtered}
    fi
}

# history
function peco-history() {
    local NUM=$(history | wc -l)
    local FIRST=$((-1 * (NUM - 1)))
    if [ $FIRST -eq 0 ]; then
        history -d $((HISTCMD - 1))
        echo "No history" >&2
        return
    fi
    local CMD=$(fc -l $FIRST | sort -k 2 -k 1nr | uniq -f 1 | sort -nr | sed -E 's/^[0-9]+[[:blank:]]+//' | peco | head -n 1)
    if [ -n "$CMD" ]; then
        history -s $CMD
        if type osascript >/dev/null 2>&1; then
            (osascript -e 'tell application "System Events" to keystroke (ASCII character 30)' &)
        fi
    else
        history -d $((HISTCMD - 1))
    fi
}
bind -x '"\C-r": peco-history'

# ghq
function peco-ghq() {
    local filtered=$(ghq list --full-path | peco)
    if [ -n "${filtered}" ]; then
        cd ${filtered}
    fi
}
bind -x '"\C-g": peco-ghq'

# git-log
function peco-gitlog() {
    local filtered=$(git log --no-merges --date=short --pretty='format:%h %cd %an%d %s' | peco | cut -d" " -f1)
    if [ -n "${filtered}" ]; then
        git show ${filtered}
    fi
}

# peco's commands
function peco-peco() {
    local filtered=$(compgen -c | grep -E '^peco-.+$' | grep -vE '^peco-peco$' | peco)
    if [ -n "${filtered}" ]; then
        eval ${filtered}
    fi
}
bind -x '"\C-n": peco-peco'
################################################################################
