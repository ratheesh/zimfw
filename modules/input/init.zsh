#
# Editor and input char assignment
#


# Return if requirements are not found.
if [[ ${TERM} == 'dumb' ]]; then
    return 1
fi

# Treat these characters as part of a word.
WORDCHARS='*?_-.[]~&;!#$%^(){}<>'

# Use human-friendly identifiers.
# zmodload zsh/terminfo
zmodload -F zsh/terminfo +b:echoti +p:terminfo
typeset -gA key_info
key_info=(
  'Control'          '\C-'
  'ControlLeft'      '\e[1;5D \e[5D \e\e[D \eOd'
  'ControlRight'     '\e[1;5C \e[5C \e\e[C \eOc'
  'ControlPageUp'    '\e[5;5~'
  'ControlPageDown'  '\e[6;5~'
  'Escape'           '\e'
  'Meta'             '\M-'
  'Backspace'        "^?"
  'Delete'           "^[[3~"
  'F1'               "$terminfo[kf1]"
  'F2'               "$terminfo[kf2]"
  'F3'               "$terminfo[kf3]"
  'F4'               "$terminfo[kf4]"
  'F5'               "$terminfo[kf5]"
  'F6'               "$terminfo[kf6]"
  'F7'               "$terminfo[kf7]"
  'F8'               "$terminfo[kf8]"
  'F9'               "$terminfo[kf9]"
  'F10'              "$terminfo[kf10]"
  'F11'              "$terminfo[kf11]"
  'F12'              "$terminfo[kf12]"
  'Insert'           "$terminfo[kich1]"
  'Home'             "$terminfo[khome]"
  'PageUp'           "$terminfo[kpp]"
  'End'              "$terminfo[kend]"
  'PageDown'         "$terminfo[knp]"
  'Up'               "$terminfo[kcuu1]"
  'Left'             "$terminfo[kcub1]"
  'Down'             "$terminfo[kcud1]"
  'Right'            "$terminfo[kcuf1]"
  'BackTab'          "$terminfo[kcbt]"
)

#
# External Editor
#

# Allow command line editing in an external editor.
autoload -Uz edit-command-line
zle -N edit-command-line

#
# Functions
#
# Runs bindkey but for all of the keymaps. Running it with no arguments will
# print out the mappings for all of the keymaps.
function bindkey-all {
  local keymap=''
  for keymap in $(bindkey -l); do
    [[ "$#" -eq 0 ]] && printf "#### %s\n" "${keymap}" 1>&2
    bindkey -M "${keymap}" "$@"
  done
}

# Exposes information about the Zsh Line Editor via the $editor_info associative
# array.
function editor-info {
  # Clean up previous $editor_info.
  unset editor_info
  typeset -gA editor_info

  if [[ "$KEYMAP" = 'vicmd' ]]; then
      zstyle -s ':zim:input:info:keymap:alternate' format 'REPLY'
      editor_info[keymap]="$REPLY"
      editor_info[mode]="       %F{60}---%B%F{208}NORMAL%F{60}%b---%f"
  elif [[ "$KEYMAP" = 'viins' || "$KEYMAP" = 'main' ]];then
      zstyle -s ':zim:input:info:keymap:primary' format 'REPLY'
      editor_info[mode]="       %F{60}---%B%F{33}INSERT%F{60}%b---%f"
      editor_info[keymap]="$REPLY"

      if [[ "$ZLE_STATE" == *overwrite* ]]; then
          zstyle -s ':zim:input:info:keymap:primary:overwrite' format 'REPLY'
          editor_info[overwrite]="$REPLY"
      else
          zstyle -s ':zim:input:info:keymap:primary:insert' format 'REPLY'
          editor_info[overwrite]="$REPLY"
      fi
  elif [[ "$KEYMAP" = 'vivis' || "$KEYMAP" = 'vivli' ]];then
      zstyle -s ':zim:input:info:keymap:alternate' format 'REPLY'
      editor_info[keymap]="$REPLY"
      editor_info[mode]="       %F{60}---%B%F{5}VISUAL%F{60}%b---%f"
  fi

  unset REPLY
  zle zle-reset-prompt
}
zle -N editor-info

# Reset the prompt based on the current context and
# the ps-context option.
function zle-reset-prompt {
  if zstyle -t ':prezto:input' ps-context; then
    # If we arent within one of the specified contexts, then we want to reset
    # the prompt with the appropriate editor_info[keymap] if there is one.
    if [[ $CONTEXT != (select|cont) ]]; then
      zle .reset-prompt
      zle -R
    fi
  else
    zle .reset-prompt
    zle -R
  fi
}
zle -N zle-reset-prompt

# Updates editor information when the keymap changes.
function zle-keymap-select {
  zle editor-info
}
zle -N zle-keymap-select

# Toggles emacs overwrite mode and updates editor information.
function overwrite-mode {
  zle .overwrite-mode
  zle editor-info
}
zle -N overwrite-mode

# Enters vi insert mode and updates editor information.
function vi-insert {
  zle .vi-insert
  zle editor-info
}
zle -N vi-insert

# Moves to the first non-blank character then enters vi insert mode and updates
# editor information.
function vi-insert-bol {
  zle .vi-insert-bol
  zle editor-info
}
zle -N vi-insert-bol

# Enters vi replace mode and updates editor information.
function vi-replace  {
  zle .vi-replace
  zle editor-info
}
zle -N vi-replace

# Expand aliases
function glob-alias {
  zle _expand_alias
  zle expand-word
  zle magic-space
}
zle -N glob-alias

# Toggle the comment character at the start of the line. This is meant to work
# around a buggy implementation of pound-insert in zsh.
#
# This is currently only used for the emacs keys because vi-pound-insert has
# been reported to work properly.
function pound-toggle {
  if [[ "$BUFFER" = '#'* ]]; then
    # Because of an oddity in how zsh handles the cursor when the buffer size
    # changes, we need to make this check before we modify the buffer and let
    # zsh handle moving the cursor back if its past the end of the line.
    if [[ $CURSOR != $#BUFFER ]]; then
      (( CURSOR -= 1 ))
    fi
    BUFFER="${BUFFER:1}"
  else
    BUFFER="#$BUFFER"
    (( CURSOR += 1 ))
  fi
}
zle -N pound-toggle

# Bind the keys

# Expands .... to ../..
if [[ ${zdouble_dot_expand} == 'true' ]]; then
  double-dot-expand() {
    if [[ ${LBUFFER} == *.. ]]; then
      LBUFFER+='/..'
    else
      LBUFFER+='.'
    fi
  }
  zle -N double-dot-expand
fi

# Displays an indicator when completing.
function expand-or-complete-with-indicator {
  local indicator
  zstyle -s ':zim:input:info:completing' format 'indicator'

  # This is included to work around a bug in zsh which shows up when interacting
  # with multi-line prompts.
  if [[ -z "$indicator" ]]; then
    zle expand-or-complete
    return
  fi

  [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti rmam
  print -Pn "$indicator"
  [[ -n "$terminfo[rmam]" && -n "$terminfo[smam]" ]] && echoti smam
  sleep .1
  zle expand-or-complete
  zle redisplay
}
zle -N expand-or-complete-with-indicator

# Redisplay after completing, and avoid blank prompt after <Tab><Tab><Ctrl-C>
expand-or-complete-with-redisplay() {
  local indicator
  zstyle -s ':zim:input:info:completing' format 'indicator'
  print -n '$indicator'
  zle expand-or-complete
  zle redisplay
}
zle -N expand-or-complete-with-redisplay

# Put into application mode and validate ${terminfo}
zle-line-init() {
  if (( ${+terminfo[smkx]} )); then
    echoti smkx
  fi
  zle editor-info
}
zle -N zle-line-init

zle-line-finish() {
  if (( ${+terminfo[rmkx]} )); then
    echoti rmkx
  fi
  zle editor-info
}
zle -N zle-line-finish

# Other functions

#this function tries to mimic vim's ctrl-a and ctrl-x bindings for
# increasing or decreasing a number.
function _increase_number() {
  integer pos NUMBER i first last prelength diff
  pos=$CURSOR
  # find numbers starting from the left of the cursor to the end of the line
  while [[ $BUFFER[$pos] != [[:digit:]] ]]; do
    (( pos++ ))
    (( $pos > $#BUFFER )) && return
  done

  # use the numeric argument and default to 1
  # negate if called as decrease-number
  NUMBER=${NUMERIC:-1}
  if [[ $WIDGET = decrease-number ]]; then
    (( NUMBER = 0 - $NUMBER ))
  fi

  # find the start of the number
  i=$pos
  while [[ $BUFFER[$i-1] = [[:digit:]] ]]; do
    (( i-- ))
  done
  first=$i

  # include one leading - if found
  if [[ $BUFFER[$first-1] = - ]]; then
    (( first-- ))
  fi

  # find the end of the number
  i=$pos
  while [[ $BUFFER[$i+1] = [[:digit:]] ]]; do
    (( i++ ))
  done
  last=$i

  # change the number and move cursor after it
  prelength=$#BUFFER
  (( BUFFER[$first,$last] += $NUMBER ))
  (( diff = $#BUFFER - $prelength ))
  (( CURSOR = last + diff ))
}
zle -N increase-number _increase_number
zle -N decrease-number _increase_number

# Use C-z to put current application to background and vice-versa
fancy-ctrl-z () {
    if [[ $#BUFFER -eq 0 ]]; then
        BUFFER="fg"
        zle accept-line
    else
        zle push-input
        zle clear-screen
    fi
}
zle -N fancy-ctrl-z

# Inserts 'sudo ' at the beginning of the line.
function prepend-sudo {
    if [[ "$BUFFER" != su(do|)\ * ]]; then
        BUFFER="sudo $BUFFER"
        (( CURSOR += 5 ))
    fi
}
zle -N prepend-sudo

#
# Emacs and Vi Key Bindings
#

#
# Layout
#

# Set the key layout.
# zstyle -s ':zim:input' key-bindings 'key_bindings'
if [[ "${zinput_mode}" == (emacs|) ]]; then
    bindkey -e
elif [[ "${zinput_mode}" == vi ]]; then
    bindkey -v
else
    print "zim: input: invalid key bindings: $key_bindings" >&2
fi

# Unbound keys in vicmd and viins mode will cause really odd things to happen
# such as the casing of all the characters you have typed changing or other
# undefined things. In emacs mode they just insert a tilde, but bind these keys
# in the main keymap to a noop op so if there is no keybind in the users mode
# it will fall back and do nothing.
function _zim-zle-noop {  ; }
zle -N _zim-zle-noop
local -a unbound_keys
unbound_keys=(
  "${key_info[F1]}"
  "${key_info[F2]}"
  "${key_info[F3]}"
  "${key_info[F4]}"
  "${key_info[F5]}"
  "${key_info[F6]}"
  "${key_info[F7]}"
  "${key_info[F8]}"
  "${key_info[F9]}"
  "${key_info[F10]}"
  "${key_info[F11]}"
  "${key_info[F12]}"
  "${key_info[PageUp]}"
  "${key_info[PageDown]}"
  "${key_info[ControlPageUp]}"
  "${key_info[ControlPageDown]}"
)

for keymap in $unbound_keys; do
  bindkey -M viins "${keymap}" _zim-zle-noop
  bindkey -M vicmd "${keymap}" _zim-zle-noop
done

# Keybinds for all keymaps
for keymap in 'emacs' 'viins' 'vicmd'; do
  bindkey -M "$keymap" "$key_info[Home]" beginning-of-line
  bindkey -M "$keymap" "$key_info[End]" end-of-line
done

# Keybinds for all vi keymaps
for keymap in viins vicmd; do
    # Ctrl + Left and Ctrl + Right bindings to forward/backward word
    for key in "${(s: :)key_info[ControlLeft]}";do
        bindkey -M "$keymap" "$key" vi-backward-word
    done

    for key in "${(s: :)key_info[ControlRight]}";do
        bindkey -M "$keymap" "$key" vi-forward-word
    done
done

bindkey -M vicmd '?' history-incremental-search-backward
bindkey -M vicmd '/' history-incremental-search-forward

# Beginning search with arrow keys
autoload -U up-line-or-beginning-search
autoload -U down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey "^[OA" up-line-or-beginning-search
bindkey "^[OB" down-line-or-beginning-search
bindkey -M vicmd "k" up-line-or-beginning-search
bindkey -M vicmd "j" down-line-or-beginning-search

# Just delete char in command mode on backspace.
bindkey -M vicmd "^?" vi-backward-delete-char

# Insert 'sudo ' at the beginning of the line.
bindkey -M vicmd "${key_info[Escape]}s" prepend-sudo

# Keybinds for emacs and vi insert mode
for keymap in 'emacs' 'viins'; do
    bindkey -M "$keymap" "$key_info[Insert]" overwrite-mode
    bindkey -M "$keymap" "$key_info[Delete]" delete-char
    bindkey -M "$keymap" "$key_info[Backspace]" backward-delete-char

    bindkey -M "$keymap" "$key_info[Left]" backward-char
    bindkey -M "$keymap" "$key_info[Right]" forward-char

    # Expand history on space.
    bindkey -M "$keymap" ' ' magic-space

    # Clear screen.
    bindkey -M "$keymap" "$key_info[Control]L" clear-screen

    # Expand command name to full path.
    for key in "$key_info[Escape]"{E,e};do
        bindkey -M "$keymap" "$key" expand-cmd-path
    done

    # Duplicate the previous word.
    autoload -Uz copy-earlier-word
    zle -N copy-earlier-word
    for key in "$key_info[Escape]"{M,m};do
        # bindkey -M "$keymap" "$key" copy-prev-shell-word
        bindkey -M "$keymap" "$key" copy-earlier-word
    done

    # Use a more flexible push-line.
    for key in "$key_info[Control]Q" "$key_info[Escape]"{q,Q};do
        bindkey -M "$keymap" "$key" push-line-or-edit
    done

    # Bind Shift + Tab to go to the previous menu item.
    bindkey -M "$keymap" "$key_info[BackTab]" reverse-menu-complete

    # Complete in the middle of word.
    bindkey -M "$keymap" "$key_info[Control]I" expand-or-complete

    # Expand .... to ../..
    if [[ ${zdouble_dot_expand} == 'true' ]]; then
        bindkey -M "$keymap" "." double-dot-expand
    fi

    # Display an indicator when completing.
    bindkey -M "$keymap" "$key_info[Control]I" \
        expand-or-complete-with-indicator

    # Insert 'sudo ' at the beginning of the line.
    bindkey -M "$keymap" "${key_info[Escape]}s" prepend-sudo

    # control-space expands all aliases, including global
    # bindkey -M "$keymap" "$key_info[Control] " glob-alias

    # These are mainly for viins mode
    bindkey -M "$keymap" "$key_info[Control]W"   backward-delete-word
    bindkey -M "$keymap" "$key_info[Control]U"   backward-kill-line
    bindkey -M "$keymap" "$key_info[Control]K"   kill-line

done

# Word walking by default.
if zstyle -t ':zim:input' zsh_vi_word_walking; then
    bindkey -M vicmd h vi-backward-word
    bindkey -M vicmd l vi-forward-word
    for keymap in viins vicmd;do
        bindkey -M "$keymap" "$key_info[Escape]h" vi-backward-char
        bindkey -M "$keymap" "$key_info[Escape]l" vi-forward-char
        bindkey -M "$keymap" "$key_info[Escape]h" vi-backward-char
        bindkey -M "$keymap" "$key_info[Escape]l" vi-forward-char
    done
fi
bindkey -M viins "$key_info[Escape]$key_info[Backspace]" backward-kill-word
bindkey -M vicmd "$key_info[Escape]$key_info[Backspace]" backward-kill-word

zstyle -s ':zim:input' key-bindings 'key_bindings'
if [[ "$key_bindings" == vi ]]; then
    # load surround module
    # KEYTIMEOUT should be higher if vicmd Keybindings to work fine
    autoload -Uz surround
    zle -N delete-surround surround
    zle -N add-surround surround
    zle -N change-surround surround
    bindkey -M vicmd cs change-surround
    bindkey -M vicmd ds delete-surround
    bindkey -M vicmd ys add-surround
    bindkey -M visual S add-surround
fi

unset key{,map,_bindings}

# End of File
