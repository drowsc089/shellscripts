#!/bin/bash

#myservice="haolaoshi"
#serviceport="8805"
if [ $# -ne '2' ];then
	echo "arg is not 2"
	exit 2
fi
myservice=$1
serviceport=$2
CATALINA_HOME="/data/usr/tomcat-[a-z]-${myservice}-${serviceport}"
webroot="/data/www/${myservice}_bondwebapp_com/webroot"
#webroot="${CATALINA_HOME}/webapps"
webrootwar="${webroot}/${myservice}.war"

#JAVA_HOME="/usr/local/jdk1.7.0_79"

uploaddir="/data/ci/upload/${myservice}"
backupdir="/data/ci/backup/${myservice}"
deploylog="/data/ci/logs/deploy.log"

[ -d $uploaddir ] || mkdir -p $uploaddir
[ -d $backupdir ] || mkdir -p $backupdir
[ -d $webroot ] || ( mkdir -p $webroot || exit 2 )
[ -f $deploylog ] || touch $deploylog

nowtime=`date +%Y%m%d_%H%M%S`
findservice="ps -ef |grep 'Dcatalina.home=${CATALINA_HOME=}' |grep -v 'grep'"

killservice() {
	kill -9 `eval ${findservice} |awk '{print $2}'` && echo "$nowtime : killed service!" >> $deploylog
        [ "$?" = "0" ] || ( echo "$nowtime : kill ${myservice} Failed! exit srcipt ..." >> $deploylog && exit 2 )
}

echo "$nowtime : ------****** begining deploy ${myservice} ******------" >> $deploylog
	eval $findservice > /dev/null 2>&1
	if [ "$?" = "0" ];then
		serviceuser=`eval ${findservice=} |awk '{print $1}'`
		[ $serviceuser = 'tomcat' ] || exit 2
		nc -z localhost $serviceport > /dev/null 2>&1
		if [ "$?" = "0" ];then
			#echo "service is running!"
			echo "$nowtime : try to stop $myservice ..." >> $deploylog
			cd $CATALINA_HOME && sh bin/shutdown.sh
			eval $findservice > /dev/null 2>&1 && killservice
			#return 0
		else
			#echo "service is unstable!"
			killservice
			#return 2
		fi
	else
		#echo "service is not running!"
		echo "$nowtime : ${myservice} is not running ..." >> $deploylog 
		#return 1
	fi

	echo "$nowtime : clean $myservice cache ..." >> $deploylog
	cd $CATALINA_HOME
	rm -rf webapps/* && rm -rf work/*
	#rm -rf webapps/*
	[ $? = "0" ] || echo "$nowtime : clean $myservice cache Failed ..." >> $deploylog

	echo "$nowtime : try to backup $myservice to $backupdir ..." >> $deploylog
	backupwar="${backupdir}/${myservice}.war-${nowtime}"
	cd $CATALINA_HOME 
	[ -f $webrootwar ] && mv $webrootwar $backupwar
	[ $? = "0" ] && echo "$nowtime : backup ${myservice} to ${backupdir} success ..." >> $deploylog

	echo "$nowtime : copy new ${myservice}.war to webapps dir ..." >> $deploylog
	newwar="${uploaddir}/${myservice}.war"
	[ -f $newwar ] && cp $newwar $webroot
	[ $? = "0" ] || ( echo "$nowtime : copy new ${myservice}.war Failed! exit script ..." >> $deploylog && exit 2 )

	echo "$nowtime : start ${myservice} ..." >> $deploylog
	cd $CATALINA_HOME
	sh bin/startup.sh
	[ $? = "0" ] && echo "$nowtime : deploy ${myservice} done ..." >> $deploylog

	cd ${backupdir} && ls -t ${backupdir} | awk '{if(NR>7){print $0}}' |xargs rm -f > /dev/null 2>&1
