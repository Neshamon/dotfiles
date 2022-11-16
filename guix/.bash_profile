# Honor per-interactive-shell startup file
if [ -f ~/.bashrc ]; then . ~/.bashrc; fi

picom &

exec emacs -mm --debug-init -l ~/.emacs.d/desktop.el
