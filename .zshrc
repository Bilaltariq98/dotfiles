# =============================================================================
# Bilal's .zshrc — minimal, fast (~50ms target)
# Setup: https://github.com/bilal/.zsh-setup (see README.md)
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

# WHY: zsh's default WORDCHARS includes / and other symbols, so Ctrl+Arrow
# and Ctrl+Backspace treat ~/Documents/personal/Github as ONE word.
# Removing / - . makes word boundaries stop at path separators, hyphens,
# and dots — matching how text editors behave.
# Default WORDCHARS: *?_-.[]~=/&;!#$%^(){}<>
WORDCHARS='*?_[]~=&;!#$%^(){}<>'

# WHY: Ctrl+Backspace doesn't send a consistent signal across terminals.
# Ghostty sends \x17 via keybind config, but other terminals (Zed, VS Code,
# iTerm) may send different sequences. Binding all known variants here
# makes backward-kill-word work everywhere, not just in Ghostty.
bindkey '^H'    backward-kill-word   # Ctrl-Backspace (some terminals)
bindkey '^[[3;5~' kill-word          # Ctrl-Delete (forward kill word)

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
# Shift-select on the command line (like a text editor)
# ---------------------------------------------------------------------------
# WHY: zsh doesn't support Shift+Arrow text selection out of the box.
#      The old zsh-autocomplete plugin provided this, but we removed it
#      to save ~6ms startup. This reimplements just the shift-select part.
#
# HOW: Uses zsh's REGION_ACTIVE and set-mark-command (ZLE visual mode).
#      On first shift+arrow press, a mark is set at the cursor position.
#      Subsequent shift+arrow extends the selection. Unmodified arrow
#      keys clear the selection. Delete/Backspace removes selected text.
#
# REQUIRES: Terminal must NOT intercept Shift+Arrow keys.
#      Ghostty config unbinds shift+arrow from adjust_selection.
#      See: ~/Library/Application Support/com.mitchellh.ghostty/config
#
# REF: https://zsh.sourceforge.io/Doc/Release/Zsh-Line-Editor.html
#      CSI codes: ;2=Shift ;4=Shift+Alt ;6=Ctrl+Shift
# ---------------------------------------------------------------------------
shift-select() {
  ((REGION_ACTIVE)) || zle set-mark-command
  zle $1
}
for cmd in forward-char backward-char forward-word backward-word \
           beginning-of-line end-of-line; do
  eval "shift-select-$cmd() { shift-select $cmd; }"
  zle -N shift-select-$cmd
done
bindkey '^[[1;2C' shift-select-forward-char       # Shift-Right
bindkey '^[[1;2D' shift-select-backward-char      # Shift-Left
bindkey '^[[1;6C' shift-select-forward-word       # Ctrl-Shift-Right
bindkey '^[[1;6D' shift-select-backward-word      # Ctrl-Shift-Left
bindkey '^[[1;4C' shift-select-forward-word       # Shift-Option-Right (macOS word select)
bindkey '^[[1;4D' shift-select-backward-word      # Shift-Option-Left  (macOS word select)
bindkey '^[[1;2H' shift-select-beginning-of-line  # Shift-Home
bindkey '^[[1;2F' shift-select-end-of-line        # Shift-End

# Deactivate selection on unmodified movement (pressing arrow without shift clears highlight)
deselect() { REGION_ACTIVE=0; zle $1; }
for cmd in forward-char backward-char; do
  eval "deselect-$cmd() { deselect $cmd; }"
  zle -N deselect-$cmd
done
bindkey '^[[C' deselect-forward-char   # Right (clears selection)
bindkey '^[[D' deselect-backward-char  # Left (clears selection)

# Delete/overwrite selected region (typing or Delete key replaces selection)
delete-region-or-char() {
  if ((REGION_ACTIVE)); then
    zle kill-region
  else
    zle delete-char
  fi
}
zle -N delete-region-or-char
bindkey '^[[3~' delete-region-or-char  # Delete key
bindkey '^?' backward-delete-char      # Backspace

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

_nvm_lazy_load() {
  unfunction nvm node npm npx 2>/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

  # Auto-select default Node if an alias exists; otherwise respect .nvmrc.
  if command -v nvm >/dev/null 2>&1; then
    if nvm alias default >/dev/null 2>&1; then
      nvm use --silent default >/dev/null 2>&1
    elif [ -f .nvmrc ]; then
      nvm use --silent >/dev/null 2>&1
    fi
  fi
}

nvm() {
  _nvm_lazy_load
  nvm "$@"
}

node() {
  _nvm_lazy_load
  node "$@"
}

npm() {
  _nvm_lazy_load
  npm "$@"
}

npx() {
  _nvm_lazy_load
  npx "$@"
}

# ---------------------------------------------------------------------------
# Lazy-load: conda (saves ~355ms)
# ---------------------------------------------------------------------------
conda() {
  unfunction conda 2>/dev/null
  __conda_setup="$("$HOME/miniconda/bin/conda" 'shell.zsh' 'hook' 2>/dev/null)"
  if [ $? -eq 0 ]; then
    eval "$__conda_setup"
  else
    if [ -f "$HOME/miniconda/etc/profile.d/conda.sh" ]; then
      . "$HOME/miniconda/etc/profile.d/conda.sh"
    else
      export PATH="$HOME/miniconda/bin:$PATH"
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
# WHY these settings: Our custom shift-select widgets (deselect-forward-char etc.)
# replace the default forward-char on Right arrow. zsh-autosuggestions only
# recognises widgets in its accept list, so we add ours. Without this,
# Right arrow stops accepting the grey ghost suggestion.
ZSH_AUTOSUGGEST_ACCEPT_WIDGETS=(forward-char end-of-line deselect-forward-char)
ZSH_AUTOSUGGEST_PARTIAL_ACCEPT_WIDGETS=(forward-word deselect-forward-word)
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
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
alias su='TERM=xterm-256color command su'  # other users lack ghostty terminfo
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
