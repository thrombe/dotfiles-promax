
# in tmux .bashrc
alias vscode-non-ubu="termux-wake-lock && code-server --bind-addr 0.0.0.0:13337 --auth none"
alias ls="ls -a"
alias ts="tree-rs"
alias tsa="tree-rs -a"
alias exib="termux-wake-unlock && exit"
alias vscode="~/shortcuts/vscode.sh"
#alias vscode="termux-wake-lock && ~/start-ubuntu.sh code-server --bind-addr 0.0.0.0:13337"
alias ubu="~/start-ubuntu.sh"
alias cleab="termux-wake-unlock && clear"

alias dc="tel-app Discord"
alias gh="tel-app OctoDroid"
alias files="tel-app Material\ Files"
alias sns="tel-app QKSMS"
alias home="tel-app Square\ Home"
alias reddit="tel-app Infinity"
alias cam="tel-app camera"
alias inf="tel-app infinity"
alias clo="tel-app clock"
alias pho="tel-app Phone"
alias wha="tel-app whats"

alias g="python ~/0Git/groups.py --launch-app"
alias yankpass="~/0Git/scripts/yankpass.sh"
# alias musiman="python ~/0Git/musimanager/src/main.py"
alias musiman="cd ~/0Git/musiman; ./target/release/musiman"
alias wildo="cd ~/0Git/wildo; ./target/release/wildo"
alias yp="yankpass"
alias kalker="~/0Git/bin/kalker"
alias k="kalker"
alias kk="qalc"
alias ttb="cat ~/0Git/ttb.txt"
alias tod="cat ~/0Git/todo.txt"
alias o="opan"
alias bt="broot"

alias home="am start -n com.nothing.launcher/com.android.searchlauncher.SearchLauncher"
alias h="home"
alias notification-history="am start -n com.android.settings/com.android.settings.notification.history.NotificationHistoryActivity"
alias ntf="notification-history"

opan() {
    am start --user 0 -a android.intent.action.VIEW -d "file://$(readlink -f $1)" -t "$(file -b --mime-type $1)" > /dev/null
}

tesy() {
    echo "lol $@ lol"
}
export PATH="$HOME/.cargo/bin:$PATH"

# export FZF_DEFAULT_COMMAND='rg --hidden --files -L -i -g "!.git" -g "!.cache" -g "!.cargo/registry"'

sshd


if [[ -n $SSH_CONNECTION ]] ; then
    connections=$(ps ax | grep sshd | wc -l)
    if [[ $connections == "3" ]] ; then
        termux-wake-lock
        echo "wake-lock held"
    fi
fi

trap exit_hook EXIT

function exit_hook {
    if [[ -n $SSH_CONNECTION ]] ; then
        connections=$(ps ax | grep sshd | wc -l)
        if [[ $connections == "3" ]] ; then
            termux-wake-unlock
            echo "wake-lock dropped"
        fi
    fi  
}
