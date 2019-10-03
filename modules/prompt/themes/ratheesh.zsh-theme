#
# Ratheesh's theme based on minimal theme
# few git functions are copied from sorin's theme in prezto
#

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
function git_repo_status() {
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
        tag_at_current_commit="%F{8}(%b%{$italic%}%F{178}tag%{$reset%}%B%F{198}:%f%b%F{66}${tag_at_current_commit}%F{8})%f%b"
    fi

    if [[ -n $branch_name ]] && \
     branch=("%B%F{129}«%B%F{11}±%f%b%F{33}${branch_name}%F{142}%b${tag_at_current_commit:-""}%B%F{129}»%f%b")
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
    (( stashed )) && git_status+=("%F{7}${stashed}%B%F{63}S%f%b")

    (( ahead > 0 )) && git_status+=("%F{7}${ahead}%B%F{34}↑%f%b")
    (( behind > 0 )) && git_status+=("%F{7}${behind}%B%F{198}↓%f%b")
    (( untracked > 0 )) && git_status+=("%F{7}${untracked}%B%F{162}??%f")
    (( modified > 0 )) && git_status+=("%F{7}${modified}%B%F{202}*%f%b")
    (( added > 0 )) && git_status+=("%F{7}${added}%B%F{2}+%f%b")
    (( renamed > 0 )) && git_status+=("%F{7}${renamed}%B%F{54}➜%f%b")
    (( deleted > 0 )) && git_status+=("%F{7}${deleted}%B%F{1}x%f%b")

    print "$git_status"
}

function get_git_data() {
    local is_git="$(git rev-parse --is-inside-work-tree 2>/dev/null)"
    if [[ -n $is_git ]]; then
        local infos="$(git_repo_status)%f"
        print " $infos"
    fi
}

function python_info() {
    # Clean up previous $python_info.
    unset _python_info
    typeset -gA _python_info

    local v_env=''

    if (( ! $+commands[python] )); then
        print ''
        return 1
    fi

    # print only if virtualenv is active
    if [[ -n "$VIRTUAL_ENV" ]]; then
        v_env=$(basename ${VIRTUAL_ENV})
        _python_info=" %F{8}(%{$italic%}%F{5}venv%{$reset%}%B%F{33}:%b%F{179}${v_env}%F{8})%f%b"
    else
        _python_info=''
    fi
}

function prompt_ratheesh_signal() {
    _prompt_git_info="$(cat $_prompt_async_data_file 2>/dev/null)"
    zle && zle reset-prompt # Redisplay prompt.
    _prompt_ratheesh_async_pid=0
}

function prompt_ratheesh_precmd() {

    function async_thread() {
        printf "%s" "$(get_git_data)" >! "$_prompt_async_data_file"
        kill -WINCH $$
    }

    # Get python virtualenv info
    python_info

    [[ "${_prompt_ratheesh_async_pid}" > 0 ]] && return

    _prompt_git_info=''
    # Handle updating git data. We also clear the git prompt data if we're in a
    # different git root now.
    if (( $+functions[git-dir] )); then
        local new_git_root="$(git-dir 2> /dev/null)"
        if [[ $new_git_root = '' ]];then
            [[ -a $_prompt_async_data_file ]] && rm -f $_prompt_async_data_file &> /dev/null
            return
        else
            [[ $new_git_root != $_ratheesh_cur_git_root ]] && _ratheesh_cur_git_root=$new_git_root
        fi
    fi

    # Compute slow commands in the background.
    trap prompt_ratheesh_signal WINCH
    async_thread &!
    _prompt_ratheesh_async_pid=$!
}

function prompt_ratheesh_zshexit() {
    # remove prompt data to avoid littering
    [[ -a $_prompt_async_data_file ]] && rm -f $_prompt_async_data_file &> /dev/null
}

function prompt_ratheesh_setup() {
    setopt LOCAL_OPTIONS
    unsetopt XTRACE KSH_ARRAYS

    autoload -Uz add-zsh-hook
    # autoload -Uz async && async
    prompt_opts=(cr percent sp subst)

    # Get the async worker set up
    _ratheesh_cur_git_root=''
    _prompt_git_info=''

    _prompt_ratheesh_async_pid=0
    _prompt_async_data_file="/run/user/${UID}/zsh_prompt_data.$$"

    add-zsh-hook precmd prompt_ratheesh_precmd
    add-zsh-hook zshexit prompt_ratheesh_zshexit

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
    PROMPT='%{$terminfo_down_sc$italic$vimode$reset$terminfo[rc]%}\
${SSH_TTY:+"%F{8}⌠%b%f%{$italic%}%F{102}%n%b%{$reset%}%F{60}@%F{131}%m%F{8}⌡%B%F{162}~%f%b"}\
%F{8}⌠%f%b%F{60}${${${(%):-%30<...<%2~%<<}//\//%B%F{25\}/%b%{$italic%\}%F{173\}}//\~/⌂}%b%{$reset%}%F{8}⌡%f%b\
%(!. %B%F{1}#%f%b.)%(1j.%F{8}-%F{93}%j%F{8}-%f.)${editor_info[keymap]}%{$reset_color%} '

    # RPROMPT=''
    # RPROMPT='%(?:%B%F{40}⏎%f%b:%B%F{9}⏎%f%b)$(get_python_info)'
    RPROMPT='%(?::%B%F{9}⏎%f%b)${_python_info}${_prompt_git_info}'
    SPROMPT='zsh: Correct %F{1}%R%f to %F{27}%r%f ?([Y]es/[N]o/[E]dit/[A]bort)'
}

# Clear to the end of the line before execution
function preexec () { print -rn -- $terminfo[el]; }

prompt_ratheesh_preview () {
  if (( ${#} )); then
    prompt_preview_theme ratheesh "${@}"
  else
    prompt_preview_theme ratheesh
    print
    prompt_preview_theme eriner black blue green yellow
  fi
}

prompt_ratheesh_setup "${@}"

# End of File
