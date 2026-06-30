# ┌─────────────────────────────────────────────────────────────────┐
# │ Environment Variables & PATH                                     │
# └─────────────────────────────────────────────────────────────────┘

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

# --- GPG TTY ---------------------------------------------------------
export GPG_TTY="${GPG_TTY:-$(tty 2>/dev/null || echo '')}"
