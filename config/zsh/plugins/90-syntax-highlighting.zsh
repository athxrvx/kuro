# Keep syntax highlighting last so it can wrap widgets installed by other plugins.
[[ ! -o interactive ]] && return

typeset -g ZSH_HIGHLIGHT_HIGHLIGHTERS=(main brackets pattern cursor)
typeset -gA ZSH_HIGHLIGHT_STYLES
ZSH_HIGHLIGHT_STYLES[command]='fg=2,bold'
ZSH_HIGHLIGHT_STYLES[builtin]='fg=2,bold'
ZSH_HIGHLIGHT_STYLES[function]='fg=2,bold'
ZSH_HIGHLIGHT_STYLES[alias]='fg=2,bold'
ZSH_HIGHLIGHT_STYLES[reserved-word]='fg=5,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=1,bold'
ZSH_HIGHLIGHT_STYLES[precommand]='fg=6,bold'
ZSH_HIGHLIGHT_STYLES[commandseparator]='fg=8'
ZSH_HIGHLIGHT_STYLES[redirection]='fg=6'
ZSH_HIGHLIGHT_STYLES[single-quoted-argument]='fg=3'
ZSH_HIGHLIGHT_STYLES[double-quoted-argument]='fg=3'
ZSH_HIGHLIGHT_STYLES[dollar-quoted-argument]='fg=3'
ZSH_HIGHLIGHT_STYLES[dollar-double-quoted-argument]='fg=3'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=5'
ZSH_HIGHLIGHT_STYLES[comment]='fg=8'
ZSH_HIGHLIGHT_STYLES[hashed-command]='fg=2,bold'
ZSH_HIGHLIGHT_STYLES[back-quoted-argument]='fg=5'

for _kuro_plugin in \
  "$HOME/.config/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" \
  /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh \
  /usr/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh; do
  if [[ -r "$_kuro_plugin" ]]; then
    source "$_kuro_plugin"
    typeset -g KURO_SYNTAX_HIGHLIGHTING=plugin
    break
  fi
done
unset _kuro_plugin

if [[ -z "${KURO_SYNTAX_HIGHLIGHTING:-}" ]]; then
  # Native ZLE highlighter fallback for installations without the plugin.
  function _kuro_syntax_highlight() {
    local n=${#BUFFER} i=1 j start end char next word first_word='' found_command=0
    region_highlight=()

    while (( i <= n )); do
      char="$BUFFER[$i]"

      # Shell comments begin at a word boundary.
      if [[ "$char" == '#' ]] && { (( i == 1 )) || [[ "$BUFFER[$((i - 1))]" == [[:space:]] ]]; }; then
        region_highlight+=( "$((i - 1)) $n fg=8" )
        break
      fi

      # Keep quoted strings readable and do not interpret their contents.
      if [[ "$char" == "'" || "$char" == '"' ]]; then
        start=$i
        j=$((i + 1))
        while (( j <= n )); do
          next="$BUFFER[$j]"
          if [[ "$next" == "$char" ]]; then
            (( j == 1 )) || [[ "$BUFFER[$((j - 1))]" != '\\' ]] && break
          fi
          (( j++ ))
        done
        end=$(( j <= n ? j : n ))
        region_highlight+=( "$((start - 1)) $end fg=3" )
        i=$((end + 1))
        continue
      fi

      # Highlight shell variables, including brace-delimited names.
      if [[ "$char" == '$' ]]; then
        start=$i
        if [[ "$BUFFER[$((i + 1))]" == '{' ]]; then
          j=$((i + 2))
          while (( j <= n )) && [[ "$BUFFER[$j]" != '}' ]]; do (( j++ )); done
          end=$(( j <= n ? j : n ))
        else
          j=$((i + 1))
          while (( j <= n )) && [[ "$BUFFER[$j]" == [A-Za-z0-9_#?$!*@-] ]]; do (( j++ )); done
          end=$((j - 1))
        fi
        if (( end >= start )); then
          region_highlight+=( "$((start - 1)) $end fg=6" )
          i=$((end + 1))
          continue
        fi
      fi

      # Give command names, options and control operators distinct colors.
      if [[ "$char" == [[:space:]] ]]; then
        (( i++ ))
        continue
      fi
      if [[ "$char" == [\;\|\&\<\>\(\)] ]]; then
        region_highlight+=( "$((i - 1)) $i fg=8" )
        (( i++ ))
        continue
      fi

      start=$i
      j=$i
      while (( j <= n )) && [[ "$BUFFER[$j]" != [[:space:]] && "$BUFFER[$j]" != [\;\|\&\<\>\(\)] ]]; do (( j++ )); done
      end=$((j - 1))
      word="$BUFFER[$start,$end]"

      if [[ "$word" == -* ]]; then
        region_highlight+=( "$((start - 1)) $end fg=5" )
      elif (( ! found_command )); then
        first_word="$word"
        case "$word" in
          if|then|else|elif|fi|for|while|until|do|done|case|esac|in|function|select|time|coproc|!)
            region_highlight+=( "$((start - 1)) $end fg=5,bold" ) ;;
          sudo|command|builtin|exec|noglob|nocorrect|nohup|time)
            region_highlight+=( "$((start - 1)) $end fg=6,bold" ) ;;
          *)
            if (( $+commands[$word] || $+builtins[$word] || $+functions[$word] || $+aliases[$word] )); then
              region_highlight+=( "$((start - 1)) $end fg=2,bold" )
            else
              region_highlight+=( "$((start - 1)) $end fg=1,bold" )
            fi ;;
        esac
        found_command=1
      fi
      i=$((end + 1))
    done

    # Render the native autosuggestion as muted ghost text.
    if [[ -n "${_KURO_SUGGESTION_HIGHLIGHT:-}" ]]; then
      local suggestion_start suggestion_end suggestion_style
      read -r suggestion_start suggestion_end suggestion_style <<< "$_KURO_SUGGESTION_HIGHLIGHT"
      [[ -n "$suggestion_start" && -n "$suggestion_end" ]] && region_highlight+=( "$suggestion_start $suggestion_end $suggestion_style" )
    fi
  }

  autoload -Uz add-zle-hook-widget
  add-zle-hook-widget line-pre-redraw _kuro_syntax_highlight
  typeset -g KURO_SYNTAX_HIGHLIGHTING=native
fi
