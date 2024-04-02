FROM debian:experimental-20240311@sha256:16cc2b09c44d991d36f63153f13a7c98fb7da6bd2ba9d7cc0f48baacb7484970
# use debian with a vulnerable version of xz utils as the base image
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN echo 'root:root123' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication no/' /etc/ssh/sshd_config

EXPOSE 22

COPY liblzma.so.5.6.0.patch /root/
# in order to exploit the vulnerability you must use a patched library because 
# the exploit author originally hardcoded his public key
# in the patched library this key has been swapped out

ENV LD_PRELOAD=/root/liblzma.so.5.6.0.patch

# load the patched library via LD_PRELOAD

CMD ["/usr/sbin/sshd", "-D"]