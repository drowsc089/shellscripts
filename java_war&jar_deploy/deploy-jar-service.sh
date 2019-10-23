#!/bin/bash
#deploy the jar service
#powered by dc at 2018-12-01

SERVICE=$1

servicepath=$2

#JAVA_HOME="/usr/local/jdk1.7.0_79"

uploaddir="/data/ci/upload/${SERVICE}"
backupdir="/data/ci/backup/${SERVICE}"

[ -d $uploaddir ] || mkdir -p $uploaddir
[ -d $backupdir ] || mkdir -p $backupdir

nowtime=`date +%Y%m%d_%H%M%S`

#findservice=`ps -ef |grep "${SERVICE}.jar" |grep -v "grep"`

#killservice() {
#	kill -12 $(echo ${findservice} |awk '{print $2}')
#        [ "$?" = "0" ] || ( echo "$nowtime : kill ${SERVICE} Failed! exit srcipt ..." && exit 2 )
#}

#eval $findservice > /dev/null 2>&1

#if [ -n "$findservice" ]
#then
#	killservice
#fi

cd ${servicepath}
[ -f $uploaddir/${SERVICE}.zip ] || (echo "upload jar pack can not be found" && exit 3)
[ -f ${SERVICE}.jar ] && zip -r ${SERVICE}-${nowtime}.zip ${SERVICE}.jar && mv ${SERVICE}-${nowtime}.zip ${backupdir}/ || (echo "backup old jar pack error" && exit 4)
sh ${SERVICE}.sh stop
rm -f ${SERVICE}.jar
[ -d logs ] && find logs/ -type f -mtime +3 | xargs rm -rf
[ -d lib ] && rm -rf lib
[ -d ${SERVICE}_lib ] && rm -rf ${SERVICE}_lib
unzip ${uploaddir}/${SERVICE}.zip -d ${servicepath} &> /dev/null || (echo "unzip new jar pack error" && exit 5)
sh ${SERVICE}.sh restart


cd ${backupdir} && ls -t ${backupdir} | awk '{if(NR>3){print $0}}' |xargs rm -f > /dev/null 2>&1

