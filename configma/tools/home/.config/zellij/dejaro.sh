
if [[ $# > 1 ]]; then
  distrobox-enter jaro -- "$@"
else 
  distrobox-enter jaro
fi