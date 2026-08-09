# dotfiles-chezmoi

Managed by [chezmoi](https://www.chezmoi.io/).

## Setup (new machine)

```bash
# Install chezmoi and apply dotfiles
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply stevejkang/dotfiles-chezmoi
```

## Daily usage

```bash
# Add a file to chezmoi
chezmoi add ~/.config/tmux/tmux.conf.local

# Edit a managed file (opens in $EDITOR, auto-applies on save)
chezmoi edit ~/.config/tmux/tmux.conf.local

# Preview changes before applying
chezmoi diff

# Apply changes from source to home
chezmoi apply

# Pull latest from remote and apply
chezmoi update
```

## Secrets (1Password)

Requires [1Password CLI](https://developer.1password.com/docs/cli/). Configure in `~/.config/chezmoi/chezmoi.toml`:

```toml
[onepassword]
  command = "op"
```

### Template: inject secret values into config files

When a config file contains partial secrets. Only placeholders are stored in the repo; actual values are fetched from 1Password at `chezmoi apply` time.

```bash
chezmoi add --template ~/.config/some-app/config.toml
```

```toml
# source: dot_config/some-app/config.toml.tmpl
[credential]
  token = "{{ onepasswordRead "op://Chezmoi/SomeApp/token" }}"
```

### Encrypt: store entire files encrypted

When an entire file is secret (e.g. SSH private keys, credentials.json). The file is stored age-encrypted in the repo and decrypted at `chezmoi apply` time using an age key stored in 1Password.

```bash
# 1. Generate age key and store in 1Password
age-keygen | op document create --title "age key" --vault Chezmoi -

# 2. Add age config to chezmoi.toml
#    encryption = "age"
#    [age]
#      identity = "{{ onepasswordDocument "age key" "Chezmoi" }}"
#      recipient = "age1..."  # public key from age-keygen output

# 3. Add a file as encrypted
chezmoi add --encrypt ~/.ssh/id_ed25519
# Stored as encrypted_private_dot_ssh/private_id_ed25519.age
```

### Naming convention (Chezmoi vault)

All chezmoi-related secrets live in the **Chezmoi** vault in 1Password.

| Type | Item title | Example reference |
|---|---|---|
| Age encryption key | `age key` | `op://Chezmoi/age key` (document) |
| Template secret | Application name (e.g. `WakaTime`) | `op://Chezmoi/WakaTime/api key` |

Rules:
- Item title = application or purpose name, **lowercase where possible**.
- Field name = what the config file calls it (e.g. `api key`, `token`, `secret`).
- One item per application. Multiple fields under the same item when an app needs several secrets.

## Git workflow

```bash
chezmoi cd                                      # cd into source directory
git add -A && git commit -m "..." && git push   # commit and push
exit                                            # back to previous directory
```

## What's managed

| File | Description | Encryption | Prerequisite |
|---|---|---|---|
| `~/.config/tmux/tmux.conf.local` | tmux config (oh-my-tmux + powerkit) | — | `tmux` `bash` ≥5.0 (brew), [gpakosz/.tmux](https://github.com/gpakosz/.tmux) (git clone), Nerd Font (cask) |
| `~/.gitignore-global` | Global gitignore | — | `git` (system-installed) |
| `~/.gitconfig` | Git configuration (GPG signing enabled) | — | `git` (system-installed), `gnupg` (brew) |
| `~/.ssh/config` | SSH client config | — | `ssh` (system-installed) |
| `~/.ssh/id_ed25519` | SSH private key | age | `ssh` (system-installed) |
| `~/.ssh/id_ed25519.pub` | SSH public key | — | `ssh` (system-installed) |
| `~/.hushlogin` | Suppress login message | — | system-installed |
| `~/.gnupg/common.conf` | GnuPG common config | — | `gnupg` (brew) |
| `~/.gnupg/gpg-agent.conf` | GPG agent config (pinentry) | — | `gnupg` `pinentry-mac` (brew) |
| `~/.gnupg/public-key-*.asc` | GPG public keys (armored export) | — | `gnupg` (brew) |
| `~/.gnupg/secret-key-*.asc` | GPG secret keys | age | `gnupg` (brew) |
| `~/.gnupg/trustdb.gpg` | GPG trust database | — | `gnupg` (brew) |
| `~/.config/karabiner/karabiner.json` | Karabiner-Elements key remapping | — | [Karabiner-Elements](https://karabiner-elements.pqrs.org/) (cask) |
| `~/.wakatime.cfg` | WakaTime config | template | [WakaTime](https://wakatime.com/) plugin installed |

## Scripts

| Script | Trigger | Description |
|---|---|---|
| `run_onchange_before_macos-defaults.sh` | content change | macOS system preferences (Dock, Finder, Keyboard, Lock Screen, etc.) |
| `run_onchange_after_import-gpg-keys.sh.tmpl` | GPG key file change | Import GPG public/secret keys |
| `run_onchange_after_ssh-add.sh.tmpl` | SSH key file change | Add SSH key to Apple Keychain |
