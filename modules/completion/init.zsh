#
# Completion enhancements
#


#
# initialization
#

# if it's a dumb terminal, return.
if [[ ${TERM} == 'dumb' ]]; then
  return 1
fi

# add the completions to the fpath
fpath=(${0:h}/external/src ${fpath})

# load and initialize the completion system
autoload -Uz compinit && compinit -C -d "${ZDOTDIR:-${HOME}}/${zcompdump_file:-.zcompdump}"


#
# zsh options
#

# If a completion is performed with the cursor within a word, and a full
# completion is inserted, the cursor is moved to the end of the word.
setopt ALWAYS_TO_END

# Perform a path search even on command names with slashes in them.
setopt PATH_DIRS

# Make globbing (filename generation) not sensitive to case.
setopt NO_CASE_GLOB

# Don't beep on an ambiguous completion.
setopt NO_LIST_BEEP


#
# completion module options
#

# group matches and describe.
zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*:matches' group yes
zstyle ':completion:*:options' description yes
zstyle ':completion:*:options' auto-description '%d'
zstyle ':completion:*:corrections' format '%F{green}-- %d (errors: %e) --%f'
zstyle ':completion:*:descriptions' format '%F{yellow}-- %d --%f'
zstyle ':completion:*:messages' format '%F{purple}-- %d --%f'
zstyle ':completion:*:warnings' format '%F{red}-- no matches found --%f'
zstyle ':completion:*' format '%F{yellow}-- %d --%f'
zstyle ':completion:*' group-name ''
zstyle ':completion:*' verbose yes
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' '+r:|?=**'

# directories
if (( ! ${+LS_COLORS} )); then
  # Locally use same LS_COLORS definition from utility module, in case it was not set
  local LS_COLORS='di=1;34:ln=35:so=32:pi=33:ex=31:bd=1;36:cd=1;33:su=30;41:sg=30;46:tw=30;42:ow=30;43'
fi
zstyle ':completion:*:default' list-colors ${(s.:.)LS_COLORS}
zstyle ':completion:*:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select
zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'expand'
zstyle ':completion:*' squeeze-slashes true

# enable caching
zstyle ':completion::complete:*' use-cache on
zstyle ':completion::complete:*' cache-path "${ZDOTDIR:-${HOME}}/.zcompcache"

# ignore useless commands and functions
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec)|prompt_*)'

# completion sorting
zstyle ':completion:*:*:-subscript-:*' tag-order indexes parameters

# Man
zstyle ':completion:*:manuals' separate-sections true
zstyle ':completion:*:manuals.(^1*)' insert-sections true

# history
zstyle ':completion:*:history-words' stop yes
zstyle ':completion:*:history-words' remove-all-dups yes
zstyle ':completion:*:history-words' list false
zstyle ':completion:*:history-words' menu yes

# ignore multiple entries.
zstyle ':completion:*:(rm|kill|diff):*' ignore-line other
zstyle ':completion:*:rm:*' file-patterns '*:all-files'

# If the _my_hosts function is defined, it will be called to add the ssh hosts
# completion, otherwise _ssh_hosts will fall through and read the ~/.ssh/config
zstyle -e ':completion:*:*:ssh:*:my-accounts' users-hosts \
  '[[ -f ${HOME}/.ssh/config && ${key} == hosts ]] && key=my_hosts reply=()'

#--------------------------------------------------------------------------------
# --------------------------- PORTED/CUSTOMIZED CHANGES -------------------------
#--------------------------------------------------------------------------------

# Automatically use menu completion after the second consecutive request for completion
setopt AUTO_MENU

# Automatically list choices on an ambiguous completion.
setopt AUTO_LIST

# On an ambiguous completion, instead of listing possibilities or beeping, insert the first match immediately.
# Then when completion is requested again, remove the first match and insert the second match, etc.
unsetopt MENU_COMPLETE

# Complete from both ends of a word.
setopt COMPLETE_IN_WORD

# Disable start/stop characters in shell editor.
unsetopt FLOW_CONTROL

# If completed parameter is a directory, add a trailing slash.
setopt AUTO_PARAM_SLASH

# Show message while waiting for completion
zstyle ':completion:*' show-completer true

zstyle ':completion:*:corrections'  format '%B%F{60}---%f%b %F{3}%d %F{9}(errors: %e)%f %B%F{60}---%f%b'
zstyle ':completion:*:descriptions' format '%B%F{60}---%f%b %F{65}%d%f %B%F{60}---%f%b'
zstyle ':completion:*:messages'     format '%B%F{60}---%f%b %F{65}%d%f %B%F{60}---%f%b'
zstyle ':completion:*:warnings'     format '%B%F{60}---%f%b %F{9}no matches found%f %B%F{60}---%f%b'
zstyle ':completion:*'              format '%B%F{60}---%f%b %F{65}%d%f %B%F{60}---%f%b'

# zstyle ':completion:*:default' list-prompt '%S%M matches%s'
zstyle ':completion:*' list-prompt %SAt %p: Hit \<TAB\> for more, or a character to insert%s

zstyle ':completion:*' select-prompt '%SScrolling active: current selection at %p%s'

zstyle ':completion:*' list-dirs-first true

zstyle ':completion:*:-tilde-:*' group-order 'named-directories' 'path-directories' 'users' 'expand'

# Environmental Variables
zstyle ':completion::*:(-command-|export):*' fake-parameters ${${${_comps[(I)-value-*]#*,}%%,*}:#-*-}

zstyle ':completion:*:expand:*' group-order all-expansions expansions

# cd|mv|cp command never selects the parent directory (e.g.: cd ../<TAB>
zstyle ':completion:*:(cd|mv|cp):*' ignore-parents parent pwd

zstyle ':completion:*:cd:*' ignored-patterns '(*/)#lost+found'
zstyle ':completion:*:cd:*' ignored-patterns '(*/)#CVS'
zstyle ':completion:*:(all-|)files' ignored-patterns '(|*/)CVS'

# Avoid completion of unwanted(mostly default) users
zstyle ':completion:*:*:*:users' ignored-patterns \
    $(awk -F: '$3<1000 || $3>60000 {print $1}' /etc/passwd)

zstyle ':completion:*:bd:*' list-colors '=^(-- *)=34'

# Prettier completion for processes
zstyle ':completion:*:*:*:*:processes' force-list always

zstyle ':completion:*:options' list-colors '=^(-- *)=34'

# partial match coloring
zstyle -e ':completion:*:default' list-colors 'reply=("${PREFIX:+=(#bi)($PREFIX:t)(?)*=2=32=2}:${(s.:.)LS_COLORS}")'

# prevent a tab from being inserted when there are no characters to the left of the cursor.
zstyle ':completion:*' insert-tab false

# 0 -- vanilla completion (abc => abc)
# 1 -- smart case completion (abc => Abc)
# 2 -- word flex completion (abc => A-big-Car)
# 3 -- full flex completion (abc => ABraCadabra)
# zstyle ':completion:*' matcher-list '' \
#        'm:{a-z\-}={A-Z\_}' \
#        'r:[^[:alpha:]]||[[:alpha:]]=** r:|=* m:{a-z\-}={A-Z\_}' \
#        'r:|?=** m:{a-z\-}={A-Z\_}'
zstyle ':completion:*' accept-exact '*(N)'
zstyle ':completion:*' rehash true
zstyle ':completion:*' use-ip true

# Populate hostname completion.
zstyle -e ':completion:*:hosts' hosts 'reply=(
  ${=${=${=${${(f)"$(cat {/etc/ssh_,~/.ssh/known_}hosts(|2)(N) 2>/dev/null)"}%%[#| ]*}//\]:[0-9]*/ }//,/ }//\[/ }
  ${=${(f)"$(cat /etc/hosts(|)(N) <<(ypcat hosts 2>/dev/null))"}%%\#*}
  ${=${${${${(@M)${(f)"$(cat ~/.ssh/config 2>/dev/null)"}:#Host *}#Host }:#*\**}:#*\?*}}
)'

# processes
zstyle ':completion:*:*:*:*:processes' command 'ps -u $USER -o pid,user,comm -w'

# Kill
zstyle ':completion::*:kill:*:*' command 'ps xf -U $USER -o pid,%cpu,cmd'
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;36=0=01'
zstyle ':completion:*:*:kill:*' menu yes select
zstyle ':completion:*:*:kill:*' force-list always
zstyle ':completion:*:*:kill:*' insert-ids single
zstyle ':completion:*:*:kill:*' list-colors '=(#b) #([0-9]#)*( *[a-z])*=34=31=33'

zstyle ':completion:*:directories'  list-colors '=*=32'

# user completion array. users completion will use only these items
typeset -gU users
users=(root)
# zstyle ':completion:*' users $users
zstyle -e ':completion:*:users' users 'local user; getent passwd | while IFS=: read -rA user; do (( user[3] >= 1000 || user[3] == 0 )) && reply+=($user[1]); done'

# completion of .. directories
# zstyle ':completion:*' special-dirs true

# fault tolerance
# zstyle ':completion:*' completer _complete _correct _approximate
# (1 error on 3 characters)
# zstyle -e ':completion:*:approximate:*' max-errors 'reply=( $(( ($#PREFIX+$#SUFFIX)/3 )) numeric )'

# smart editor completion
zstyle ':completion:*:(nano|vim|nvim|vi|emacs|e):*' ignored-patterns '*.(wav|mp3|flac|ogg|mp4|avi|mkv|webm|iso|dmg|so|o|a|bin|exe|dll|pcap|7z|zip|tar|gz|bz2|rar|deb|pkg|gzip|pdf|mobi|epub|png|jpeg|jpg|gif)'

# SSH/SCP/RSYNC
zstyle ':completion:*:(scp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:(scp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
zstyle ':completion:*:ssh:*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host users hosts-ipaddr
zstyle ':completion:*:(ssh|ssh-copy-id|scp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|ssh-copy-id|scp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|ssh-copy-id|scp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'

# End of File
