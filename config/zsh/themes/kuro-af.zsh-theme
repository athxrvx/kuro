# Kuro Af-Magic: Kuro's palette and container context in af-magic's layout.
# The full-width dashed rule, green path, compact Git marker, prompt glyph,
# and right-side status/context keep the original af-magic shape.

[[ -r "$HOME/.cache/kuro/zsh-colors.zsh" ]] && source "$HOME/.cache/kuro/zsh-colors.zsh"
: ${KURO_PROMPT_BG:=#151515}
: ${KURO_PROMPT_FG:=#dedede}
: ${KURO_PROMPT_ACCENT:=#97bedc}
: ${KURO_PROMPT_HOT:=#e27373}
: ${KURO_PROMPT_BLUE:=#97bedc}
: ${KURO_PROMPT_MUTED:=#888888}
: ${KURO_PROMPT_GREEN:=#94b979}
: ${KURO_PROMPT_YELLOW:=#ffba7b}
: ${KURO_PROMPT_MAGENTA:=#e1c0fa}
: ${KURO_PROMPT_RULE:=#333333}

setopt prompt_subst
autoload -Uz add-zsh-hook vcs_info
zstyle ':vcs_info:*' enable git
zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' check-for-staged-changes true
zstyle ':vcs_info:git:*' stagedstr '●'
zstyle ':vcs_info:git:*' unstagedstr '*'

: ${KURO_PROMPT_GREEN:=#94b979}
: ${KURO_PROMPT_YELLOW:=#ffba7b}
function afmagic_dashes() { print -n -- "${COLUMNS:-80}"; }

function _kuro_af_git_styles() {
  local hex="${KURO_PROMPT_BLUE#\#}"
  [[ "$hex" == [0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F] ]] || hex=97bedc
  local r=$(( 16#${hex[1,2]} )) g=$(( 16#${hex[3,4]} )) b=$(( 16#${hex[5,6]} ))
  local blue_ansi reset_ansi blue reset
  printf -v blue_ansi '\e[1;38;2;%d;%d;%dm' "$r" "$g" "$b"
  reset_ansi=$'\e[0m'
  blue="%{${blue_ansi}%}"
  reset="%{${reset_ansi}%}"
  zstyle ':vcs_info:git:*' formats " (${blue}%b${reset}%c%u)"
  zstyle ':vcs_info:git:*' actionformats " (${blue}%b${reset}|%a%c%u)"
}

function _kuro_af_precmd() {
  [[ -r "$HOME/.cache/kuro/zsh-colors.zsh" ]] && source "$HOME/.cache/kuro/zsh-colors.zsh"
  _kuro_af_git_styles
  vcs_info

  local box="${DISTROBOX_NAME:-}"
  local kind=""
  if [[ -n "$box" ]]; then
    kind="distrobox"
  elif [[ -n "${CONTAINER_ID:-}" || -n "${CONTAINER_NAME:-}" ]]; then
    box="${CONTAINER_NAME:-${CONTAINER_ID[1,12]}}"
    kind="container"
  elif [[ -f /.dockerenv ]]; then
    box="docker"
    kind="container"
  elif [[ -f /run/.containerenv ]]; then
    box="podman"
    kind="container"
  elif [[ -n "${container:-}" ]]; then
    box="$container"
    kind="container"
  fi

  if [[ -n "$box" ]]; then
    KURO_CONTAINER_SEGMENT=" %F{$KURO_PROMPT_HOT}[${kind}:${box}]%f"
  else
    KURO_CONTAINER_SEGMENT=""
  fi

  local venv="${CONDA_DEFAULT_ENV:-}"
  [[ -n "${VIRTUAL_ENV:-}" ]] && venv="${VIRTUAL_ENV:t}"
  if [[ -n "$venv" ]]; then
    KURO_VENV_SEGMENT=" %F{$KURO_PROMPT_MAGENTA}(${venv})%f"
  else
    KURO_VENV_SEGMENT=""
  fi
}

add-zsh-hook precmd _kuro_af_precmd

PROMPT='%F{$KURO_PROMPT_RULE}${(l.$(afmagic_dashes)..-.)}%f
%F{$KURO_PROMPT_GREEN}%~%f${vcs_info_msg_0_} %F{$KURO_PROMPT_ACCENT}%(!.#.»)%f '
RPROMPT='%(?..%F{$KURO_PROMPT_HOT}%? ↵%f)${KURO_VENV_SEGMENT}${KURO_CONTAINER_SEGMENT} %F{$KURO_PROMPT_MUTED}%n@%m%f'
PS2='%F{$KURO_PROMPT_HOT}↳%f '
