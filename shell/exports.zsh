# ┌─────────────────────────────────────────────────────────────────┐
# │ Environment Variables & PATH                                     │
# └─────────────────────────────────────────────────────────────────┘

# --- Path deduplication helper (needed before other sources) --------
dedup_path() {
  local var_name="$1"
  local entry="$2"
  local current="${(P)var_name:-}"
  current=":${current}:"
  current="${current//:$entry:/:}"
  current="${current#:}"
  current="${current%:}"
  if [[ -z "$current" ]]; then
    printf -v "$var_name" '%s' "$entry"
  else
    printf -v "$var_name" '%s' "$entry:$current"
  fi
}

# --- Editors & Tools -------------------------------------------------
export EDITOR="${EDITOR:-code}"
export VISUAL="${VISUAL:-code}"
export PAGER="${PAGER:-less}"

# --- Rust ------------------------------------------------------------
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# --- NVM / Node (lazy-loaded) ----------------------------------------
export NVM_DIR="$HOME/.nvm"
_nvm_lazy_load() {
  unset -f nvm node npm npx pnpm
  [[ -s "$NVM_DIR/nvm.sh" ]] && \. "$NVM_DIR/nvm.sh"
}
nvm() { _nvm_lazy_load; nvm "$@"; }
node() { _nvm_lazy_load; node "$@"; }
npm() { _nvm_lazy_load; npm "$@"; }
npx() { _nvm_lazy_load; npx "$@"; }
pnpm() { _nvm_lazy_load; pnpm "$@"; }

# --- Bun (lazy-loaded) -----------------------------------------------
export BUN_INSTALL="$HOME/.bun"
_bun_lazy_load() {
  unset -f bun
  [[ -s "$BUN_INSTALL/_bun" ]] && source "$BUN_INSTALL/_bun"
}
bun() { _bun_lazy_load; bun "$@"; }

# --- Solana ----------------------------------------------------------
export SOLANA_BIN="$HOME/.local/share/solana/install/active_release/bin"
[[ -d "$SOLANA_BIN" ]] && dedup_path PATH "$SOLANA_BIN"

# --- Foundry ---------------------------------------------------------
[[ -d "$HOME/.foundry/bin" ]] && dedup_path PATH "$HOME/.foundry/bin"

# --- PNPM ------------------------------------------------------------
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) dedup_path PATH "$PNPM_HOME" ;;
esac

# --- User local/bin --------------------------------------------------
dedup_path PATH "$HOME/.local/bin"
dedup_path PATH "$HOME/bin"

# --- LM Studio (if installed) ----------------------------------------
[[ -d "$HOME/.lmstudio/bin" ]] && dedup_path PATH "$HOME/.lmstudio/bin"

# --- SDKMAN (if installed) -------------------------------------------
[[ -s "$HOME/.sdkman/bin/sdkman-init.sh" ]] && source "$HOME/.sdkman/bin/sdkman-init.sh"

# --- Python / pyenv (lazy-loaded) ------------------------------------
export PYENV_ROOT="$HOME/.pyenv"
_pyenv_lazy_load() {
  unset -f pyenv python pip
  [[ -d "$PYENV_ROOT/bin" ]] && dedup_path PATH "$PYENV_ROOT/bin"
  eval "$(pyenv init - 2>/dev/null)" 2>/dev/null || true
}
pyenv() { _pyenv_lazy_load; pyenv "$@"; }
python() { _pyenv_lazy_load; python "$@"; }
pip() { _pyenv_lazy_load; pip "$@"; }

# --- Go (lazy-loaded) -------------------------------------------------
export GOPATH="$HOME/go"
_go_lazy_load() {
  unset -f go
  dedup_path PATH "/usr/local/go/bin"
  dedup_path PATH "$GOPATH/bin"
}
go() { _go_lazy_load; go "$@"; }

# --- AWS CLI (lazy-loaded) -------------------------------------------
_aws_lazy_load() { unset -f aws; }
aws() { command aws "$@"; }

# --- gcloud (lazy-loaded) --------------------------------------------
_gcloud_lazy_load() { unset -f gcloud; }
gcloud() { command gcloud "$@"; }

# --- Kubernetes ---------------------------------------
[[ -f "$HOME/.krew/bin" ]] && dedup_path PATH "$HOME/.krew/bin"

# --- GPG TTY ---------------------------------------------------------
export GPG_TTY="${GPG_TTY:-$(tty 2>/dev/null || echo '')}"
