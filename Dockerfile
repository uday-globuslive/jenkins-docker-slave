# Alternative Dockerfile with OpenJDK (more reliable for Ubuntu 24.04)
FROM ubuntu:24.04
LABEL maintainer="uday kiran reddy"

# Build arguments
ARG JDK_VERSION=17
ARG NODE_VERSION=18
ARG MAVEN_VERSION=3.9.4

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64
ENV MAVEN_HOME=/opt/maven
ENV PATH=$PATH:$MAVEN_HOME/bin

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

# Install Java (OpenJDK - more reliable for Ubuntu 24.04)
RUN apt-get update && \
    apt-get install -y openjdk-${JDK_VERSION}-jdk && \
    rm -rf /var/lib/apt/lists/*

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
