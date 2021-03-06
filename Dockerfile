FROM debian:bullseye-20220801-slim

ARG user=jenkins \
    group=jenkins \
    uid=1000 \
    gid=1000
ENV JENKINS_AGENT_HOME=/home/${user} \
    LANG='C.UTF-8' LC_ALL='C.UTF-8'

# Requirements
ENV DEBIAN_FRONTEND=noninteractive
RUN rm /etc/apt/sources.list && \
    echo "deb http://ftp.debian.org/debian bullseye main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://ftp.debian.org/debian bullseye-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://ftp.debian.org/debian bullseye-proposed-updates main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://ftp.debian.org/debian bullseye-backports main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://ftp.debian.org/debian bullseye-backports-sloppy main contrib non-free" >> /etc/apt/sources.list && \
    echo "deb http://security.debian.org/debian-security bullseye-security main contrib non-free" >> /etc/apt/sources.list && \
    apt update -t bullseye-backports -y && \
    apt upgrade -t bullseye-backports -y --allow-downgrades && \
    apt dist-upgrade -t bullseye-backports -y --allow-downgrades && \
    apt autoremove -t bullseye-backports --purge -y && \
    apt autoclean -t bullseye-backports -y && \
    apt clean -t bullseye-backports -y && \
    apt -o DPkg::Options::="--force-confnew" -y install -t bullseye-backports -y curl gnupg ca-certificates apt-utils && \
    curl https://apt.corretto.aws/corretto.key | apt-key add - && \
    echo "deb https://apt.corretto.aws stable main" >> /etc/apt/sources.list && \
    apt update -t bullseye-backports -y && \
    apt upgrade -t bullseye-backports -y --allow-downgrades && \
    apt dist-upgrade -t bullseye-backports -y --allow-downgrades && \
    apt autoremove -t bullseye-backports --purge -y && \
    apt autoclean -t bullseye-backports -y && \
    apt clean -t bullseye-backports -y && \
    apt -o DPkg::Options::="--force-confnew" -y install -t bullseye-backports -y maven \
                                                                                 git \
                                                                                 git-lfs \
                                                                                 openssh-server \
                                                                                 ca-certificates \
                                                                                 netcat-traditional \
                                                                                 java-1.8.0-amazon-corretto-jdk \
                                                                                 java-11-amazon-corretto-jdk \
                                                                                 java-15-amazon-corretto-jdk \
                                                                                 java-16-amazon-corretto-jdk \
                                                                                 java-17-amazon-corretto-jdk \
                                                                                 java-18-amazon-corretto-jdk && \
    mkdir -p /home/jenkins/jdk/bin && \
    ln -s /usr/lib/jvm/java-17-amazon-corretto/bin/java /home/jenkins/jdk/bin/java && \
    update-alternatives --install /usr/bin/java java /usr/lib/jvm/java-17-amazon-corretto/bin/java 99999999

# Create User
RUN groupadd -g ${gid} ${group} && \
    useradd -d "${JENKINS_AGENT_HOME}" -u "${uid}" -g "${gid}" -m -s /bin/bash "${user}" && \

# setup SSH server
    sed -i /etc/ssh/sshd_config \
        -e 's/#PermitRootLogin.*/PermitRootLogin no/' \
        -e 's/#RSAAuthentication.*/RSAAuthentication yes/'  \
        -e 's/#PasswordAuthentication.*/PasswordAuthentication no/' \
        -e 's/#SyslogFacility.*/SyslogFacility AUTH/' \
        -e 's/#LogLevel.*/LogLevel INFO/' && \
    mkdir /var/run/sshd && \
    mkdir ${JENKINS_AGENT_HOME}/.ssh && \
    echo "PATH=${PATH}" >> ${JENKINS_AGENT_HOME}/.ssh/environment && \
    curl -o /usr/local/bin/setup-sshd -L https://raw.githubusercontent.com/jenkinsci/docker-ssh-agent/master/setup-sshd && \
    chmod +x /usr/local/bin/setup-sshd && \
    chown -R jenkins:jenkins /home/jenkins && \
    touch /home/jenkins/.ssh/authorized_keys && \
    chmod go-w /home/jenkins/.ssh/authorized_keys

WORKDIR "${JENKINS_AGENT_HOME}"
ENTRYPOINT ["setup-sshd"]
