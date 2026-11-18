# Jump with zoxide when available. Otherwise keep a lightweight frecency DB
# under the Zsh cache and expose compatible `z` / `zi` commands.
if (( $+commands[zoxide] )); then
  eval "$(zoxide init zsh --cmd z)"
  typeset -g KURO_Z_PROVIDER=zoxide
else
  typeset -g KURO_Z_PROVIDER=native
  typeset -g _KURO_Z_DB="${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}/z-directories.tsv"
  typeset -gA _KURO_Z_SCORE _KURO_Z_STAMP
  zmodload zsh/datetime 2>/dev/null

  if [[ -r "$_KURO_Z_DB" ]]; then
    typeset _kuro_z_path _kuro_z_stamp _kuro_z_score
    while IFS=$'\t' read -r _kuro_z_path _kuro_z_stamp _kuro_z_score; do
      [[ -d "$_kuro_z_path" && "$_kuro_z_score" == <-> && "$_kuro_z_stamp" == <-> ]] || continue
      _KURO_Z_SCORE[$_kuro_z_path]=$_kuro_z_score
      _KURO_Z_STAMP[$_kuro_z_path]=$_kuro_z_stamp
    done < "$_KURO_Z_DB"
    unset _kuro_z_path _kuro_z_stamp _kuro_z_score
  fi

  function _kuro_z_save() {
    local tmp="${_KURO_Z_DB}.$$" path
    umask 077
    {
      for path in "${(@k)_KURO_Z_SCORE}"; do
        [[ -d "$path" ]] || continue
        print -r -- "${_KURO_Z_STAMP[$path]}"$'\t'"${_KURO_Z_SCORE[$path]}"$'\t'"$path"
      done
    } | /usr/bin/sort -nr -t $'\t' -k2,2 | /usr/bin/head -n 500 >| "$tmp"
    /usr/bin/mv -f -- "$tmp" "$_KURO_Z_DB"
  }

  function _kuro_z_record() {
    [[ -n "$PWD" && "$PWD" != "$HOME" ]] || return 0
    local now=${EPOCHSECONDS:-$(date +%s)}
    local previous="${_KURO_Z_SCORE[$PWD]:-0}"
    _KURO_Z_SCORE[$PWD]=$(( previous + 1 ))
    _KURO_Z_STAMP[$PWD]=$now
    _kuro_z_save
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook chpwd _kuro_z_record

  function z() {
    if [[ "$1" == - ]]; then
      builtin cd -
      return
    elif [[ "$1" == -l ]]; then
      print -rl -- "${(@k)_KURO_Z_SCORE}"
      return
    elif (( $# == 1 )) && [[ -d "$1" ]]; then
      builtin cd -- "$1"
      return
    fi

    local now=${EPOCHSECONDS:-$(date +%s)} path term lower rank score stamp best_rank=-1 best=''
    for path in "${(@k)_KURO_Z_SCORE}"; do
      [[ -d "$path" ]] || continue
      lower="${path:l}"
      local matches=1 lower_term
      for term in "$@"; do
        lower_term="${term:l}"
        [[ "$lower" == *"$lower_term"* ]] || { matches=0; break; }
      done
      (( matches )) || continue
      score="${_KURO_Z_SCORE[$path]}"
      stamp="${_KURO_Z_STAMP[$path]}"
      rank=$(( score * 86400 / (now - stamp + 86400) ))
      if (( rank > best_rank )); then
        best_rank=$rank
        best=$path
      fi
    done

    if [[ -z "$best" ]]; then
      print -u2 -r -- "z: no matching directory for $*"
      return 1
    fi
    builtin cd -- "$best"
  }

  function zi() {
    if (( $+commands[fzf] )); then
      local target
      target="$(printf '%s\n' "${(@k)_KURO_Z_SCORE}" | fzf --query="$*" --prompt='z > ' --preview='ls -la --color=always {} 2>/dev/null' --preview-window='right,50%,border-left')" || return
      [[ -n "$target" ]] && builtin cd -- "$target"
    else
      z "$@"
    fi
  }
fi
