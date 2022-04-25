docker run -v /tmp/.X11-unix:/tmp/.X11-unix -v $(pwd):/home/dev -e DISPLAY=$DISPLAY -h $HOSTNAME -v $HOME/.Xauthority:/root/.Xauthority -it midi_menu $*
