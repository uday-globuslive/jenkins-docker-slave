FROM ubuntu:24.04

LABEL maintainer="Bibin Wilson <bibinwilsonn@gmail.com>"

# Update packages and install dependencies
RUN apt-get update && \
    apt-get -qy full-upgrade && \
    apt-get install -qy git wget gnupg2 software-properties-common && \
\
# Install a basic SSH server
    apt-get install -qy openssh-server && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
\
# Install OpenJDK 17 from default Ubuntu 24.04 repository
    apt-get install -qy openjdk-17-jdk && \
\
# Install Maven
    apt-get install -qy maven && \
\
# Cleanup
    apt-get -qy autoremove && \
\
# Add user jenkins
    adduser --quiet jenkins && \
    echo "jenkins:jenkins" | chpasswd && \
    mkdir -p /home/jenkins/.m2

# Copy authorized SSH keys
COPY .ssh/authorized_keys /home/jenkins/.ssh/authorized_keys

RUN chown -R jenkins:jenkins /home/jenkins/.m2/ && \
    chown -R jenkins:jenkins /home/jenkins/.ssh/

# Standard SSH port
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
