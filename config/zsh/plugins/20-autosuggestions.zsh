# Load zsh-autosuggestions when installed. When it is absent, provide a small
# native ZLE history suggestion so the feature still works without downloads.
if [[ ! -o interactive ]]; then
  return
fi

ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'
for _kuro_plugin in \
  "$HOME/.config/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" \
  /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh-autosuggestions/zsh-autosuggestions.zsh \
  /usr/share/zsh/plugins/zsh-autosuggestions.zsh; do
  if [[ -r "$_kuro_plugin" ]]; then
    source "$_kuro_plugin"
    typeset -g KURO_AUTOSUGGESTIONS=plugin
    break
  fi
done
unset _kuro_plugin

if [[ -z "${KURO_AUTOSUGGESTIONS:-}" ]]; then
  typeset -ga _kuro_history_suggestions
  typeset -g _KURO_SUGGESTION_HIGHLIGHT=''

  function _kuro_suggest_history_refresh() {
    _kuro_history_suggestions=( "${(@f)$(fc -ln -200 2>/dev/null)}" )
  }

  function _kuro_suggest_refresh() {
    POSTDISPLAY=''
    _KURO_SUGGESTION_HIGHLIGHT=''
    [[ -n "$BUFFER" ]] || return 0

    local candidate
    for candidate in "${_kuro_history_suggestions[@]}"; do
      candidate="${candidate#"${candidate%%[![:space:]]*}"}"
      [[ -n "$candidate" && "$candidate" != *$'\n'* && ${#candidate} -gt ${#BUFFER} ]] || continue
      if [[ "${candidate[1,${#BUFFER}]}" == "$BUFFER" ]]; then
        POSTDISPLAY="${candidate[$(( ${#BUFFER} + 1 )),-1]}"
        _KURO_SUGGESTION_HIGHLIGHT="${#BUFFER} ${#candidate} fg=8"
        break
      fi
    done
  }

  function _kuro_suggest_accept() {
    [[ -n "$POSTDISPLAY" ]] || return 0
    BUFFER+="$POSTDISPLAY"
    CURSOR=${#BUFFER}
    POSTDISPLAY=''
    zle reset-prompt
  }

  function _kuro_suggest_forward_char() {
    if (( CURSOR == ${#BUFFER} )) && [[ -n "$POSTDISPLAY" ]]; then
      _kuro_suggest_accept
    else
      zle .forward-char
    fi
  }

  autoload -Uz add-zsh-hook add-zle-hook-widget
  add-zsh-hook precmd _kuro_suggest_history_refresh
  add-zle-hook-widget line-pre-redraw _kuro_suggest_refresh
  zle -N kuro-suggest-accept _kuro_suggest_accept
  zle -N forward-char _kuro_suggest_forward_char
  bindkey '^@' kuro-suggest-accept
  typeset -g KURO_AUTOSUGGESTIONS=native
fi
