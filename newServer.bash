#!/bin/bash

secure=false

while test $# -gt 0; do
  case "$1" in
    -h|--help)
      echo "$package - attempt to capture frames"
      echo " "
      echo "$package [options] site domain"
      echo " "
      echo "options:"
      echo "-h, --help                show brief help"
      echo "-t, --type=TYPE           static|php|nodejs"
      echo "-p, --port=PORT           port on this server listen"
      echo "-s, --secure              setup ssl"
      exit 0
      ;;

    -t|--type)
      shift
      if test $# -gt 0; then
        type=$1
      else
        echo "no type specified"
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
        echo "no type specified"
        exit 1
      fi
      shift
      ;;

    -s|--secure)
      secure=true
      shift
      ;;
  esac
done