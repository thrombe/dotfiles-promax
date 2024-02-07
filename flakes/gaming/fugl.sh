#! /bin/sh

# https://www.reddit.com/r/wine_gaming/comments/rli4n8/how_do_i_run_games_through_wine_guide/

# export WINE64=~/MyGame/Wine/bin/wine64
# export WINESERVER=~/MyGame/Wine/bin/wineserver
# export WINEARCH=win32 # defaults to 64bit
export WINEPREFIX=~/Games/0prefixes/fugl-prefix

nvidia-offload wine64 start /unix  ~/Games/Fugl.v23.04.2022/Fugl.exe
