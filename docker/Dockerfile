FROM debian:bullseye

RUN apt-get update -y && apt-get install -y python3-pyqt5

RUN groupadd -g 1000 dev
RUN useradd -d /home/dev -s /bin/bash -m dev -u 1000 -g 1000
USER dev
ENV HOME /home/dev

CMD ["/bin/sleep", "9999"]

# docker build -t midi_menu .
# docker run -v /tmp/.X11-unix:/tmp/.X11-unix -v $(pwd):/home/dev -e DISPLAY=$DISPLAY -h $HOSTNAME -v $HOME/.Xauthority:/root/.Xauthority -it midi_menu $*