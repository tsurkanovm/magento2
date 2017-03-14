FROM      ubuntu:14.04.4
MAINTAINER Oleksander Kutsenko    <olexander.kutsenko@gmail.com>

# Let the conatiner know that there is no tty
ENV DEBIAN_FRONTEND noninteractive

#Create docker user
RUN mkdir -p /var/www
RUN mkdir -p /home/docker
RUN useradd -d /home/docker -s /bin/bash -M -N -G www-data,sudo,root docker
RUN echo docker:docker | chpasswd
RUN usermod -G www-data,users www-data
RUN chown -R docker:www-data /var/www
RUN chown -R docker:www-data /home/docker

#install Software
RUN echo "#!/bin/sh\nexit 0" > /usr/sbin/policy-rc.d
RUN apt-get update && apt-get upgrade -y
RUN dpkg-reconfigure tzdata
RUN apt-get install -y software-properties-common python-software-properties \
    git git-core vim nano mc nginx screen curl unzip wget \
    memcached htop tmux zip
COPY configs/nginx/default /etc/nginx/sites-available/default

#Install PHP
RUN apt-get install -y language-pack-en-base
RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php
RUN apt-get update 
RUN apt-get install -y php7.1 php7.1-cli php7.1-common php7.1-cgi php7.1-curl php7.1-imap php7.1-pgsql
RUN apt-get install -y php7.1-sqlite3 php7.1-mysql php7.1-fpm php7.1-intl php7.1-gd php7.1-json
RUN apt-get install -y php-memcached php-memcache php-imagick php7.1-xml php7.1-mbstring php7.1-ctype
RUN apt-get install -y php7.1-dev php-pear
RUN pecl install xdebug
RUN rm /etc/php/7.1/cgi/php.ini
RUN rm /etc/php/7.1/cli/php.ini
RUN rm /etc/php/7.1/fpm/php.ini
RUN rm /etc/php/7.1/fpm/pool.d/www.conf
COPY configs/php/www.conf /etc/php/7.1/fpm/pool.d/www.conf
COPY configs/php/php.ini  /etc/php/7.1/cgi/php.ini
COPY configs/php/php.ini  /etc/php/7.1/cli/php.ini
COPY configs/php/php.ini  /etc/php/7.1/fpm/php.ini
COPY configs/php/xdebug.ini /etc/php/7.1/mods-available/xdebug.ini
RUN ln -s /etc/php/7.0/mods-available/xdebug.ini /etc/php/7.1/fpm/conf.d/20-xdebug.ini
RUN ln -s /etc/php/7.0/mods-available/xdebug.ini /etc/php/7.1/cli/conf.d/20-xdebug.ini

#Install Percona Mysql 5.7 server
RUN wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
RUN dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
RUN rm percona-release_0.1-4.$(lsb_release -sc)_all.deb
RUN apt-get update
RUN echo "percona-server-server-5.7 percona-server-server/root_password password root" | sudo debconf-set-selections
RUN echo "percona-server-server-5.7 percona-server-server/root_password_again password root" | sudo debconf-set-selections
RUN apt-get install -y percona-server-server-5.7
COPY configs/mysql/my.cnf /etc/mysql/my.cnf

# SSH service
RUN sudo apt-get install -y openssh-server openssh-client
RUN echo 'root:root' | chpasswd
#change 'pass' to your secret password
RUN sed -i 's/PermitRootLogin without-password/PermitRootLogin yes/' /etc/ssh/sshd_config
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

# capifony
RUN apt-get install -y rubygems git curl
RUN gem install net-ssh -v 3.1.1
RUN gem install capifony -v 2.4.2

#configs bash start
COPY configs/autostart.sh /root/autostart.sh
RUN  chmod +x /root/autostart.sh
COPY configs/bash.bashrc /etc/bash.bashrc
COPY configs/.bashrc /root/.bashrc
COPY configs/.bashrc /home/docker/.bashrc

#Install locale
RUN locale-gen en_US en_US.UTF-8 uk_UA uk_UA.UTF-8
RUN dpkg-reconfigure locales

#Install Java 8
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886
RUN add-apt-repository -y ppa:webupd8team/java
RUN apt-get update
# Accept license non-iteractive
RUN echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections
RUN apt-get install -y oracle-java8-installer \
                       oracle-java8-set-default
RUN echo "JAVA_HOME=/usr/lib/jvm/java-8-oracle" | sudo tee -a /etc/environment
RUN export JAVA_HOME=/usr/lib/jvm/java-8-oracle

#ant install
RUN sudo apt-get install -y ant

#Autocomplete symfony3
COPY configs/files/symfony3-autocomplete.bash /etc/bash_completion.d/symfony3-autocomplete.bash

#Composer
RUN cd /home
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
RUN chmod 777 /usr/local/bin/composer

#Code standart
RUN composer global require "squizlabs/php_codesniffer=*"
RUN composer global require "sebastian/phpcpd=*"
RUN composer global require "phpmd/phpmd=@stable"
RUN cd /usr/bin && ln -s ~/.composer/vendor/bin/phpcpd
RUN cd /usr/bin && ln -s ~/.composer/vendor/bin/phpmd
RUN cd /usr/bin && ln -s ~/.composer/vendor/bin/phpcs

#etcKeeper
RUN mkdir -p /root/etckeeper
COPY configs/etckeeper.sh /root/etckeeper.sh
COPY configs/files/etckeeper-hook.sh /root/etckeeper/etckeeper-hook.sh
RUN chmod +x /root/etckeeper/*.sh
RUN chmod +x /root/*.sh
RUN /root/etckeeper.sh

#open ports
EXPOSE 80 22 9000
