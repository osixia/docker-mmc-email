#!/bin/sh

# -e Exit immediately if a command exits with a non-zero status
set -e

DOMAIN_NAME=${DOMAIN_NAME}
LDAP_HOST=${LDAP_HOST}
LDAP_BASE_DN=${LDAP_BASE_DN}
IMAP_SSL_CRT_FILENAME=${IMAP_SSL_CRT_FILENAME}
IMAP_SSL_KEY_FILENAME=${IMAP_SSL_KEY_FILENAME}

# dovecot is not already configured
if [ ! -e /etc/dovecot/docker_bootstrapped ]; then

  cp /etc/dovecot/config/dovecot.conf /etc/dovecot/dovecot.conf
  cp /etc/dovecot/config/dovecot-ldap.conf.ext /etc/dovecot/dovecot-ldap.conf.ext

  mkdir -p /etc/ssl/imap
  /sbin/create-ssl-cert imap.$DOMAIN_NAME /etc/ssl/imap/$IMAP_SSL_CRT_FILENAME /etc/ssl/imap/$IMAP_SSL_KEY_FILENAME

  # SSL Cert
  sed -i -e "s/imap.crt/$IMAP_SSL_CRT_FILENAME/g" /etc/dovecot/dovecot.conf
  sed -i -e "s/imap.key/$IMAP_SSL_KEY_FILENAME/g" /etc/dovecot/dovecot.conf

  echo "ssl_protocols = !SSLv2 !SSLv3" >> /etc/dovecot/conf.d/10-ssl.conf

  # Set ldap host
  sed -i -e "s/127.0.0.1/$LDAP_HOST/g" /etc/dovecot/dovecot-ldap.conf.ext

  # Set ldap base dn
  sed -i -e "s/dc=example,dc=com/$LDAP_BASE_DN/g" /etc/dovecot/dovecot-ldap.conf.ext

  mkdir /etc/dovecot/global_script
  mv /etc/dovecot/config/dovecot.sieve /etc/dovecot/global_script/dovecot.sieve

  chown -R vmail:mail /etc/dovecot/global_script/ 
  chmod -R 770 /etc/dovecot/global_script/


  touch /etc/dovecot/docker_bootstrapped
else
  status "found already-configured dovecot"
fi


# exec postfix and dovecot if amavis is ready
if [ -e /etc/amavis/docker_exec ]; then
  service postfix start
  exec /usr/sbin/dovecot -F
else  
  sleep 60
fi
