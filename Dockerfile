FROM ubuntu:24.04
LABEL maintainer="uday kiran reddy"

# Build arguments (can override at build time)
ARG JDK_VERSION=17
ARG NODE_VERSION=18
ARG MAVEN_VERSION=3.9.4

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-${JDK_VERSION}-openjdk-amd64
ENV MAVEN_HOME=/opt/maven
ENV PATH="${PATH}:${MAVEN_HOME}/bin"

# Install minimal dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        openssh-server \
        curl \
        wget \
        unzip \
        ca-certificates \
        gnupg && \
    rm -rf /var/lib/apt/lists/*

# Install Java dynamically
RUN apt-get update && \
    apt-get install -y --no-install-recommends openjdk-${JDK_VERSION}-jdk && \
    echo "JAVA_HOME=${JAVA_HOME}" >> /etc/environment && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js dynamically
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# Enable Yarn via Corepack
RUN corepack enable && corepack prepare yarn@stable --activate

# Install Maven dynamically
RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz \
    | tar -xz -C /opt && \
    ln -s /opt/apache-maven-${MAVEN_VERSION} /opt/maven && \
    echo 'export PATH=$PATH:/opt/maven/bin' > /etc/profile.d/maven.sh

# Ensure PATH is available in SSH sessions
RUN echo "PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/maven/bin" >> /etc/environment

# Create Jenkins user
RUN adduser --quiet jenkins && \
    echo "jenkins:jenkins" | chpasswd && \
    mkdir -p /home/jenkins/.m2 /home/jenkins/.ssh /workspace && \
    chown -R jenkins:jenkins /home/jenkins /workspace && \
    echo 'export PATH=$PATH:/opt/maven/bin' >> /home/jenkins/.bashrc && \
    echo 'export PATH=$PATH:/opt/maven/bin' >> /home/jenkins/.profile

# Ensure Maven is readable by all users
RUN chmod -R a+rX /opt/maven

# Copy authorized keys
COPY .ssh/authorized_keys /home/jenkins/.ssh/authorized_keys
RUN chmod 700 /home/jenkins/.ssh && chmod 600 /home/jenkins/.ssh/authorized_keys

# SSH setup
RUN mkdir -p /var/run/sshd && \
    sed -i 's|session    required     pam_loginuid.so|session    optional     pam_loginuid.so|g' /etc/pam.d/sshd

WORKDIR /workspace
EXPOSE 22

CMD ["/usr/sbin/sshd", "-D"]
