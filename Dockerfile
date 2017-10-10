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
    htop tmux zip
COPY configs/nginx/default /etc/nginx/sites-available/default

#Install PHP
RUN apt-get install -y language-pack-en-base
RUN LC_ALL=en_US.UTF-8 add-apt-repository ppa:ondrej/php
RUN apt-get update 
RUN apt-get install -y php7.0 php7.0-cli php7.0-common php7.0-cgi php7.0-curl php7.0-imap
RUN apt-get install -y php7.0-mysql php7.0-fpm php7.0-gd php7.0-intl
RUN apt-get install -y php7.0-xml php7.0-mbstring php7.0-mcrypt
RUN apt-get install -y php7.0-dev php7.0-xsl php7.0-zip php7.0-soap
RUN pecl install xdebug-2.5.1
RUN rm /etc/php/7.0/cgi/php.ini
RUN rm /etc/php/7.0/cli/php.ini
RUN rm /etc/php/7.0/fpm/php.ini
RUN rm /etc/php/7.0/fpm/pool.d/www.conf
COPY configs/php/www.conf /etc/php/7.0/fpm/pool.d/www.conf
COPY configs/php/php.ini  /etc/php/7.0/cgi/php.ini
COPY configs/php/php.ini  /etc/php/7.0/cli/php.ini
COPY configs/php/php.ini  /etc/php/7.0/fpm/php.ini
COPY configs/php/xdebug.ini /etc/php/7.0/mods-available/xdebug.ini
RUN ln -s /etc/php/7.0/mods-available/xdebug.ini /etc/php/7.0/fpm/conf.d/20-xdebug.ini
RUN ln -s /etc/php/7.0/mods-available/xdebug.ini /etc/php/7.0/cli/conf.d/20-xdebug.ini

#Install Percona Mysql 5.6 server
RUN wget https://repo.percona.com/apt/percona-release_0.1-4.$(lsb_release -sc)_all.deb
RUN dpkg -i percona-release_0.1-4.$(lsb_release -sc)_all.deb
RUN rm percona-release_0.1-4.$(lsb_release -sc)_all.deb
RUN apt-get update
RUN echo "percona-server-server-5.6 percona-server-server/root_password password root" | sudo debconf-set-selections
RUN echo "percona-server-server-5.6 percona-server-server/root_password_again password root" | sudo debconf-set-selections
RUN apt-get install -y percona-server-server-5.6
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

#configs bash start
COPY configs/autostart.sh /root/autostart.sh
RUN chmod +x /root/autostart.sh
RUN sh /root/autostart.sh

#Install locale
RUN locale-gen en_US en_US.UTF-8 uk_UA uk_UA.UTF-8
RUN dpkg-reconfigure locales

#Composer
RUN cd /home
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin/ --filename=composer
RUN chmod 777 /usr/local/bin/composer

#open ports
EXPOSE 80 22 9000
