#
# enables fish-shell like syntax highlighting
#

# highlighters
ZSH_HIGHLIGHT_HIGHLIGHTERS=(${zhighlighters[@]})

source "${0:h}/external/fast-syntax-highlighting.plugin.zsh" || return 1
