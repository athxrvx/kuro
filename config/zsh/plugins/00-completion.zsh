# Completion setup with a local completion directory and persistent cache.
[[ -d "$ZSH_CONFIG_HOME/completions" ]] && fpath=("$ZSH_CONFIG_HOME/completions" $fpath)
autoload -Uz compinit
[[ -d "${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}" ]] || mkdir -p "${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}" 2>/dev/null
compinit -C -d "${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}/zcompdump-${ZSH_VERSION}"

setopt AUTO_MENU
setopt COMPLETE_IN_WORD
setopt ALWAYS_TO_END
setopt AUTO_LIST
setopt NO_BEEP
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '%F{cyan}── %d ──%f'
zstyle ':completion:*' squeeze-slashes true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${ZSH_CACHE_DIR:-$HOME/.config/zsh/cache}/completion"
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
