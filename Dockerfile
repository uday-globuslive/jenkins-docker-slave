# More robust Dockerfile with proper variable handling
FROM ubuntu:24.04
LABEL maintainer="uday kiran reddy"

# Build arguments
ARG JDK_VERSION=17
ARG NODE_VERSION=18
ARG MAVEN_VERSION=3.9.4

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive

# Make sure the package repository is up to date and install basic tools
RUN apt-get update && \
    apt-get -qy full-upgrade && \
    apt-get install -qy \
        git \
        openssh-server \
        curl \
        wget \
        unzip \
        ca-certificates \
        build-essential \
        python3 \
        python3-pip \
        gnupg \
        software-properties-common \
        apt-transport-https && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd && \
    mkdir -p /var/run/sshd && \
    rm -rf /var/lib/apt/lists/*

# Install Java (OpenJDK) with proper variable expansion
RUN apt-get update && \
    JDK_PACKAGE="openjdk-${JDK_VERSION}-jdk" && \
    echo "Installing Java package: $JDK_PACKAGE" && \
    apt-get install -y $JDK_PACKAGE && \
    rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME after Java installation
RUN JAVA_HOME_DIR="/usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64" && \
    echo "JAVA_HOME=$JAVA_HOME_DIR" >> /etc/environment && \
    echo "export JAVA_HOME=$JAVA_HOME_DIR" >> /etc/bash.bashrc
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64

# Install Node.js and npm
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install Yarn
RUN corepack enable && \
    corepack prepare yarn@stable --activate

# Install Maven (newer version)
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz -o /tmp/maven.tgz && \
    tar -xzf /tmp/maven.tgz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven && \
    rm /tmp/maven.tgz

# Set Maven environment variables
ENV MAVEN_HOME=/opt/maven
ENV PATH=$PATH:$MAVEN_HOME/bin

# Cleanup old packages and add user jenkins to the image
RUN apt-get -qy autoremove && \
    adduser --quiet jenkins && \
    echo "jenkins:jenkins" | chpasswd && \
    mkdir -p /home/jenkins/.m2 && \
    mkdir -p /home/jenkins/.ssh

#ADD settings.xml /home/jenkins/.m2/
# Copy authorized keys
COPY .ssh/authorized_keys /home/jenkins/.ssh/authorized_keys

# Set permissions and verify installations
RUN chown -R jenkins:jenkins /home/jenkins/.m2/ && \
    chown -R jenkins:jenkins /home/jenkins/.ssh/ && \
    chmod 700 /home/jenkins/.ssh && \
    chmod 600 /home/jenkins/.ssh/authorized_keys

# Verify all installations work
RUN java -version && \
    mvn -version && \
    node -v && \
    npm -v && \
    yarn -v

# Set working directory
WORKDIR /workspace

# Standard SSH port
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
