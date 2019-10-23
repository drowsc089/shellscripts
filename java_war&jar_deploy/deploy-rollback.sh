#!/bin/bash

SERVICE=$1
PORT=$2

if [ $# != 2 ] ; then
        echo "USAGE: $0 service-name port"
        exit 1;
fi

#ssh -p 63000 tomcat@aliyun-web1 "sh /data/ci/script/deploy-switch-nginx-tolocal.sh ${SERVICE} ${PORT}"
#sleep 3
#sh /data/ci/script/deploy-switch-nginx-toremote.sh $SERVICE $PORT

uploaddir="/data/ci/upload/${SERVICE}"
backupdir="/data/ci/backup/${SERVICE}"

rm -f /data/www/${SERVICE}_bondwebapp_com/webroot/${SERVICE}.war
rm -f ${uploaddir}/${SERVICE}.war

lastwarfile=`ls -t /data/ci/backup/${SERVICE}/ |head -n 1`

cp ${backupdir}/${lastwarfile} ${uploaddir}/${SERVICE}.war && sh /data/ci/script/deploy-web.sh $SERVICE $PORT

#sh /data/ci/script/deploy-switch-nginx-tolocal.sh $SERVICE $PORT
