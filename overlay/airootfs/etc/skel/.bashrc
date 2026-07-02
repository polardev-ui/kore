#
# Kore OS - Default .bashrc
#

PS1='\[\e[1;36m\][kore@\h \W]\$ \[\e[0m\]'
alias ls='ls --color=auto'
alias ll='ls -la'
alias la='ls -A'
alias grep='grep --color=auto'

export EDITOR=nano
export VISUAL=nano
export BROWSER=firefox

# Welcome message (first run only)
if [ -f /usr/local/bin/kore-welcome ] && [ ! -f ~/.kore-welcome-shown ]; then
    touch ~/.kore-welcome-shown
    /usr/local/bin/kore-welcome
fi
