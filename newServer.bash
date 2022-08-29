#!/bin/bash

secure=false
rootFolder="conf.d"



function setupServerCmd() {
  sudo mkdir /home/prod/"$name"/www
  sudo mkdir /home/prod/"$name"/logs
  sudo service nginx restart
  adduser "$1"
  sudo service proftpd restart
}

function staticConf() {
  echo "server {

    listen 80;
    server_name $1;

    location / {
        root /home/prod/$1/www;
        index index.html index.htm;
        try_files \$uri \$uri/ \$uri.html =404;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    error_log /home/prod/$1/logs/error.log;
    access_log /home/prod/$1/logs/acess.log;

    error_page 404 500 501 /error.html;

}

server {
    listen 80;
    server_name www.$1;
    return 301 http://$1\$request_uri;
}" > "$rootFolder"/"$1".conf
}

function nodejsVanillaConf() {
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

    error_log /home/prod/$1/logs/error.log;
    access_log /home/prod/$1/logs/acess.log;

    error_page 404 500 501 /error.html;

}

server {
    listen 80;
    server_name www.$1;
    return 301 http://$1\$request_uri;
}" > "$rootFolder"/"$1".conf

}

function nodejsWSConf() {
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

    error_log /home/prod/$1/logs/error.log;
    access_log /home/prod/$1/logs/acess.log;

    error_page 404 500 501 /error.html;

}

server {
    listen 80;
    server_name www.$1;
    return 301 http://$1\$request_uri;
}" > "$rootFolder"/"$1".conf

}

function phpVanillaConf() {
echo "server {

    listen 80;
    server_name $name;

    index index.php index.html index.htm;

    location / {
        root /home/prod/$name/www;
        index index.html index.htm;
        try_files \$uri \$uri/ \$uri.html =404;
    }

    location ~ /\. {
        deny all;
        access_log off;
        log_not_found off;
    }

    location ~ \.php$ {
        try_files \$uri =404;
        fastcgi_pass unix:/var/run/php8-fpm.sock;
        fastcgi_index index.php;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
        include fastcgi_params;
    }

    error_log /home/prod/$name/logs/error.log;
    access_log /home/prod/$name/logs/acess.log;

    error_page 404 500 501 /error.html;

}

server {
    listen 80;
    server_name www.$name;
    return 301 http://$name\$request_uri;
}" > "$rootFolder"/"$name".conf

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

if test -z "$type" -a -z "$name"; then
  echo "-n name and -t type required"
  exit 1
else
  if test "$type" = "static"; then
    staticConf "$name"
    setupServerCmd "$name"
    exit 1

  elif test "$type" = "nodejs"; then
    if test -z "$port"; then
      echo "port is not define"
      exit 1

    elif test -z "$webSocket"; then
      nodejsVanillaConf "$name" "$port"
      setupServerCmd "$name"
      exit 1

    else
      nodejsWSConf "$name" "$port"
      setupServerCmd "$name"
      exit 1
    fi

    elif test "$type" = "php"; then
      phpVanillaConf "$name"
      setupServerCmd "$name"
      exit 1
  fi
fi