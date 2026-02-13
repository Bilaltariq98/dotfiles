# Zsh Setup

Minimal, fast zsh config (~60ms startup). Replaces Oh My Zsh + Powerlevel10k.

## What's in the stack

| Tool | Purpose | Install |
|------|---------|---------|
| **Starship** | Prompt with git status, Nerd Font icons | `brew install starship` |
| **eza** | Modern `ls` with icons and colors | `brew install eza` |
| **atuin** | Shell history — single source of truth | `brew install atuin` |
| **fzf** | Fuzzy file picker — `Ctrl-T`, completion | `brew install fzf` |
| **zsh-autosuggestions** | Fish-like inline suggestions | git clone (see below) |
| **fast-syntax-highlighting** | Command syntax coloring | git clone (see below) |

## Fresh machine setup

```bash
# 1. Install Homebrew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# 2. Install core tools
brew install starship eza fzf atuin

# 3. Create plugin directory
mkdir -p ~/.oh-my-zsh/custom/plugins

# 4. Install plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting ~/.oh-my-zsh/custom/plugins/fast-syntax-highlighting

# 5. Copy config files
cp .zshrc ~/.zshrc
cp .zprofile ~/.zprofile
cp .zshenv ~/.zshenv
mkdir -p ~/.config
cp starship.toml ~/.config/starship.toml

# 6. Fix Homebrew completion permissions (prevents compaudit warning)
chmod 755 /opt/homebrew/share/zsh/site-functions /opt/homebrew/share/zsh

# 7. IMPORTANT: scrub secrets from zsh_history BEFORE importing into atuin
#    (atuin import does not apply secrets_filter — it imports everything)
brew install trufflehog
trufflehog filesystem ~/.zsh_history          # review what's there
# manually remove flagged lines, then:
atuin import auto

# 8. Restart shell
exec zsh
```

## How history works

Atuin is the **single source of truth** for shell history. Zsh does NOT write to `~/.zsh_history`.

```
You type a command
       |
       +---> zsh keeps it in memory (HISTSIZE=10000, session only)
       |
       +---> atuin captures and persists to SQLite DB
             (~/.local/share/atuin/history.db)
```

- `SAVEHIST=0` — zsh writes nothing to disk
- `HISTSIZE=10000` — in-memory fallback if atuin ever breaks
- Atuin handles persistence, search, sync, and deduplication
- `~/.zsh_history` can be safely deleted once atuin has imported it

## Keybindings

| Shortcut | Tool | Action |
|----------|------|--------|
| `Ctrl-R` | atuin | Fuzzy search full history (time, duration, exit code, directory) |
| `Ctrl-T` | fzf | Fuzzy file picker (insert file path at cursor) |
| `Alt-C` | fzf | Fuzzy cd into subdirectory |
| `Up/Down` | zsh | Previous/next in-memory session history |
| `Tab` | zsh | Completion menu |
| `Right arrow` | zsh-autosuggestions | Accept inline suggestion |

## Handy commands

### atuin

```bash
atuin search "pattern"                        # interactive search for a pattern
atuin search --cmd-only "git push"            # non-interactive, command text only
atuin search --delete "secret-pattern"        # delete matching entries
atuin history list                            # list all history
atuin history list --format "{time} {command}" # custom format
atuin stats                                   # most-used commands
atuin import auto                             # import from zsh/bash/fish history
atuin history prune                           # prune based on history_filter rules
atuin history dedup                           # remove duplicate entries
```

Query atuin's SQLite directly (useful outside interactive shells):

```bash
# Search by pattern with timestamps
sqlite3 ~/.local/share/atuin/history.db \
  "SELECT datetime(timestamp/1000000000, 'unixepoch', 'localtime'), command
   FROM history WHERE command LIKE '%PATTERN%' ORDER BY timestamp;"

# Count total commands
sqlite3 ~/.local/share/atuin/history.db "SELECT COUNT(*) FROM history;"

# Most used commands
sqlite3 ~/.local/share/atuin/history.db \
  "SELECT command, COUNT(*) as n FROM history GROUP BY command ORDER BY n DESC LIMIT 20;"
```

### eza

```bash
eza --icons                                   # ls with icons (aliased to ls)
eza --icons -la --sort=oldest                 # ls -latr equivalent
eza --icons -la --sort=newest                 # newest first
eza --icons -la --sort=size                   # largest first
eza --icons --tree --level=2                  # tree view (aliased to lt)
eza --icons -la --git                         # show git status per file
eza --icons --group-directories-first -la     # dirs first
command ls -latr                              # bypass alias, use real ls
```

### starship

```bash
starship explain                              # show what each prompt segment means
starship timings                              # show how long each module takes
starship config                               # open config in $EDITOR
starship preset no-nerd-font -o ~/.config/starship.toml  # switch to non-nerd-font preset
```

### fzf

```bash
# Keybindings (in terminal)
Ctrl-T                                        # fuzzy file picker
Alt-C                                         # fuzzy cd
**<Tab>                                       # fuzzy completion (e.g. cd **<Tab>)

# Piping
cat file.txt | fzf                            # fuzzy filter lines
git branch | fzf                              # pick a branch
git log --oneline | fzf                       # pick a commit
ps aux | fzf                                  # pick a process
```

### trufflehog (secret scanning)

```bash
trufflehog filesystem ~/.local/share/atuin/   # scan atuin DB for secrets
trufflehog filesystem .                       # scan current directory
trufflehog filesystem . --results=verified    # only show confirmed-live secrets
trufflehog filesystem . --json                # JSON output for scripting
trufflehog git file://.                       # scan git repo history
```

### noseyparker (secret scanning)

```bash
noseyparker scan -d /tmp/np ~/.local/share/atuin/ && noseyparker report -d /tmp/np
noseyparker scan -d /tmp/np . && noseyparker report -d /tmp/np  # scan current dir
```

## Aliases defined in .zshrc

| Alias | Expands to |
|-------|------------|
| `ls` | `eza --icons` |
| `ll` | `eza --icons -la` |
| `la` | `eza --icons -a` |
| `lt` | `eza --icons --tree --level=2` |
| `..` | `cd ..` |
| `...` | `cd ../..` |

## Starship prompt symbols

```
plumb on  main !1?2  v24.13.0 took 3s
❯
```

| Symbol | Meaning |
|--------|---------|
| ` main` | Git branch |
| `!N` | N modified files (unstaged) |
| `?N` | N untracked files |
| `+N` | N staged files |
| `⇡N` | N commits ahead of remote |
| `⇣N` | N commits behind remote |
| ` vX.Y.Z` | Node.js version (shown when package.json present) |
| `took Xs` | Command duration (only shown if > 2s) |

Config: `~/.config/starship.toml`

## Lazy-loaded tools

These don't load at startup. They initialize on first use:

- **nvm** — triggers on `nvm`, `node`, `npm`, or `npx`
- **conda** — triggers on `conda`
- **rbenv** — triggers on `rbenv`

First invocation has a small delay (~200ms for nvm, ~350ms for conda). Subsequent calls are instant.

## Auditing history for secrets

Since atuin is the only persistent history store, scan its database:

```bash
# Scan atuin's SQLite database with trufflehog
trufflehog filesystem ~/.local/share/atuin/

# Or with noseyparker
noseyparker scan -d /tmp/np ~/.local/share/atuin/ && noseyparker report -d /tmp/np
```

Prevention (already configured in `~/.config/atuin/config.toml`):

- `secrets_filter = true` — built-in filter for AWS, GitHub PATs, Slack, Stripe
- `history_filter` — custom regexes for Anthropic, OpenAI, SendGrid, Twilio, OAuth secrets, sensitive exports
- Space prefix — start any command with a space (` export KEY=...`) and neither zsh nor atuin will record it

## Key files

| File | Purpose |
|------|---------|
| `~/.zshrc` | Main shell config |
| `~/.zprofile` | Login shell (brew shellenv, OrbStack) |
| `~/.zshenv` | Env vars loaded for all shells (cargo) |
| `~/.config/starship.toml` | Prompt configuration |
| `~/.config/atuin/config.toml` | Atuin config (filters, search mode, sync) |
| `~/.local/share/atuin/history.db` | Atuin history database (SQLite) |
| `~/.zsh-setup/` | This directory — portable config + docs |
| `~/.zsh-backup-20260213-122127/` | Pre-optimization backup of original dotfiles |

## Roadmap: secret leak prevention

See `PLAN.md` for full implementation details.

### What's done

- [x] Atuin is the only persistent history store (`SAVEHIST=0`)
- [x] `secrets_filter = true` in atuin config (catches AWS, GitHub PATs, Slack, Stripe)
- [x] Custom `history_filter` regexes for Anthropic, OpenAI, SendGrid, Twilio, OAuth, sensitive exports
- [x] `HIST_IGNORE_SPACE` — prefix any command with a space to hide it from both zsh and atuin
- [x] Manually scrubbed all known secrets from `~/.zsh_history` and atuin DB

### What's planned

- [ ] **`zsh-scrub-secrets` script** — automated scan + review + purge workflow:
  1. Runs `trufflehog filesystem` against atuin's SQLite DB
  2. Displays findings in a review table (redacted values, detector name, verified status)
  3. User selects which entries to delete
  4. Purges from atuin via `atuin search --delete` or direct SQLite
  5. Supports `--dry-run` for preview without changes
- [ ] **Pre-import hook** — scrub `~/.zsh_history` before `atuin import auto` on new machines
- [ ] **Periodic scan** — optional cron/launchd job to run trufflehog against atuin DB weekly

### Quick manual workflow (until the script exists)

```bash
# 1. Scan
trufflehog filesystem ~/.local/share/atuin/

# 2. Find the offending command in atuin
sqlite3 ~/.local/share/atuin/history.db \
  "SELECT datetime(timestamp/1000000000, 'unixepoch', 'localtime'), command
   FROM history WHERE command LIKE '%PATTERN%';"

# 3. Delete from atuin (in an interactive shell)
atuin search --delete "pattern"

# 4. Or delete via SQLite directly (works anywhere)
sqlite3 ~/.local/share/atuin/history.db \
  "DELETE FROM history WHERE command LIKE '%PATTERN%';"
```

## Optional upgrades

- **zoxide** (`brew install zoxide`) — smarter `cd` that learns your frequent directories. Add `eval "$(zoxide init zsh)"` to .zshrc.
