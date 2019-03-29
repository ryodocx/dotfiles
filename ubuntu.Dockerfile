FROM ubuntu:18:04

COPY . /root/.dotfiles/
WORKDIR /root/.dotfiles
RUN /root/.dotfiles/link.sh
RUN /root/.dotfiles/install.sh
