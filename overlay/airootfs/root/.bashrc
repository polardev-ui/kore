#
# Kore OS - Root .bashrc
#

PS1='\[\e[1;36m\][kore@\h \W]\$ \[\e[0m\]'
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias grep='grep --color=auto'
alias neofetch='neofetch --ascii'

export EDITOR=nano
export VISUAL=nano
export BROWSER=firefox

# Welcome message
if [ -f /usr/local/bin/kore-welcome ] && [ -z "${KORE_WELCOME_SHOWN:-}" ]; then
    export KORE_WELCOME_SHOWN=1
    /usr/local/bin/kore-welcome
fi
