#!/bin/bash
#backup wiki's files including application directory(/opt/atlassian /var/atlassian) and database (Mysql)
#powered by dc at 2017-02-28,edited at 2018-06-05
#wiki_backup.sh

BACKUP_DIR=/data/backup/wiki/
SH_DIR=/data/scripts/wikibackup/
WIKI_HOME=/opt/atlassian/confluence/
WIKI_PID=`ps uax|grep "/opt/atlassian"|grep -v grep|awk '{print $2}'`
MYSQLBIN_DIR=/usr/bin/
TIME=$(date +%Y%m%d)
TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
TIME_LINE=$(date +%Y-%m-%d)


####### genarate the backup directory #########

[ -d ${BACKUP_DIR}allfiles/var ] && mkdir -p ${BACKUP_DIR}allfiles/var
[ -d ${BACKUP_DIR}allfiles/opt ] && mkdir -p ${BACKUP_DIR}allfiles/opt
[ -d ${BACKUP_DIR}mysql ] && mkdir -p ${BACKUP_DIR}mysql

######### function Wiki Startup ##########
startup_wiki(){
/bin/sh ${WIKI_HOME}bin/startup.sh &>/dev/null
}

################################################# Main progress ####################################

echo "-------------------------${TIME_LINE}---------------------------" > ${SH_DIR}backup.log
echo "start the backup process at ${TIME_MISC}" >> ${SH_DIR}backup.log

####### Stop the wiki ###########

TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
echo "stop the wiki at ${TIME_MISC}" >> ${SH_DIR}backup.log
/bin/sh ${WIKI_HOME}bin/shutdown.sh 1>/dev/null 2>> ${SH_DIR}backup.log
sleep 30
if [  -n "${WIKI_PID}" ]
   then
        /bin/kill -9 ${WIKI_PID}
	TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
	echo "wiki shutdown failed,kill the wiki process directly at ${TIME_MISC}" >> ${SH_DIR}backup.log
fi
       
########### Purge the logs and files of expired on local server #########

find /var/atlassian/application-data/confluence/backups -type f -mtime +0|xargs rm -f
sed -i '/insecure/d' ${SH_DIR}syserror.log
find ${WIKI_HOME}logs -type f -mtime +3 |xargs rm -rf
echo /dev/null > ${WIKI_HOME}logs/catalina.out

########### Purge the backup files of expired on remote server #########

TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
echo "start to purge the old backup tar files on remote server at ${TIME_MISC}" >> ${SH_DIR}backup.log
ssh root@r1sdb "find /backup/wiki -mtime +6 | xargs rm -rf" && ssh root@r1mdb "find /data/backup/wiki -mtime +6 | xargs rm -rf"
if [ $? == 0 ]
  then 
	TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
	echo "purge the old backup tar files success at ${TIME_MISC}" >> ${SH_DIR}backup.log
	TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
	echo "start to backup wiki files and express at ${TIME_MISC}" >> ${SH_DIR}backup.log
########## backup wiki's files ####################
	cp -a /opt/atlassian ${BACKUP_DIR}allfiles/opt/
	cp -a /var/atlassian ${BACKUP_DIR}allfiles/var/
	if [ $? == 0 ]
  		then    
    			TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
        		echo "backup wiki's files success at ${TIME_MISC}" >> ${SH_DIR}backup.log
			TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
			echo "start to backup wiki's mysql at ${TIME_MISC}" >> ${SH_DIR}backup.log
########## backup wiki's database #################
			${MYSQLBIN_DIR}mysqldump -uroot -h 127.0.0.1 -p'123456' -P3306 --default-character-set=utf8 --add-drop-table --routines --triggers --events --extended-insert --all-databases  > ${BACKUP_DIR}mysql/alldb-${TIME}.sql
			if [ $? == 0 ]
			   then
				TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
				echo "backup wiki's mysql success at ${TIME_MISC}" >> ${SH_DIR}backup.log
				TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
				echo "start to express all wiki's backup files at ${TIME_MISC}" >> ${SH_DIR}backup.log
				cd ${BACKUP_DIR}
########## pack the wiki's backup files with TAR ############
				tar -zcf wikibackup_${TIME}.tar.gz allfiles mysql
				if [ $? == 0 ]
				   then
					TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
					echo "express wiki's all files success at ${TIME_MISC}" >> ${SH_DIR}backup.log
					TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
					echo "start to scp all wiki's backup files to r1sdb at ${TIME_MISC}" >> ${SH_DIR}backup.log
########## transfer the backup files to remote server #########
/usr/bin/expect <<EOF
set timeout -1
spawn scp -p ${BACKUP_DIR}wikibackup_${TIME}.tar.gz root@r1sdb:/backup/wiki/
expect eof
EOF
	            
					if [ $? == 0 ]
						then
							TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
							echo "scp all wiki's backup files to r1sdb success at ${TIME_MISC}" >> ${SH_DIR}backup.log
							TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
							echo "start to scp all wiki's backup files to r1mdb at ${TIME_MISC}" >> ${SH_DIR}backup.log
/usr/bin/expect << EOF
set timeout -1
spawn scp -p ${BACKUP_DIR}wikibackup_${TIME}.tar.gz root@r1mdb:/data/backup/wiki/
expect eof
EOF
							if [ $? == 0 ]
								then
									TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
									echo "scp all wiki's backup files to r1mdb success at ${TIME_MISC}" >> ${SH_DIR}backup.log
									TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
									echo "finish the backup process at ${TIME_MISC}" >> ${SH_DIR}backup.log
									rm -rf ${BACKUP_DIR}
########### reboot the wiki service whether the backup process success or not ###############
									startup_wiki
								else
									TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
									echo "scp all wiki's backup files to r1mdb error at ${TIME_MISC}" >> ${SH_DIR}backup.log
									TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
									echo "but scp all wiki's backup files to r1sdb success and stop the backup process at ${TIME_MISC}" >> ${SH_DIR}backup.log
									rm -rf ${BACKUP_DIR}
									startup_wiki
									exit 2
							fi			
						else
							TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
							echo "scp all wiki's backup files to r1sdb error at ${TIME_MISC}" >> ${SH_DIR}backup.log
							TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
							echo "The backup process is unfinished and stopped at ${TIME_MISC}" >> ${SH_DIR}backup.log
							rm -rf ${BACKUP_DIR}
							startup_wiki
							exit 3
					fi
			           else
					TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
					echo "express wiki's all files failed and backup process is unfinished and stopped at ${TIME_MISC}" >> ${SH_DIR}backup.log
					rm -rf ${BACKUP_DIR}
					startup_wiki
					exit 4
				fi
			   else
				TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
				echo "backup wiki's mysql failed and backup process is unfinished and stopped at  ${TIME_MISC}" >> ${SH_DIR}backup.log
				rm -rf ${BACKUP_DIR}
				startup_wiki
				exit 5
			fi
				
		else    
    			TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
        		echo "backup wiki's files failed and backup process is unfinished and stopped at ${TIME_MISC}" >> ${SH_DIR}backup.log
			rm -rf ${BACKUP_DIR}
			startup_wiki
			exit 6
	fi
  else
	TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
	echo "purge the old backup files error at ${TIME_MISC}" >> ${SH_DIR}backup.log
	TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
	echo "The backup process is unfinished and stopped at ${TIME_MISC}" >> ${SH_DIR}backup.log
	startup_wiki
	exit 7
fi
