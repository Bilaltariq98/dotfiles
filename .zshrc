# =============================================================================
# Bilal's .zshrc — minimal, fast (~50ms target)
# Backup: ~/.zsh-backup-20260213-122127
# =============================================================================

# ---------------------------------------------------------------------------
# History — atuin is the single source of truth for persistence
# zsh keeps in-memory history only (fallback if atuin breaks)
# ---------------------------------------------------------------------------
HISTSIZE=10000                # in-memory session history
SAVEHIST=0                    # don't write to disk — atuin handles persistence
setopt HIST_IGNORE_SPACE      # space-prefixed commands hidden from both zsh + atuin
setopt HIST_VERIFY            # expand !! before running

# ---------------------------------------------------------------------------
# Core options
# ---------------------------------------------------------------------------
setopt AUTO_CD                # cd by just typing dir name
setopt INTERACTIVE_COMMENTS   # allow # comments in interactive shell
setopt NO_BEEP

# ---------------------------------------------------------------------------
# Completion (lightweight — no OMZ compinit bloat)
# ---------------------------------------------------------------------------
zmodload zsh/complist          # enables arrow-key menu navigation
autoload -Uz compinit
# Only regenerate .zcompdump once a day
if [[ -n ~/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C  # use cached dump
fi

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"

# Navigate completion menu with hjkl in addition to arrows
bindkey -M menuselect 'h' vi-backward-char
bindkey -M menuselect 'j' vi-down-line-or-history
bindkey -M menuselect 'k' vi-up-line-or-history
bindkey -M menuselect 'l' vi-forward-char

# ---------------------------------------------------------------------------
# PATH additions (fast — no evals, no subshells)
# ---------------------------------------------------------------------------
typeset -U path  # deduplicate PATH

path=(
  $HOME/.local/bin
  $HOME/.cargo/bin
  $HOME/.bun/bin
  $HOME/Library/pnpm
  $HOME/.fly/bin
  $HOME/go/bin
  $HOME/.opencode/bin
  $HOME/.orbstack/bin
  $HOME/.safe-chain/bin
  $path
)

export BUN_INSTALL="$HOME/.bun"
export PNPM_HOME="$HOME/Library/pnpm"
export FLYCTL_INSTALL="$HOME/.fly"
export REVIEW_BASE="main"

# OrbStack completions
[[ -d /Applications/OrbStack.app/Contents/Resources/completions/zsh ]] && \
  fpath+=/Applications/OrbStack.app/Contents/Resources/completions/zsh

# ---------------------------------------------------------------------------
# Lazy-load: nvm (saves ~200ms)
# ---------------------------------------------------------------------------
export NVM_DIR="$HOME/.nvm"

nvm() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  nvm "$@"
}

node() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  node "$@"
}

npm() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npm "$@"
}

npx() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
  npx "$@"
}

# ---------------------------------------------------------------------------
# Lazy-load: conda (saves ~355ms)
# ---------------------------------------------------------------------------
conda() {
  unfunction conda 2>/dev/null
  __conda_setup="$('/Users/bilal/miniconda/bin/conda' 'shell.zsh' 'hook' 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "/Users/bilal/miniconda/etc/profile.d/conda.sh" ]; then
      . "/Users/bilal/miniconda/etc/profile.d/conda.sh"
    else
      export PATH="/Users/bilal/miniconda/bin:$PATH"
    fi
  fi
  unset __conda_setup
  conda "$@"
}

# ---------------------------------------------------------------------------
# Lazy-load: rbenv (saves ~30ms)
# ---------------------------------------------------------------------------
rbenv() {
  unfunction rbenv 2>/dev/null
  eval "$(command rbenv init - --no-rehash zsh)"
  rbenv "$@"
}

# ---------------------------------------------------------------------------
# Plugins (direct source — no OMZ overhead)
# ---------------------------------------------------------------------------
# zsh-autosuggestions
[ -f ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh

# fast-syntax-highlighting (faster than zsh-syntax-highlighting)
[ -f ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh ] && \
  source ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh

# Atuin — shell history (Ctrl-R for search, Up arrow for filtered history)
eval "$(atuin init zsh --disable-up-arrow)"

# fzf — file picker (Ctrl-T) and completion; Ctrl-R left to atuin
[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ] && \
  source /opt/homebrew/opt/fzf/shell/completion.zsh
[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ] && \
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
bindkey '^R' _atuin_search_widget  # ensure atuin keeps Ctrl-R after fzf loads

# ---------------------------------------------------------------------------
# Aliases
# ---------------------------------------------------------------------------
alias ls='eza --icons'
alias ll='eza --icons -la'
alias la='eza --icons -a'
alias lt='eza --icons --tree --level=2'
alias cat='bat --paging=never'
alias catp='bat'                              # cat with pager
alias ..='cd ..'
alias ...='cd ../..'

# ---------------------------------------------------------------------------
# Safe-chain (wraps npm/bun/pip for supply chain protection)
# ---------------------------------------------------------------------------
source ~/.safe-chain/scripts/init-posix.sh 2>/dev/null

# ---------------------------------------------------------------------------
# Bun completions
# ---------------------------------------------------------------------------
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# ---------------------------------------------------------------------------
# zoxide (smarter cd — use 'z' instead of 'cd')
# ---------------------------------------------------------------------------
eval "$(zoxide init zsh)"

# ---------------------------------------------------------------------------
# Starship prompt (init last — fast, ~5ms)
# ---------------------------------------------------------------------------
eval "$(starship init zsh)"
