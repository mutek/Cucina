#!/usr/bin/env sh
#
# make-pem-cert v1.0
#
# Luca Cappelletti (c) 2015
#
# Licenza WTF
#
# Genera un certificato PEM con chiavi da 4096 bit

[ $(which openssl) ] || { echo "ERRORE: non trovo il binario openssl "; exit;  }
[ -f stunnel.cnf ] || [ -f openssl.cnf ] || { echo "ERRORE: non trovo un file di configurazione .cnf"; exit; }

[ -f openssl.cnf ] && CONF_FILE=openssl.cnf
[ -f stunnel.cnf ] && CONF_FILE=stunnel.cnf

OPENSSL=$(which openssl)
echo "openssl = "$OPENSSL

$(which openssl) req -new -x509 -days 365 -config $CONF_FILE  -out certificato.pem -keyout certificato.pem

$(which openssl) x509 -subject -dates -fingerprint -noout -in certificato.pem

unlink stunnel.pem
mv certificato.pem stunnel.pem

