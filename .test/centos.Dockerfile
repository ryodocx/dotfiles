FROM centos:7

COPY . /root/.dotfiles/
WORKDIR /root
RUN /root/.dotfiles/link.sh
RUN /root/.dotfiles/install.sh
