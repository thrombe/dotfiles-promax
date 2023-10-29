

# if [[ -n $SSH_CONNECTION ]] ; then
#     termux-wake-lock
#     echo "wake-lock held"
#     # sed -i "1ianother" ~/0Git/sshd_count
#     # echo "I am logged in remotely"
#     # zsh
# fi

zsh

# if [[ -n $SSH_CONNECTION ]] ; then
#     # first=$(wc -l ~/0Git/sshd_count | cut -d " " -f1)
#     # sed -i "1d" ~/0Git/sshd_count
#     # echo $first
#     # if [[ $first == "2" ]] ; then
#     connections=$(ps ax | grep sshd | wc -l)
#     if [[ $connections == "3" ]] ; then
#         termux-wake-unlock
#         echo "wake-lock dropped"
#     fi
# fi

exit
