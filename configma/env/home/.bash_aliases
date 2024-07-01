#!/bin/bash

export LC_ALL="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"

export FLAKE="$(realpath /etc/nixos)"

# - [Install br - Broot](https://dystroy.org/broot/install-br/)
# This script was automatically generated by the broot program
# More information can be found in https://github.com/Canop/broot
# This function starts broot and executes the command
# it produces, if any.
# It's needed because some shell commands, like `cd`,
# have no useful effect if executed in a subshell.
function bt {
    local cmd cmd_file code
    cmd_file=$(mktemp)
    if broot --outcmd "$cmd_file" "$@"; then
        cmd=$(<"$cmd_file")
        command rm -f "$cmd_file"
        eval "$cmd"
    else
        code=$?
        command rm -f "$cmd_file"
        return "$code"
    fi
}

# - [Quick Start | Yazi](https://yazi-rs.github.io/docs/quick-start#shell-wrapper)
function ya() {
	local tmp="$(mktemp -t "yazi-cwd.XXXXX")"
	yazi "$@" --cwd-file="$tmp"
	if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
		cd -- "$cwd"
	fi
	rm -f -- "$tmp"
}

eval "$(zoxide init zsh)"
alias cd="z"
alias cdi="zi"


alias ls="ls --color=auto"
alias la="ls -a --color=auto"
# alias lf="~/.config/lf/lfrun"
alias musiman="python ~/0Git/musimanager/src/main.py"
alias kk="qalc"
alias k="kalker"
alias tsa="tree -a"
alias ts="tree"
# alias cargob="RUST_BACKTRACE=1 cargo"
alias d="dolphin_whale"
alias t="new_terminal"
alias x="detach"
alias ssh7s="ssh 192.168.1.190 -p 8022"
alias sshphon="ssh 192.168.1.191 -p 8022"
alias rd="rdrag"
alias de="distrobox enter"
alias br="browser_profile fzf old"
alias brf="browser_profile fzf firefox"
alias brn="browser_profile fzf librewolf"
# alias wlp="wallpaper_set"
alias ze="launch_zellij"
alias zz="open_zellij_workspace"
alias za="zellij a \$(zellij ls | grep -v 'EXITED' | cut -d ' ' -f1 | sed 's/\x1b\[[0-9;]*m//g' | fzf)"
alias zri="zellij run --in-place -- "
alias yp="~/0Git/dotfiles-promax-private/scripts/yankpass.sh"

open_zellij_workspace() {
  if [[ -f ./workspace.kdl ]]; then
    zellij -l ./workspace.kdl
  else
    zellij
  fi
}

toggle_mic() {
  # - [WirePlumber - ArchWiki](https://wiki.archlinux.org/title/WirePlumber)
  mic_id="$(wpctl status | grep "Built-in Audio Analog Stereo" | sort -r | head -n 1 | cut -d " " -f7 | cut -d "." -f1)"
  wpctl set-mute $mic_id toggle
}

launch_zellij() {
  if [[ $# < 1 ]]; then
    (cd ~/.config/zellij/layouts && zellij -l $(ls | fzf $@))
  else
    zlinputs="$@"
    (cd ~/.config/zellij/layouts && zellij -l $(ls | fzf -1 -q $zlinputs))
  fi
}

alacritty_focused() {
  detach $(alacritty msg create-window $@ || alacritty $@)
  
  sleep 0.4
  alacritty_id="$(wmctrl -lpx | grep "Alacritty.Alacritty" | sort -r | head -n 1 | cut -d " " -f 1)"
  if [[ $alacritty_id != "" ]] ; then
    wmctrl -ia $alacritty_id
  fi
}

new_terminal() {
  wdir=""
  args=""
  if [[ $# < 1 ]] ; then
    wdir="--working-directory=$(realpath .)"
  else
    wdir="--working-directory=$(realpath $@)"
  fi
  alacritty_focused $wdir $args
  # detach $(alacritty msg create-window $wdir $args || alacritty $wdir $args)

  # sleep 0.4
  # alacritty_id="$(wmctrl -lpx | grep "Alacritty.Alacritty" | sort -r | head -n 1 | cut -d " " -f 1)"
  # if [[ $alacritty_id != "" ]] ; then
  #   wmctrl -ia $alacritty_id
  # fi
}

launch_a_file_from() {
  if [[ $# > 0 ]] ; then
    if [[ $1 == "-d" ]] ; then
      if [[ $# < 3 ]] ; then
        return
      fi
      dir_path=$3
      depth=$2
    else
      depth="1"
      dir_path=$1
    fi
    file_path="$(cd $dir_path && fd --max-depth $depth --type file . ./ | fzf)"
    (cd $dir_path && ifarg hx $file_path)
  fi
}

dolphin_whale() {  
  if [[ $# == 0 ]]; then
    detach dolphin --new-window .
  else
    detach dolphin --new-window $@
  fi
}

# wallpaper_set() {
#   # set desktop wallpaper
#   python ~/1Git/repo_test/ksetwallpaper/ksetwallpaper.py -f $@
  
#   # set lockscreen wallpaper
#   python ~/1Git/repo_test/ksetwallpaper/ksetwallpaper.py -l -f $@
  
#   # set sddm wallpaper (path is set in /usr/share/sddm/themes/breeze/theme.conf.user)
#   cp $1 ~/zessential/wallpee.png
# }

detach() {
  $@ </dev/null &>/dev/null & disown
}

open() {
  detach xdg-open $@
}

ifarg() {
  if [[ $# < 2 ]] ; then
    return
  else
    $@
  fi
}

rdrag() {
  if [[ $# == 0 ]]; then
    ripdrag -h
    return
  elif [[ $# > 1 ]]; then
    x ripdrag --icon-size 70 -H "$((85 * $# + 30))" -W 360 $@
  else
    if [[ -f $1 ]] ; then
      x ripdrag --icon-size 70 -H "$((85 * $# + 30))" -W 360 -x $@
    else
      files_in_dir=()
      count=0
      for file in $(realpath $1)/* ; do
        if [[ -f $file ]] ; then
          count=$(($count + 1))
          files_in_dir+=("$file")
        fi
      done
      x ripdrag --icon-size 70 -H "$((85 * $count + 30))" -W 360 $files_in_dir
    fi
  fi
  if [[ "$(is-x11)" == "1" ]]; then
    if [[ "$(until-window-class-detected ripdrag)" == "1" ]]; then
        xdotool key "Super_L+Shift_L+Control_L+F" # to make it go into floating window mode
    fi
  fi
}

browser_profile() {
  runner="$1"
  shift
  browser="$1"
  shift

  br_path=~/daata/browser_profiles/$browser
  if [[ $browser == "old" ]]; then
    br_path=~/daata/browser_profiles
    browser="librewolf"
  fi

  if [[ "$1" == "-n" ]]; then
    echo "creating new profile from template profile $2"
    cp -r $br_path/template_profile $br_path/$2
  elif [[ $1 == "-e" ]]; then
    if [[ $# == 2 ]]; then
      br_name="$2"
      detach nixGLIntel $browser --profile $br_path/$br_name
    else
      echo "-e option needs exact profile name as argument"
    fi
  else
    if [[ $runner == "fzf" ]]; then
      if [[ $# < 1 ]]; then
        br_name=$(ls $br_path | fzf)
      else
        br_inputs="$@"
        br_name=$(ls $br_path | fzf -1 -q $br_inputs)
      fi
    elif [[ $runner == "rofi" ]]; then
      br_name=$(ls $br_path | rofi -p 'Profiles:' -dmenu)
    fi
    if [[ $br_name != "" ]]; then
      echo "$br_path/$br_name"
      detach nixGLIntel $browser --profile $br_path/$br_name
    fi
  fi
}

lbwopen() {
  command=lbwopen-links
  
  br_path=~/daata/browser_profiles
  if [[ "$1" == "-p" ]]; then
    if [[ $# < 2 ]]; then
      br_name=$(ls $br_path | fzf)
    else
      br_inputs="$2"
      br_name=$(ls $br_path | fzf -1 -q $br_inputs)
    fi
    if [[ $br_name != "" ]]; then
      echo "$br_path/$br_name"
      $command "$br_path/$br_name"
    fi
  else
    $command
  fi
}

# xhost +si:localuser:$USER > /dev/null

# export FZF_DEFAULT_COMMAND='rg --hidden --files -L -i -g "!.git" -g "!.cache" -g "!.cargo/registry"'
# export FZF_DEFAULT_COMMAND='rg --hidden -L -l "" -i --max-depth 15 -g "!.git" -g "!.cache" -g "!.cargo/registry"'
export FZF_COMPLETION_TRIGGER='`'
# command for listing path candidates.
# - The first argument to the function ($1) is the base path to start traversal
# - See the source code (completion.{bash,zsh}) for the details.
# _fzf_compgen_path() {
  # fd --hidden --follow --exclude ".git" . "$1"
  # rg --hidden --files -L -i --no-messages -g "!.git" -g "!.cache" -g "!.cargo/registry" "$1"
  # rg --files -i -L --max-depth 15 --no-messages --no-ignore -g "!.git" -g "!.cache" -g "!.cargo/registry" "$1"
# }

# Use fd to generate the list for directory completion
# _fzf_compgen_dir() {
  # fd --type d --hidden --follow --exclude ".git" . "$1"
  # rg --hidden --files -i -g "!.git" -g "!.cache" -g "!.cargo/registry" "$1"
# }

