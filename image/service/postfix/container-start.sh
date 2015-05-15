#!/bin/bash -e

FIRST_START_DONE="/etc/docker-postfix-first-start-done"

# container first start
if [ ! -e "$FIRST_START_DONE" ]; then

  # copy config
  cp /osixia/postfix/config/${POSTFIX_CONFIG}/* /etc/postfix/

  # set mailserver hostname
  sed -i "s/hostname.domain.tld/${SERVER_NAME}/g" /etc/postfix/main.cf


  # postfix ssl config
  # check certificat and key or create it
  /sbin/ssl-kit "/osixia/postfix/ssl/$SSL_CRT_FILENAME" "/osixia/postfix/ssl/$SSL_KEY_FILENAME" --ca-crt=/osixia/postfix/ssl/$SSL_CA_CRT_FILENAME

  # adapt tls ldif
  sed -i "s,/osixia/postfix/ssl/ca.crt,/osixia/postfix/ssl/${SSL_CA_CRT_FILENAME},g" /etc/postfix/main.cf
  sed -i "s,/osixia/postfix/ssl/mailserver.crt,/osixia/postfix/ssl/${SSL_CRT_FILENAME},g" /etc/postfix/main.cf
  sed -i "s,/osixia/postfix/ssl/mailserver.key,/osixia/postfix/ssl/${SSL_KEY_FILENAME},g" /etc/postfix/main.cf

  # ldap config
  for i in `ls /etc/postfix/ldap-*.cf`;
  do
    sed -i "s,127.0.0.1,$LDAP_URL," $i;
    sed -i "s/dc=mandriva,dc=com/$LDAP_BASE_DN/" $i;

    # ldap bind dn
    if [ -n "${LDAP_BIND_DN}" ]; then
      echo "bind = yes" >> $i;
      echo "bind_dn = $LDAP_BIND_DN" >> $i;

      # ldap bind password
      if [ -n "${LDAP_BIND_PW}" ]; then
        echo "bind_pw = $LDAP_BIND_PW" >> $i;
      fi
    fi

    # ldap tls config
    if [ "${LDAP_USE_TLS,,}" == "true" ]; then
      echo "start_tls = no" >> $i;
      echo "tls_ca_cert_file = /osixia/postfix/ssl/$LDAP_SSL_CA_CRT_FILENAME" >> $i;
      echo "tls_cert = /osixia/postfix/ssl/$LDAP_SSL_CRT_FILENAME" >> $i;
      echo "tls_key = /osixia/postfix/ssl/$LDAP_SSL_KEY_FILENAME" >> $i;
      echo "tls_require_cert = no" >> $i;
    fi
  done

  touch $FIRST_START_DONE
fi

# set hosts
echo "$SERVER_NAME" > /etc/hostname
echo "127.0.0.1 localhost.localdomain" >> /etc/hosts
echo "127.0.0.1 $SERVER_NAME" >> /etc/hosts

# fix files permissions
chown -R vmail:vmail /var/mail

service postfix start

exit 0
