#!/bin/bash

secure=false
rootFolder="conf.d"

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
      exit 0
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
    echo "server {

  listen 80;
  server_name $name;

  # Les urls commençant par / (toutes les urls)
  location / {
      root /home/prod/$name/www;
      index index.html index.htm;
      try_files \$uri \$uri/ \$uri.html =404;
  }

  # Les urls contennant /. (dotfiles)
  location ~ /\. {
      deny all;
      access_log off;
      log_not_found off;
  }

  # On va placer les logs dans un dossier accessible
  error_log /home/prod/$name/logs/error.log;
  access_log /home/prod/$name/logs/acess.log;

  # Les pages d'erreurs
  error_page 404 500 501 /error.html;

}

server {
  # On redirige les www. vers la version sans www
  listen 80;
  server_name www.$name;
  return 301 http://$name\$request_uri;
}" > "$rootFolder"/"$name".conf

    cmd "$(sudo mkdir /home/prod/"$name"/www)"
    cmd "$(sudo mkdir /home/prod/"$name"/logs)"

    cmd "$(sudo nginx -t)"
    cmd "$(sudo service nginx restart)"
    exit 1

  elif test "$type" = "nodejs"; then
    if test -z "$port"; then
      echo "port is not define"
      exit 1

    elif test -z "$webSocket"; then
      echo "upstream $name {
  server localhost:$port;
}

server {

  listen 80;
  listen [::]:80;
  server_name $name;

  location / {
      proxy_pass http://$name;
  }
}" > "$rootFolder"/"$name".conf

      cmd "$(pm2 start /home/prod/"$name"/serverjs)"
      cmd "$(sudo nginx -t)"
      cmd "$(sudo service nginx restart)"
      exit 1

    else
      echo "upstream $name {
    server localhost:$port;
}

server {

    listen 80;
    listen [::]:80;
    server_name $name;

    location / {
        proxy_pass http://$name;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection \"upgrade\";
    }
}" > "$rootFolder"/"$name".conf

      cmd "$(sudo mkdir /home/prod/"$name")"
      cmd "$(pm2 start /home/prod/"$name"/server.js)"
      cmd "$(sudo nginx -t)"
      cmd "$(sudo service nginx restart)"
      exit 1
    fi

    elif test "$type" = "php"; then
      echo "" > "$rootFolder"/"$name".conf

      md "$(sudo mkdir /home/prod/"$name")"
      cmd "$(pm2 start /home/prod/"$name"/server.js)"
      cmd "$(sudo nginx -t)"
      cmd "$(sudo service nginx restart)"
      exit 1
  fi
fi
