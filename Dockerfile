FROM osixia/baseimage:0.8.1
MAINTAINER Bertrand Gouny <bertrand.gouny@osixia.net>

# Default configuration: can be overridden at the docker command line
ENV DB_HOST 127.0.0.1
ENV USE_EXTENDED_FEATURES true

# Needed if USE_EXTENDED_FEATURES = true
ENV DB_ROOT_USER admin
ENV DB_ROOT_PWD toor

# phpmyadmin SSL certificat and private key filename
ENV PHPMYADMIN_SSL_CRT_FILENAME phpmyadmin.crt
ENV PHPMYADMIN_SSL_KEY_FILENAME phpmyadmin.key

# Disable SSH
# RUN rm -rf /etc/service/sshd /etc/my_init.d/00_regen_ssh_host_keys.sh

# Enable php and nginx
RUN /sbin/enable-service php5-fpm nginx

# Use baseimage-docker's init system.
CMD ["/sbin/my_init"]

# Resynchronize the package index files from their sources
RUN apt-get -y update

# Install phpMyAdmin
RUN LC_ALL=C DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends slapd ldap-utils dovecot-imapd

# Expose http and https default ports
EXPOSE 80 443

# phpMyAdmin config
RUN mkdir -p /etc/my_init.d
ADD service/phpmyadmin/phpmyadmin.sh /etc/my_init.d/phpmyadmin.sh

# phpMyAdmin nginx config
RUN mkdir -p /etc/phpmyadmin
ADD service/phpmyadmin/config/ /etc/phpmyadmin

# Clear out the local repository of retrieved package files
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*
