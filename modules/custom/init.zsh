#
# Custom aliases/settings
#

# any custom stuff should go here.
# ensure that 'custom' exists in the zmodules array in your .zimrc

#
# Defines general aliases and functions.
#
# Authors:
#   Robby Russell <robby@planetargon.com>
#   Suraj N. Kurapati <sunaku@gmail.com>
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#


# Correct commands.
setopt CORRECT

#
# Aliases
#

# Disable correction.
alias ack='nocorrect ack'
alias cd='nocorrect cd'
alias cp='nocorrect cp'
alias ebuild='nocorrect ebuild'
alias gcc='nocorrect gcc'
alias gist='nocorrect gist'
alias grep='nocorrect grep --color=always -n'
alias heroku='nocorrect heroku'
alias ln='nocorrect ln'
# alias man='nocorrect man'
alias mkdir='nocorrect mkdir'
alias mv='nocorrect mv'
# alias mysql='nocorrect mysql'
alias rm='nocorrect rm'

# Disable globbing.
alias bower='noglob bower'
alias fc='noglob fc'
alias find='noglob find'
alias ftp='noglob ftp'
alias history='noglob history'
alias locate='noglob locate'
alias rake='noglob rake'
alias rsync='noglob rsync'
alias scp='noglob scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null'
alias sftp='noglob sftp'

# Define general aliases.
alias _='sudo'
alias b='${(z)BROWSER}'
# alias cp="${aliases[cp]:-cp} -i"
alias e='${(z)VISUAL:-${(z)EDITOR}}'
alias ln="${aliases[ln]:-ln} -i"
alias mkdir="${aliases[mkdir]:-mkdir} -p"
alias mv="${aliases[mv]:-mv} -i"
alias p='${(z)PAGER}'
alias po='popd'
alias pu='pushd'
alias rm="${aliases[rm]:-rm} -i"
alias type='type -a'

# ls
if is-callable 'dircolors'; then
    # GNU Core Utilities
    alias ls='ls --group-directories-first'
    if [[ -s "$HOME/.dir_colors" ]];then
        eval "$(dircolors --sh "$HOME/.dir_colors")"
    else
        eval "$(dircolors --sh)"
    fi
    alias ls="${aliases[ls]:-ls} --color=auto"
else
    # Define colors for BSD ls.
    export LSCOLORS='exfxcxdxbxGxDxabagacad'

    # Define colors for the completion system.
    export LS_COLORS='di=34:ln=35:so=32:pi=33:ex=31:bd=36;01:cd=33;01:su=31;40;07:sg=36;40;07:tw=32;40;07:ow=33;40;07:'

    alias ls="${aliases[ls]:-ls} -G"
fi
alias l='ls -1A'         # Lists in one column, hidden files.
alias ll='ls -lh'        # Lists human readable sizes.
alias lr='ll -R'         # Lists human readable sizes, recursively.
alias la='ll -A'         # Lists human readable sizes, hidden files.
alias lm='la | "$PAGER"' # Lists human readable sizes, hidden files through pager.
alias lx='ll -XB'        # Lists sorted by extension (GNU only).
alias lk='ll -Sr'        # Lists sorted by size, largest last.
alias lt='ll -tr'        # Lists sorted by date, most recent last.
alias lc='lt -c'         # Lists sorted by date, most recent last, shows change time.
alias lu='lt -u'         # Lists sorted by date, most recent last, shows access time.
alias sl='ls'            # I often screw this up.

# Mac OS X Everywhere
if [[ "$OSTYPE" == darwin* ]]; then
  alias o='open'
elif [[ "$OSTYPE" == cygwin* ]]; then
  alias o='cygstart'
  alias -g pbcopy='tee > /dev/clipboard'
  alias -g pbpaste='cat /dev/clipboard'
else
  alias o='xdg-open'

  if (( $+commands[xclip] )); then
    alias pbcopy='xclip -selection clipboard -in'
    alias pbpaste='xclip -selection clipboard -out'
  elif (( $+commands[xsel] )); then
    alias pbcopy='xsel --clipboard --input'
    alias pbpaste='xsel --clipboard --output'
  fi
fi

# alias pbc='pbcopy'
# alias pbp='pbpaste'

# File Download
if (( $+commands[curl] )); then
  alias get='curl --continue-at - --location --progress-bar --remote-name --remote-time'
elif (( $+commands[wget] )); then
  alias get='wget --continue --progress=bar --timestamping'
fi

# Resource Usage
alias df='df -kh'
alias du='du -kh'

if (( $+commands[htop] )); then
  alias top=htop
else
  if [[ "$OSTYPE" == (darwin*|*bsd*) ]]; then
    alias topc='top -o cpu'
    alias topm='top -o vsize'
  else
    alias topc='top -o %CPU'
    alias topm='top -o %MEM'
  fi
fi

# Miscellaneous

# to avoid any terminfo related mismatch in remote hosts
alias ssh="TERM=xterm-256color ssh"

# Serves a directory via HTTP.
# alias http-serve='python -m SimpleHTTPServer'

# fasd
# alias  v='f -e vim'      # quick opening files with vim
# alias  m='f -e mplayer'  # quick opening files with mplayer
# alias  o='a -e xdg-open' # quick opening files with xdg-open
# alias  enn='f -e emacsclient -nc'

# personalized aliases
# alias e="emacsclient -nc"
# alias ec="emacsclient -t"
# alias en="emacsclient -n"
# alias eckill="emacsclient -e '(kill-emacs)'"
alias tmux='tmux -2 -u'
alias mux="tmuxinator"
# alias ack="ack-grep --pager=\"less -R\""
# alias rsyncp='rsync -avz -e ssh --progress --partial '
alias peek='tee >(cat 1>&2)' # Mirror stdout to stderr, useful for seeing data going through a pipe

# suffix aliases
alias -s c=vim
alias -s h=vim
# alias -s zsh=vim
# alias -s sh=vim
# alias -s py=vim
alias -s h=vim
alias -s log=less

#
# Functions
#

# verbose for common commands
for c in chmod chown; do
    alias $c="$c -v"
done

# verbose with interactive
for c in cp mv; do
    alias $c="$c -v"
done

# Makes a directory and changes to it.
function mkdcd {
  [[ -n "$1" ]] && mkdir -p "$1" && builtin cd "$1"
}

# Changes to a directory and lists its contents.
function cdls {
  builtin cd "$argv[-1]" && ls "${(@)argv[1,-2]}"
}

# Pushes an entry onto the directory stack and lists its contents.
function pushdls {
  builtin pushd "$argv[-1]" && ls "${(@)argv[1,-2]}"
}

# Pops an entry off the directory stack and lists its contents.
function popdls {
  builtin popd "$argv[-1]" && ls "${(@)argv[1,-2]}"
}

# Prints columns 1 2 3 ... n.
function slit {
  awk "{ print ${(j:,:):-\$${^@}} }"
}

# Finds files and executes a command on them.
function find-exec {
  find . -type f -iname "*${1:-}*" -exec "${2:-file}" '{}' \;
}

# Displays user owned processes status.
function psu {
  ps -U "${1:-$LOGNAME}" -o 'pid,%cpu,%mem,command' "${(@)argv[2,-1]}"
}

# colorize man pages
man() {
    env                                         \
    LESS='-QRS'                                 \
    LESS_TERMCAP_mb=$'\E[0;93m'                 \
    LESS_TERMCAP_md=$'\E[0;94m'                 \
    LESS_TERMCAP_me=$'\E[0m'                    \
    LESS_TERMCAP_se=$'\E[0m'                    \
    LESS_TERMCAP_so=$'\E[3;103;34m'             \
    LESS_TERMCAP_ue=$'\E[0m'                    \
    LESS_TERMCAP_us=$'\E[3;93m'                 \
    man "$@"
}

# auto expand aliases
ealiases=(  l la ll lm lr lx lk lt lc lu sl get \
              df du topc topm http-serve pbcopy \
              pbpaste e ec en eckill            \
              ack rsyncp v m o enn debi debc    \
              g gb gbc gf gfc gfr gg gp gs )

_expand-ealias() {
    if [[ $LBUFFER =~ "(^|[;|&])\s*(${(j:|:)ealiases})\$" ]]; then
        zle _expand_alias
        zle expand-word
    fi
    zle magic-space
}
zle -N _expand-ealias
for keymap in 'emacs' 'viins'; do
    bindkey -M ${keymap} ' ' _expand-ealias
done

for keymap in 'emacs' 'viins' 'vicmd'; do
    bindkey -M ${keymap} '^Z' fancy-ctrl-z
done

bindkey -a "^A" increase-number
bindkey -a "^X" decrease-number

# End of File
