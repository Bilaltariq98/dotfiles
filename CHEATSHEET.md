# Terminal Tooling Cheatsheet

A guide to the modern CLI tools in this setup. Each replaces a slower, older default with something faster and more useful. All are written in Rust.

---

## zoxide — smarter cd

**Replaces:** `cd`
**Why:** Learns your most-used directories. Stop typing full paths.

```bash
z projects          # cd to most-visited dir matching "projects"
z san               # cd to ~/code/sanity-studio (or whatever matches)
z proj san          # cd to a dir matching both "proj" and "san"
zi                  # interactive picker with fzf
z -                 # go back to previous directory (like cd -)
```

**How it works:** Every time you `cd` somewhere, zoxide records it. Over time it builds a ranking of your most frequent + recent directories. `z` fuzzy-matches against that database.

**Muscle memory shift:**
- Old: `cd ~/code/my-long-project-name/src/components`
- New: `z comp` (gets you there if it's a frequent dir)

**Tip:** Keep using `cd` for one-off directories. Use `z` for places you go often. zoxide learns from both `cd` and `z`.

---

## bat — better cat

**Replaces:** `cat`
**Why:** Syntax highlighting, line numbers, git integration.

```bash
cat file.ts         # syntax-highlighted output (aliased to bat)
cat -n file.ts      # with line numbers (bat's default)
catp file.ts        # with a scrollable pager (alias for bat with pager)
bat file.ts         # explicit bat call
bat -l json         # force a language (when piping stdin)
bat --diff file.ts  # show git changes inline
bat -A file.ts      # show invisible characters (tabs, spaces, newlines)
bat --list-themes   # see available color themes
```

**Muscle memory shift:** None needed — `cat` is aliased to `bat`. It just looks better now.

**Tip:** When piping to other tools, bat auto-detects and becomes plain (no colors). To force plain: `bat --plain` or `command cat`.

---

## fd — better find

**Replaces:** `find`
**Why:** Simpler syntax, respects `.gitignore`, color output, 5x faster.

```bash
fd .json                    # find all .json files recursively
fd component src/           # find files matching "component" in src/
fd -e tsx                   # find by extension
fd -e tsx -x wc -l          # find .tsx files and count lines in each
fd -H .env                  # include hidden files (normally excluded)
fd -t d node_modules        # find only directories
fd -t f -s README           # find only files, case-sensitive
fd -E node_modules pattern  # exclude a directory
fd --changed-within 1d      # files changed in last day
```

**Muscle memory shift:**
- Old: `find . -name "*.json" -type f`
- New: `fd -e json`
- Old: `find . -name "*.ts" -not -path "*/node_modules/*"`
- New: `fd -e ts` (ignores node_modules via .gitignore automatically)

**Tip:** fd respects `.gitignore` by default. Use `-H` for hidden files, `-I` to ignore `.gitignore`.

---

## delta — better git diffs

**Replaces:** `git diff`'s default pager
**Why:** Syntax highlighting, line numbers, side-by-side view.

```bash
git diff                    # automatically uses delta now
git diff --staged           # staged changes, also through delta
git log -p                  # commit diffs with syntax highlighting
git show HEAD               # show last commit, beautifully
git diff main..feature      # branch comparison with side-by-side
```

**Muscle memory shift:** None — delta is configured as git's pager automatically. Every `git diff`, `git log -p`, `git show` just looks better.

**Navigation inside delta:**
- `n` / `N` — jump to next/previous file (delta navigate mode)
- `q` — quit
- `/pattern` — search
- Arrow keys or `j`/`k` — scroll

**Tip:** If side-by-side is too wide for your terminal, toggle it off:
```bash
git config --global delta.side-by-side false
```

---

## eza — better ls

**Replaces:** `ls`
**Why:** Icons, colors, git-aware, human-readable by default.

```bash
ls                          # eza with icons (aliased)
ll                          # long list (aliased to eza -la)
la                          # show hidden files (aliased to eza -a)
lt                          # tree view 2 levels deep (aliased)
eza -la --sort=oldest       # ls -latr equivalent
eza -la --sort=newest       # newest first
eza -la --sort=size         # by size
eza -la --git               # show git status per file
eza --group-directories-first -la  # directories first
command ls -latr            # bypass alias, use real ls
```

**Muscle memory shift:** `ls` flags are different in eza.
- Old: `ls -latr` → New: `eza -la --sort=oldest`
- Old: `ls -lS` → New: `eza -la --sort=size`

---

## fzf — fuzzy finder

**Not a replacement — a new superpower.** Fuzzy-search anything.

```bash
# Terminal keybindings
Ctrl-T                      # fuzzy file picker (inserts path at cursor)
Alt-C                       # fuzzy cd into any subdirectory
Ctrl-R                      # owned by atuin (not fzf)

# Fuzzy completion
cd **<Tab>                  # fuzzy-match directories
vim **<Tab>                 # fuzzy-match files
kill **<Tab>                # fuzzy-match processes
ssh **<Tab>                 # fuzzy-match hosts

# Piping
git branch | fzf            # pick a branch interactively
git log --oneline | fzf     # pick a commit
ps aux | fzf                # pick a process
```

**Tip:** fzf + bat preview is powerful:
```bash
fzf --preview 'bat --color=always {}'
```

---

## atuin — shell history

**Replaces:** zsh's built-in history (`~/.zsh_history`)
**Why:** SQLite-backed, searchable by directory/exit code/duration, optional sync.

```bash
# Interactive (in terminal)
Ctrl-R                      # full fuzzy history search

# CLI
atuin search "pattern"      # interactive search for a pattern
atuin search --cmd-only "git push"  # non-interactive, just commands
atuin search --delete "secret"      # delete entries matching pattern
atuin stats                 # your most-used commands
atuin history list          # dump all history
atuin history dedup         # remove duplicates
atuin import auto           # import from zsh/bash/fish
```

**Muscle memory shift:** `Ctrl-R` looks different now — it's a full-screen UI showing time, directory, duration, and exit code for each command.

---

## Starship — prompt

**Replaces:** Oh My Zsh themes / Powerlevel10k
**Why:** Fast (~5ms), cross-shell, Nerd Font icons, zero config needed.

```bash
starship explain            # what each prompt segment means right now
starship timings            # how long each module takes to render
starship config             # open config in $EDITOR
starship toggle nodejs      # hide/show the Node.js version
```

Config: `~/.config/starship.toml`

---

## Quick reference: what replaced what

| Old command | New command | Tool |
|-------------|-------------|------|
| `cd ~/long/path` | `z path` | zoxide |
| `cat file` | `cat file` (auto-highlighted) | bat |
| `find . -name "*.ts"` | `fd -e ts` | fd |
| `git diff` (ugly) | `git diff` (beautiful) | delta |
| `ls -la` | `ll` | eza |
| `find . -type d` | `fd -t d` | fd |
| `history \| grep pattern` | `Ctrl-R` then type | atuin |
| `grep -r pattern .` | `rg pattern` | ripgrep (already on most systems) |

---

## The philosophy

1. **Don't memorize — build muscle memory.** Use `z` instead of `cd` for a week. It becomes automatic.
2. **Aliases hide the complexity.** `ls`, `ll`, `cat` all just work — they're wired to the better tools.
3. **Everything is opt-in.** `command ls`, `command cat`, `command find` always give you the originals.
4. **Rust tools start instantly.** No Ruby/Python/Node startup tax. Every command here launches in <5ms.
