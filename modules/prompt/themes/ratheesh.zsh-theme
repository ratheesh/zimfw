#!/usr/bin/env zsh
#  vim: set ft=zsh ff=unix ts=8 sw=4 tw=0 expandtab:
#
# My custom theme based on minimal theme
# Few git functions are copied from sorin's theme in prezto
#
# async theme without zpty is refered from
# https://github.com/woefe/git-prompt.zsh

# Gets the Git special action (am, bisect, cherry, merge, rebase).
# Borrowed from vcs_info and edited.
function _git-action {
    local git_dir=$(git-dir)
    local action_dir
    for action_dir in \
        "${git_dir}/rebase-apply" \
            "${git_dir}/rebase" \
            "${git_dir}/../.dotest"
    do
        if [[ -d ${action_dir} ]]; then
            local apply_formatted
            local rebase_formatted
            apply_formatted='apply'
            rebase_formatted='>R>rebase'

            if [[ -f "${action_dir}/rebasing" ]]; then
                print ${rebase_formatted}
            elif [[ -f "${action_dir}/applying" ]]; then
                print ${apply_formatted}
            else
                print "${rebase_formatted}/${apply_formatted}"
            fi

            return 0
        fi
    done

    for action_dir in \
        "${git_dir}/rebase-merge/interactive" \
            "${git_dir}/.dotest-merge/interactive"
    do
        if [[ -f ${action_dir} ]]; then
            local rebase_interactive_formatted
            rebase_interactive_formatted='rebase-interactive'
            print ${rebase_interactive_formatted}
            return 0
        fi
    done

    for action_dir in \
        "${git_dir}/rebase-merge" \
            "${git_dir}/.dotest-merge"
    do
        if [[ -d ${action_dir} ]]; then
            local rebase_merge_formatted
            rebase_merge_formatted='rebase-merge'
            print ${rebase_merge_formatted}
            return 0
        fi
    done

    if [[ -f "${git_dir}/MERGE_HEAD" ]]; then
        local merge_formatted
        merge_formatted='>M<merge'
        print ${merge_formatted}
        return 0
    fi

    if [[ -f "${git_dir}/CHERRY_PICK_HEAD" ]]; then
        if [[ -d "${git_dir}/sequencer" ]]; then
            local cherry_pick_sequence_formatted
            cherry_pick_sequence_formatted='cherry-pick-sequence'
            print ${cherry_pick_sequence_formatted}
        else
            local cherry_pick_formatted
            cherry_pick_formatted='cherry-pick'
            print ${cherry_pick_formatted}
        fi

        return 0
    fi

    if [[ -f "${git_dir}/BISECT_LOG" ]]; then
        local bisect_formatted
        bisect_formatted='<B>bisect'
        print ${bisect_formatted}
        return 0
    fi

    return 1
}

# Prints the first non-empty string in the arguments array.
function coalesce {
    for arg in $argv; do
        print "$arg"
        return 0
    done
    return 1
}

function git_branch_name() {
    local branch_name="$(command git rev-parse --abbrev-ref HEAD 2> /dev/null)"
    [[ -n $branch_name ]] && print "$branch_name"
}

# useful symbols            ✔
function git_info() {
    local ahead=0 behind=0 untracked=0 modified=0 deleted=0 added=0 dirty=0
    local branch
    local pos position commit
    local ahead_and_behind_cmd ahead_and_behind
    local -a git_status
    local is_on_a_tag=false
    local current_commit_hash="$(git rev-parse HEAD 2> /dev/null)"
    local branch_name="${$(git symbolic-ref HEAD 2> /dev/null)#refs/heads/}"
    #  ±

    # check if the current commit is at a tag point
    local tag_at_current_commit=$(git describe --exact-match --tags $current_commit_hash 2> /dev/null)
    if [[ -n $tag_at_current_commit ]]; then
        tag_at_current_commit="%F{60}(%b%{$italic%}%F{178}tag%{$reset%}%B%F{198}:%f%b%F{66}${tag_at_current_commit}%F{60})%f%b"
    fi

    if [[ -n $branch_name ]] && \
     branch=("%B%F{129}«%B%F{11}±%f%b%{$italic%}%F{33}${branch_name}%F{142}%b${tag_at_current_commit:-""}%B%F{129}»%f%b")
    if [[ -z "${branch_name//}" ]]; then
        pos="$(git describe --contains --all HEAD 2> /dev/null)"
        position="%B%F{8}ǁ%b%F{196}%F{7}${pos}%B%F{8}ǁ%f%b"
    fi

    [[ -z "${branch_name//}" && -z "${pos//}" ]] && commit="%B%F{8}ǁ%F{196}%F{7}${current_commit_hash}%B%F{8}ǁ%f%b"

    ahead_and_behind_cmd='git rev-list --count --left-right HEAD...@{upstream}'
    # Get ahead and behind counts.
    ahead_and_behind="$(${(z)ahead_and_behind_cmd} 2> /dev/null)"
    ahead="$ahead_and_behind[(w)1]"
    behind="$ahead_and_behind[(w)2]"

    # Use porcelain status for easy parsing.
    status_cmd="git status --porcelain --ignore-submodules=all"

    # Get current status.
    while IFS=$'\n' read line; do
        # Count added, deleted, modified, renamed, unmerged, untracked, dirty.
        # T (type change) is undocumented, see http://git.io/FnpMGw.
        # For a table of scenarii, see http://i.imgur.com/2YLu1.png.
        [[ "$line" == ([ACDMT][\ MT]|[ACMT]D)\ * ]] && (( added++ ))
        [[ "$line" == [\ ACMRT]D\ * ]] && (( deleted++ ))
        [[ "$line" == ?[MT]\ * ]] && (( modified++ ))
        [[ "$line" == R?\ * ]] && (( renamed++ ))
        [[ "$line" == (AA|DD|U?|?U)\ * ]] && (( unmerged++ ))
        [[ "$line" == \?\?\ * ]] && (( untracked++ ))
        (( dirty++ ))
    done < <(${(z)status_cmd} 2> /dev/null)

    (( dirty > 0 )) && git_status+=("%B%F{9}✘%f%b") || git_status+=("%B%F{27}✔%f%b")

    git_status+=($(_git-action))

    # if [[ -n $branch ]] && git_status+=(${branch})
    git_status+=($(coalesce $branch $position $commit))

    local -i stashed=$(command git stash list 2>/dev/null | wc -l)
    (( stashed > 0 )) && git_status+=("%F{7}${stashed}%B%F{63}S%f%b")

    (( ahead > 0 )) && git_status+=("%F{7}${ahead}%B%F{34}↑%f%b")
    (( behind > 0 )) && git_status+=("%F{7}${behind}%B%F{198}↓%f%b")
    (( added > 0 )) && git_status+=("%F{7}${added}%B%F{2}+%f%b")
    (( deleted > 0 )) && git_status+=("%F{7}${deleted}%B%F{1}x%f%b")
    (( modified > 0 )) && git_status+=("%F{7}${modified}%F{202}✱%f%b")
    (( renamed > 0 )) && git_status+=("%F{7}${renamed}%B%F{54}➜%f%b")
    (( unmerged > 0 )) && git_status+=("%F{7}${unmerged}%B%F{1}U%f%b")
    (( untracked > 0 )) && git_status+=("%F{7}${untracked}%B%F{162}??%f")

    print "$git_status"
}

function get_git_data() {
    local is_git="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
    if [[ -n $is_git ]]; then
        local infos="$(git_info)%f"
        print " $infos"
    fi
}

function python_info() {
    # Clean up previous $python_info.
    unset python_info
    typeset -gA python_info
    local v_env=''

    if (( ! $+commands[python] )); then
        print ''
        return 1
    fi

    # print only if virtualenv is active
    if [[ -n "$VIRTUAL_ENV" ]]; then
        v_env=$(basename ${VIRTUAL_ENV})
        python_info=" %F{8}(%{$italic%}%F{5}venv%{$reset%}%B%F{33}:%b%F{179}${v_env}%F{8})%f%b"
    else
        python_info=''
    fi
}

function _zsh_git_prompt_async_request() {
    typeset -g _ZSH_GIT_PROMPT_ASYNC_FD _ZSH_GIT_PROMPT_ASYNC_PID

    # If we've got a pending request, cancel it
    if [[ -n "$_ZSH_GIT_PROMPT_ASYNC_FD" ]] && { true <&$_ZSH_GIT_PROMPT_ASYNC_FD } 2>/dev/null; then

        # Close the file descriptor and remove the handler
        exec {_ZSH_GIT_PROMPT_ASYNC_FD}<&-
        zle -F $_ZSH_GIT_PROMPT_ASYNC_FD

        # Zsh will make a new process group for the child process only if job
        # control is enabled (MONITOR option)
        if [[ -o MONITOR ]]; then
            # Send the signal to the process group to kill any processes that may
            # have been forked by the suggestion strategy
            kill -TERM -$_ZSH_GIT_PROMPT_ASYNC_PID 2>/dev/null
        else
            # Kill just the child process since it wasn't placed in a new process
            # group. If the suggestion strategy forked any child processes they may
            # be orphaned and left behind.
            kill -TERM $_ZSH_GIT_PROMPT_ASYNC_PID 2>/dev/null
        fi
    fi

    # Fork a process to fetch the git status and open a pipe to read from it
    exec {_ZSH_GIT_PROMPT_ASYNC_FD}< <(
        # Tell parent process our pid
        echo $sysparams[pid]
        get_git_data
    )

    # There's a weird bug here where ^C stops working unless we force a fork
    # See https://github.com/zsh-users/zsh-autosuggestions/issues/364
    command true

    # Read the pid from the child process
    read _ZSH_GIT_PROMPT_ASYNC_PID <&$_ZSH_GIT_PROMPT_ASYNC_FD

    # When the fd is readable, call the response handler
    zle -F "$_ZSH_GIT_PROMPT_ASYNC_FD" _zsh_git_prompt_callback
}

# Called when new data is ready to be read from the pipe
# First arg will be fd ready for reading
# Second arg will be passed in case of error
function _zsh_git_prompt_callback() {
    emulate -L zsh

    if [[ -z "$2" || "$2" == "hup" ]]; then
        # Read output from fd
        prompt_info="$(cat <&$1)"

        zle reset-prompt
        zle -R

        # Close the fd
        exec {1}<&-
    fi

    # Always remove the handler
    zle -F "$1"

    # Unset global FD variable to prevent closing user created FDs in the precmd hook
    unset _ZSH_GIT_PROMPT_ASYNC_FD
}

function prompt_ratheesh_precmd() {
    setopt noxtrace noksharrays localoptions

    # Get python virtualenv info
    python_info

    _prompt_cur_pwd=$PWD

    if (( $+functions[git-dir] )); then
        local new_git_root="$(git-dir 2> /dev/null)"
        if [[ $new_git_root != $_ratheesh_cur_git_root ]];then
            prompt_info=''
            _ratheesh_cur_git_root=$new_git_root
        fi
    fi

    _zsh_git_prompt_async_request

}

function prompt_ratheesh_zshexit() {
}

function prompt_ratheesh_setup() {
    setopt localoptions noxtrace noksharrays

    zmodload zsh/system

    autoload -Uz add-zsh-hook
    # autoload -Uz async && async
    autoload -Uz +X add-zle-hook-widget 2>/dev/null

    prompt_opts=(cr percent sp subst)

    # Get the async worker set up
    _ratheesh_cur_git_root=''
    _prompt_cur_pwd=''
    prompt_info=''

    trap prompt_ratheesh_zshexit TERM
    trap prompt_ratheesh_zshexit INT
    trap prompt_ratheesh_zshexit KILL
    add-zsh-hook zshexit prompt_ratheesh_zshexit

    # Notify if git package is not installed in the system
    if (( ! $+commands[git] )); then
        prompt_info='%B%F{9}Git not installed!%f%b'
    else
        add-zsh-hook precmd prompt_ratheesh_precmd
    fi

    # Set editor-info parameters.
    zstyle ':zim:input:info:completing' format '%B%F{9}∙∙∙∙∙%f%b'
    zstyle ':zim:input:info:keymap:primary' format '%B%F{125}❯%F{65}❯%F{132}❯%f%b'
    zstyle ':zim:input:info:keymap:primary:overwrite' format ' %F{3}♺%f'
    zstyle ':zim:input:info:keymap:alternate' format '%B%F{125}❮%F{65}❮%F{132}❮%f%b'

    # ⎩⎫ ⎧⎭➜ ❯
    if (( $+commands[tput] ));then
        bold=$(tput bold)
        italic=$(tput sitm)
        reset=$(tput sgr0)
    else
        bold=''
        italic=''
        reset=''
    fi
    terminfo_down_sc=$terminfo[cud1]$terminfo[cuu1]$terminfo[sc]$terminfo[cud1]
    PROMPT='%{$terminfo_down_sc${editor_info[mode]}$reset$terminfo[rc]%}\
${SSH_TTY:+"%F{60}⌠%f%{$italic%}%F{102}%n%{$reset%}%F{60}@%F{131}%m%F{60}⌡%B%F{162}~%f%b"}\
%F{60}⌠%F{67}${${${(%):-%30<...<%2~%<<}//\//%B%F{93\}/%b%{$italic%\}%F{173\}}//\~/%B⌂%b}%b%{$reset%}%F{60}⌡%f%b\
%(!. %B%F{1}#%f%b.)%(1j.%F{8}-%F{93}%j%F{8}-%f.)${editor_info[keymap]}%{$reset_color%} '

    # RPROMPT=''
    # RPROMPT='%(?:%B%F{40}⏎%f%b:%B%F{9}⏎%f%b)$(get_python_info)'
    RPROMPT='%(?::%B%F{9}⏎%f%b)${python_info}${prompt_info}'
    SPROMPT='zsh: Correct %F{1}%R%f to %F{27}%r%f ?([Y]es/[N]o/[E]dit/[A]bort)'
}

# Clear to the end of the line before execution
function preexec () { print -rn -- $terminfo[el]; }

prompt_ratheesh_preview () {
  if (( ${#} )); then
    prompt_preview_theme ratheesh "${@}"
  else
    prompt_info=''
    prompt_preview_theme ratheesh
    print
    prompt_preview_theme eriner black blue green yellow
  fi
}

prompt_ratheesh_setup "${@}"

# End of File
