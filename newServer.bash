#!/bin/bash

secure=false
rootFolder=~/../../etc/nginx/conf.d/

function setupServerCmd() {
  useradd -m -p "$(mkpasswd -m sha-512 "$2")" "$1"
  usermod -m -d /home/"$1"/ "$1"
  sudo quotacheck -cumf /
  sudo quotaon -f /
  sudo setquota "$1" 15G 15G 0 0 /dev/sda2
  sudo mkdir /home/"$1"/prod
  sudo mkdir /home/"$1"/prod/www
  sudo mkdir /home/"$1"/prod/logs
  sudo touch /home/
  if test "$3" = true; then
#    sudo /opt/letsencrypt/letsencrypt-auto certonly --agree-tos --rsa-key-size 4096 --webroot --webroot-path /home/"$1" -d "$1"
    sudo certbot certonly --nginx --domains "$1"
  fi
  sudo service nginx restart
  sudo service proftpd restart
}

function staticConf() {
  if test "$2" = false; then
    echo "server {

    listen 80;
    server_name $1;

    location / {
        root /home/$1/prod/www;
        index index.html index.htm;
        try_files \$uri \$uri/ \$uri.html =404;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    error_log /home/$1/prod/logs/error.log;
    access_log /home/$1/prod/logs/access.log;

    error_page 404 500 501 /error.html;

}

server {
    listen 80;
    server_name www.$1;
    return 301 http://$1\$request_uri;
}" > "$rootFolder"/"$1".conf

  else
    echo "server {
    listen 80;
    listen [::]:80;
    server_name $1;
    location ~ /\.well-known/acme-challenge {
        allow all;
    }
    location / {
        return 301 https://$1\$request_uri;
    }
}

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name $1;
    root /home/$1/prod/www;
    index index.html index.htm;
    error_log /home/$1/prod/logs/error.log;
    access_log /home/$1/prod/logs/access.log;

    location ~* \.(html|css|js|png|jpg|jpeg|gif|ico|svg|eot|woff|ttf)$ {
        expires max;
    }

    location / {
        root /home/$1/prod/www;
        index index.html index.htm;
        try_files \$uri \$uri/ \$uri.html =404;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    error_page 404 500 501 /error.html;

    #### SSL
    ssl on;
    ssl_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$1/privkey.pem;

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    # Google DNS, Open DNS, Dyn DNS
    resolver 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 216.146.35.35 216.146.36.36 valid=300s;
    resolver_timeout 3s;

    ####    Session Tickets
    # Session Cache doit avoir la même valeur sur tous les blocs \"server\".
    ssl_session_cache shared:SSL:100m;
    ssl_session_timeout 24h;
    ssl_session_tickets on;
    # [ATTENTION] il faudra générer le ticket de session.
    ssl_session_ticket_key /etc/nginx/ssl/ticket.key;

    # [ATTENTION] Les paramètres Diffie-Helman doivent être générés
    ssl_dhparam /etc/nginx/ssl/dhparam4.pem;

    ####    ECDH Curve
    ssl_ecdh_curve secp384r1;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';

}" > "$rootFolder"/"$1".conf
  fi

}

function nodejsVanillaConf() {
  if test "$3" = false; then
    echo "upstream $1 {
    server localhost:$2;
}

server {

    listen 80;
    listen [::]:80;
    server_name $1;

    location / {
        proxy_pass http://$1;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    error_log /home/$1/prod/logs/error.log;
    access_log /home/$1/prod/logs/access.log;

    error_page 404 500 501 /error.html;

}

server {
    listen 80;
    server_name www.$1;
    return 301 http://$1\$request_uri;
}" > "$rootFolder"/"$1".conf

  else
    echo "upstream $1 {
    server localhost:$2;
}

server {
    listen 80;
    listen [::]:80;
    server_name $1;
    location ~ /\.well-known/acme-challenge {
        allow all;
    }
    location / {
        return 301 https://$1\$request_uri;
    }
}

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name $1;
    root /home/$1/prod/www;
    error_log /home/$1/prod/logs/error.log;
    access_log /home/$1/prod/logs/access.log;

    location ~* \.(html|css|js|png|jpg|jpeg|gif|ico|svg|eot|woff|ttf)$ {
        expires max;
    }

    location / {
        proxy_pass https://$1;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    error_page 404 500 501 /error.html;

    #### SSL
    ssl on;
    ssl_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$1/privkey.pem;

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    # Google DNS, Open DNS, Dyn DNS
    resolver 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 216.146.35.35 216.146.36.36 valid=300s;
    resolver_timeout 3s;

    ####    Session Tickets
    # Session Cache doit avoir la même valeur sur tous les blocs \"server\".
    ssl_session_cache shared:SSL:100m;
    ssl_session_timeout 24h;
    ssl_session_tickets on;
    # [ATTENTION] il faudra générer le ticket de session.
    ssl_session_ticket_key /etc/nginx/ssl/ticket.key;

    # [ATTENTION] Les paramètres Diffie-Helman doivent être générés
    ssl_dhparam /etc/nginx/ssl/dhparam4.pem;

    ####    ECDH Curve
    ssl_ecdh_curve secp384r1;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';

}" > "$rootFolder"/"$1".conf
  fi
}

function nodejsWSConf() {
  if test "$3" = false; then

    echo "upstream $1 {
    server localhost:$2;
}

server {

    listen 80;
    listen [::]:80;
    server_name $1;

    location / {
        proxy_pass http://$1;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    error_log /home/$1/prod/logs/error.log;
    access_log /home/$1/prod/logs/access.log;

    error_page 404 500 501 /error.html;

}

server {
    listen 80;
    server_name www.$1;
    return 301 http://$1\$request_uri;
}" > "$rootFolder"/"$1".conf

  else
    echo "upstream $1 {
    server localhost:$2;
}

server {
    listen 80;
    listen [::]:80;
    server_name $1;
    location ~ /\.well-known/acme-challenge {
        allow all;
    }
    location / {
        return 301 https://$1\$request_uri;
    }
}

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name $1;
    root /home/$1/prod/www;
    error_log /home/$1/prod/logs/error.log;
    access_log /home/$1/prod/logs/access.log;

    location ~* \.(html|css|js|png|jpg|jpeg|gif|ico|svg|eot|woff|ttf)$ {
        expires max;
    }

    location / {
        proxy_pass https://$1;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    error_page 404 500 501 /error.html;

    #### SSL
    ssl on;
    ssl_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$1/privkey.pem;

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    # Google DNS, Open DNS, Dyn DNS
    resolver 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 216.146.35.35 216.146.36.36 valid=300s;
    resolver_timeout 3s;

    ####    Session Tickets
    # Session Cache doit avoir la même valeur sur tous les blocs \"server\".
    ssl_session_cache shared:SSL:100m;
    ssl_session_timeout 24h;
    ssl_session_tickets on;
    # [ATTENTION] il faudra générer le ticket de session.
    ssl_session_ticket_key /etc/nginx/ssl/ticket.key;

    # [ATTENTION] Les paramètres Diffie-Helman doivent être générés
    ssl_dhparam /etc/nginx/ssl/dhparam4.pem;

    ####    ECDH Curve
    ssl_ecdh_curve secp384r1;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';

}" > "$rootFolder"/"$1".conf
fi
}

function phpVanillaConf() {
  if test "$2" = false; then
    echo "server {

    listen 80;

    server_name $1;
    root /home/$1/prod/www;
    index index.php index.html index.htm;
    error_log /home/$1/prod/logs/error.log;
    access_log /home/$1/prod/logs/access.log;

    location / {
        root /home/$name/prod/www;
        index index.php index.html index.htm;
        try_files \$uri \$uri/ \$uri.html =404;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        limit_req zone=one burst=5;
    }

    error_log /home/$name/prod/logs/error.log;
    access_log /home/$name/prod/logs/access.log;

    error_page 404 500 501 /error.html;

}

server {
    listen 80;
    server_name www.$name;
    return 301 http://$name\$request_uri;
}" > "$rootFolder"/"$name".conf

  else
    echo "server {
    listen 80;
    listen [::]:80;
    server_name $1;
    location ~ /\.well-known/acme-challenge {
        allow all;
    }
    location / {
        return 301 https://$1\$request_uri;
    }
}

server {

    listen 443 ssl http2;
    listen [::]:443 ssl http2;

    server_name $1;
    root /home/$1/prod/www;
    index index.php index.html index.htm;
    error_log /home/$1/prod/logs/error.log;
    access_log /home/$1/prod/logs/access.log;

    location ~* \.(html|css|js|png|jpg|jpeg|gif|ico|svg|eot|woff|ttf)$ {
        expires max;
    }

    location / {
        root /home/$name/prod/www;
        index index.php index.html index.htm;
        try_files \$uri \$uri/ \$uri.html =404;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass unix:/var/run/php/php-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
        limit_req zone=one burst=5;
    }


    error_page 404 500 501 /error.html;

    #### SSL
    ssl on;
    ssl_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$1/privkey.pem;

    ssl_stapling on;
    ssl_stapling_verify on;
    ssl_trusted_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    # Google DNS, Open DNS, Dyn DNS
    resolver 8.8.8.8 8.8.4.4 208.67.222.222 208.67.220.220 216.146.35.35 216.146.36.36 valid=300s;
    resolver_timeout 3s;

    ####    Session Tickets
    # Session Cache doit avoir la même valeur sur tous les blocs \"server\".
    ssl_session_cache shared:SSL:100m;
    ssl_session_timeout 24h;
    ssl_session_tickets on;
    # [ATTENTION] il faudra générer le ticket de session.
    ssl_session_ticket_key /etc/nginx/ssl/ticket.key;

    # [ATTENTION] Les paramètres Diffie-Helman doivent être générés
    ssl_dhparam /etc/nginx/ssl/dhparam4.pem;

    ####    ECDH Curve
    ssl_ecdh_curve secp384r1;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_prefer_server_ciphers on;
    ssl_ciphers 'ECDHE-RSA-AES128-GCM-SHA256:ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-GCM-SHA384:ECDHE-ECDSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:DHE-DSS-AES128-GCM-SHA256:kEDH+AESGCM:ECDHE-RSA-AES128-SHA256:ECDHE-ECDSA-AES128-SHA256:ECDHE-RSA-AES128-SHA:ECDHE-ECDSA-AES128-SHA:ECDHE-RSA-AES256-SHA384:ECDHE-ECDSA-AES256-SHA384:ECDHE-RSA-AES256-SHA:ECDHE-ECDSA-AES256-SHA:DHE-RSA-AES128-SHA256:DHE-RSA-AES128-SHA:DHE-DSS-AES128-SHA256:DHE-RSA-AES256-SHA256:DHE-DSS-AES256-SHA:DHE-RSA-AES256-SHA:!aNULL:!eNULL:!EXPORT:!DES:!RC4:!3DES:!MD5:!PSK';

}" > "$rootFolder"/"$1".conf
fi
}

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "sudo bash ./newServer.bash - create new server web"
      echo " "
      echo "sudo bash ./newServer.bash [options] site domain"
      echo " "
      echo "options:"
      echo "-h, --help                show brief help"
      echo "-n, --name                name of the web site"
      echo "-s, --secure              setup ssl"
      echo "-t, --type=TYPE           static|php|nodejs"
      echo "-p, --port=PORT           port of your app nodejs"
      echo "-ws, --web-socket         active web socket"
      echo "-psw, --password          ftp password"
      exit
      ;;

    -t|--type)
      shift
      if test $# -gt 0; then
        type=$1
      else
        echo "no type specified in -t"
        exit 1
      fi
      shift
      ;;

    -n|--name)
      shift
      if test $# -gt 0; then
        name=$1
      else
        echo "no name specified in -t"
        exit 1
      fi
      shift
      ;;

    -psw|--password)
      shift
      if test $# -gt 0; then
        password=$1
      else
        echo "no password specified in -psw"
        exit 1
      fi
      shift
      ;;

    -p|--port)
      shift
      if test $# -gt 0; then
        processUsePort=$(netstat -ltnp | grep -w ":$1")
        if test -z "$processUsePort"; then
          port=$1
        else
          echo "this port is already use"
          exit 1
        fi
      else
        echo "no port specified in -p"
        exit 1
      fi
      shift
      ;;

    -ws|--web-socket)
      webSocket=true
      shift
      ;;

    -s|--secure)
      secure=true
      shift
      ;;
  esac
done

if test -z "$type" -o -z "$name" -o -z "$password"; then
  echo "-n name and -t type and -psw password required"
  exit 1
else
  if test "$type" = "static"; then
    staticConf "$name" "$secure"
    setupServerCmd "$name" "$password" "$secure"
    exit 1

  elif test "$type" = "nodejs"; then
    if test -z "$port"; then
      echo "port is not define"
      exit 1

    elif test -z "$webSocket"; then
      nodejsVanillaConf "$name" "$port" "$secure"
      setupServerCmd "$name" "$password" "$secure"
      exit 1

    else
      nodejsWSConf "$name" "$port" "$secure"
      setupServerCmd "$name" "$password" "$secure"
      exit 1
    fi

    elif test "$type" = "php"; then
      phpVanillaConf "$name" "$secure"
      setupServerCmd "$name" "$password" "$secure"
      exit 1
  fi
fi
