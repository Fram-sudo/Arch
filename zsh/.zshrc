# ==========================================
#        CONFIGURATION ZSH
# ==========================================

# --- Raccourcis clavier basiques (mode Emacs) ---
bindkey -e

# --- Historique ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# --- Système d'autocomplétion (Touche TAB) ---
# Active le moteur de base de Zsh
autoload -Uz compinit
compinit

# --- Menu interactif pour l'autocomplétion ---
# Affiche un menu navigable avec les flèches ou TAB quand il y a plusieurs choix
zstyle ':completion:*' menu select

# --- Plugins ---
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Couleurs de frappe (Syntax Highlighting) ---
# Commande qui existe (Ton vert clair)
ZSH_HIGHLIGHT_STYLES[command]='fg=#6B8F68,bold'
# Commande qui n'existe pas (Ton rouge clair)
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#C2293F,bold'
# Texte par défaut / arguments (Ton blanc grisé/rosé)
ZSH_HIGHLIGHT_STYLES[default]='fg=#E2D9E0'

# --- Initialisation du prompt Starship ---
eval "$(starship init zsh)"
