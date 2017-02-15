# ~/.bashrc or /etc/bash.bashrc
BRED='\[\e[1;31m\]'
WHITE='\[\e[0;37m\]'

PS1="\u@${BRED}\H${WHITE}:\w\$ "



# No RM
alias sudo='sudo '
alias rm='echo "You are in production env - rm is disabled, use trash or /bin/rm instead."'

