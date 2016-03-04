#!/bin/bash

# Tech and Me, ©2016 - www.techandme.se

VERSION=4.5.5.1
HTTP_PATH=https://files.phpmyadmin.net/phpMyAdmin/$VERSION
INSTALLDIR=/var/www/html
PHPMYADMINDIR=$INSTALLDIR/phpmyadmin
WANIP=$(dig +short myip.opendns.com @resolver1.opendns.com)
ADDRESS=$(ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1')
PHPMYADMIN_CONF="/etc/apache2/conf-available/phpmyadmin.conf"
BLOWFISH=$(cat /dev/urandom | tr -dc "a-zA-Z0-9" | fold -w 15 | head -1)
UPLOADPATH=""
SAVEPATH=""

# Check if root
        if [ "$(whoami)" != "root" ]; then
        echo
        echo -e "\e[31mSorry, you are not root.\n\e[0mYou must type: \e[36msudo \e[0mbash $SCRIPTS/phpmyadmin_install.sh"
        echo
        exit 1
fi

# Install mbstring for PHP
apt-get install php7.0-mbstring -y

# Download phpMyadmin
if [ -d $PHPMYADMINDIR ];
        then
rm -rf $PHPMYADMINDIR
fi

wget $HTTP_PATH/phpMyAdmin-$VERSION-all-languages.zip -P $INSTALLDIR
unzip -q $INSTALLDIR/phpMyAdmin-$VERSION-all-languages.zip -d $INSTALLDIR && rm $INSTALLDIR/phpMyAdmin-$VERSION-all-languages.zip
mv $INSTALLDIR/phpMyAdmin-$VERSION-all-languages $PHPMYADMINDIR
cd /
chmod -R 0755 $PHPMYADMINDIR
chown www-data:www-data -R $PHPMYADMINDIR

# Secure phpMyadmin
if [ -f $PHPMYADMIN_CONF ];
        then
        rm $PHPMYADMIN_CONF
fi
        touch "$PHPMYADMIN_CONF"
        cat << CONF_CREATE > "$PHPMYADMIN_CONF"
# phpMyAdmin default Apache configuration

Alias /phpmyadmin $PHPMYADMINDIR 

<Directory $PHPMYADMINDIR>
        Options FollowSymLinks
        DirectoryIndex index.php

        <IfModule mod_authz_core.c>
# Apache 2.4
        <RequireAny>
        Require ip $WANIP
	Require ip $ADDRESS
        Require ip 127.0.0.1
        Require ip ::1
        </RequireAny>
        </IfModule>

        <IfModule !mod_authz_core.c>
# Apache 2.2
        Order Deny,Allow
        Deny from All
        Allow from $WANIP
        Allow from $ADDRESS
        Allow from ::1
        Allow from localhost
	</IfModule>
</Directory>

# Authorize for setup
<Directory $PHPMYADMINDIR/setup>
    <IfModule mod_authn_file.c>
    AuthType Basic
    AuthName "phpMyAdmin Setup"
    AuthUserFile /etc/phpmyadmin/htpasswd.setup
    </IfModule>
    Require valid-user
</Directory>

# Disallow web access to directories that don't need it
<Directory $PHPMYADMINDIR/libraries>
    Order Deny,Allow
    Deny from All
</Directory>
<Directory $PHPMYADMINDIR/setup/lib>
    Order Deny,Allow
    Deny from All
</Directory>
CONF_CREATE

# Secure phpMyadmin even more
# Secure phpMyadmin even more
CONFIG=$PHPMYADMINDIR/config/config.inc.php
if [ -d $PHPMYADMINDIR/config ];
        then
rm -R $PHPMYADMINDIR/config
fi
mkdir -p $PHPMYADMINDIR/config
chmod -R o+rw $PHPMYADMINDIR/config/
if [ -f $CONFIG ];
        then
        rm $CONIG
fi
        touch "$CONFIG"
        chmod 644 $CONFIG
        chwon www-data:www-data $CONFIG
        cat << CONFIG_CREATE > "$CONFIG"
<?php
$cfg['UploadDir'] = '$SAVEPATH';
$cfg['SaveDir'] = '$UPLOADPATH';
$cfg['BZipDump'] = false;
$cfg['blowfish_secret'] = '$BLOWFISH';
$cfg['DefaultLang'] = 'en';
$cfg['ServerDefault'] = 1;
$cfg['ShowPhpInfo'] = true;
$cfg['Export']['lock_tables'] = true;
?>
CONFIG_CREATE

mv $CONFIG $PHPMYADMINDIR/
rm -R $PHPMYADMINDIR/config

service apache2 restart

echo
echo "$PHPMYADMIN_CONF was successfully secured."
echo
sleep 3

exit 0
