# ==========================================
#        CONFIGURATION ZSH
# ==========================================

# --- Raccourcis clavier basiques ---
bindkey -e

# --- Historique ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt appendhistory

# --- Système d'autocomplétion (Touche TAB) ---
autoload -Uz compinit
compinit
zstyle ':completion:*' menu select

# --- Plugins ---
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# --- Couleurs de frappe (Syntax Highlighting) ---
ZSH_HIGHLIGHT_STYLES[command]='fg=#6B8F68,bold'
ZSH_HIGHLIGHT_STYLES[unknown-token]='fg=#C2293F,bold'
ZSH_HIGHLIGHT_STYLES[default]='fg=#E2D9E0'

# --- Initialisation de Starship ---
eval "$(starship init zsh)"

# ==========================================
#     TITRE INTELLIGENT (DOSSIER / GIT)
# ==========================================
LAST_PRINTED_DIR=""

# Fonction qui s'exécute juste avant d'afficher la flèche rouge
header_precmd() {
    # Si on est dans un NOUVEAU dossier (ou qu'on vient d'ouvrir le terminal)
    if [[ "$PWD" != "$LAST_PRINTED_DIR" ]]; then
        # On saute une ligne pour aérer (sauf à la toute première ouverture)
        [[ -n "$LAST_PRINTED_DIR" ]] && echo ""
        
        # On récupère le design depuis Starship et on l'affiche
        local dir="$(starship module directory)"
        local git="$(starship module git_branch)"
        printf "%s%s\n" "$dir" "$git"
        
        # On mémorise qu'on a affiché ce dossier
        LAST_PRINTED_DIR="$PWD"
    fi
}
autoload -Uz add-zsh-hook
add-zsh-hook precmd header_precmd

# --- Raccourci personnalisé : Ctrl + T ---
ctrl_t_clear() {
    # 1. On vide l'écran avec la vraie commande système brute
    command clear
    
    # 2. On récupère et on réaffiche le titre jaune et cyan
    local dir="$(starship module directory)"
    local git="$(starship module git_branch)"
    printf "%s%s\n" "$dir" "$git"
    
    # 3. On redessine la flèche rouge en dessous
    zle reset-prompt
}
zle -N ctrl_t_clear
bindkey '^T' ctrl_t_clear

# --- Remplacement de la commande 'clear' classique ---
clear() {
    # 1. On vide l'écran
    command clear

    # 2. On récupère et on réaffiche le titre jaune et cyan
    local dir="$(starship module directory)"
    local git="$(starship module git_branch)"
    printf "%s%s\n" "$dir" "$git"
}
