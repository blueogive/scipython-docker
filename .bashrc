# Aliases for enhanced directory listing using eza if available, otherwise
# fallback to ls
if [ -x /usr/bin/eza ]; then
    alias ls='eza --icons auto'
    alias dir='eza -l --git --icons auto --header'
    alias vdir='eza -l --loc=both --git --icons auto --header'
    alias ll='eza --git -alF --loc=both --header'
    alias la='eza --git --header -Al'
    alias l='eza --git --header -al'
    alias lcode='eza --recurse --code --header --icons auto auto'
    alias ld='eza -l --only-dirs --tree --header --recurse'
    alias lt='eza -l --tree --level 3 --header --recurse'
else
    alias ls='ls --color=auto'
    alias ll='ls -alF'
    alias la='ls -A'
    alias l='ls -CF'
fi
