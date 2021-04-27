#!/bin/bash
#backup local database per day
#WARNING!!: Please add the local ssh key for auto login to destination host
#author:dc
#NAME: mysql_fulldb_bak

BACKUP_DIR=/data/backup/alldb_backup_temp/
SH_DIR=/data/scripts/alldb_backupdaily/
MYSQLBIN_DIR=/data/usr/mysql/bin/
TIME=$(date +%Y%m%d)
TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
TIME_LINE=$(date +%Y-%m-%d)



echo "--------------------------------${TIME_LINE}-----------------------------" >> ${SH_DIR}backup.log
echo "start to backup process at ${TIME_MISC}" >> ${SH_DIR}backup.log
TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
echo "begin to clean the old tar files at ${TIME_MISC}" >> ${SH_DIR}backup.log
ssh -p63000 tomcat@aliyun-sdb "find /data/backup/mysql/daybackup_frommdb -type f -mtime +6 | xargs rm -f" && \
ssh -p63000 tomcat@aliyun-web3 "find /data/backup/mysql/daybackup_frommdb -type f -mtime +6 | xargs rm -f"
if [ $? == 0 ]
  then 
	TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
	echo "clean the old backup success at ${TIME_MISC}" >> ${SH_DIR}backup.log
	TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
	echo "begin to backup mysql at ${TIME_MISC}" >> ${SH_DIR}backup.log
	${MYSQLBIN_DIR}mysqldump -uroot  -p'Abc123' -P5104 --default-character-set=utf8 --add-drop-table --routines --triggers --events --extended-insert --all-databases  > ${BACKUP_DIR}alldb-${TIME}.sql
	if [ $? == 0 ]
  		then
    			TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
        		echo "mysqldump success at ${TIME_MISC}" >> ${SH_DIR}backup.log
			cd ${BACKUP_DIR}
    			TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
        		echo "begin to express file at ${TIME_MISC}" >> ${SH_DIR}backup.log
    			tar -zcf alldb_${TIME}.tar.gz alldb-${TIME}.sql
    			if [ $? == 0 ]
     			  then
					TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
					echo "tar express file success at ${TIME_MISC}" >> ${SH_DIR}backup.log
					TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
					echo "begin to scp backup file to aliyun-sdb at ${TIME_MISC}" >> ${SH_DIR}backup.log
/usr/bin/expect <<EOF
set timeout 3600
spawn scp -P63000 ${BACKUP_DIR}alldb_${TIME}.tar.gz tomcat@aliyun-sdb:/data/backup/mysql/daybackup_frommdb/
expect eof
EOF
	            
					if [ $? == 0 ]
						then
							TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
							echo "scp backup file to aliyun-sdb success at ${TIME_MISC}" >> ${SH_DIR}backup.log
							TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
							echo "start to scp backup file to aliyun-web3  at ${TIME_MISC}" >> ${SH_DIR}backup.log
/usr/bin/expect <<EOF
set timeout 3600
spawn scp -P63000 ${BACKUP_DIR}alldb_${TIME}.tar.gz tomcat@aliyun-web3:/data/backup/mysql/daybackup_frommdb/
expect eof
EOF
						 	if [ $? == 0 ]
								then
									TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
									echo "scp backup file to aliyun-web3 success at ${TIME_MISC}" >> ${SH_DIR}backup.log
									TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
									echo "finish all the backup process at ${TIME_MISC}" >> ${SH_DIR}backup.log
									rm -rf ${BACKUP_DIR}alldb_${TIME}.tar.gz ${BACKUP_DIR}alldb-${TIME}.sql
									[ -f ${SH_DIR}error.log ] && sed -i '/insecure/d' ${SH_DIR}error.log
								else
									TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
									echo "scp backup file to aliyun-web3 error at ${TIME_MISC}" >> ${SH_DIR}backup.log
									TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
									echo "but scp backup file to aliyun-sdb success and close the process at ${TIME_MISC}" >> ${SH_DIR}backup.log
									rm -rf ${BACKUP_DIR}alldb_${TIME}.tar.gz ${BACKUP_DIR}alldb-${TIME}.sql
									[ -f ${SH_DIR}error.log ] && sed -i '/insecure/d' ${SH_DIR}error.log
									exit 2
							fi
						else
							TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
							echo "scp backup file to aliyun-sdb error at ${TIME_MISC}" >> ${SH_DIR}backup.log
							exit 3
					fi
				  else
					TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
					echo "tar file error at ${TIME_MISC}" >> ${SH_DIR}backup.log
					exit 4
				fi
		else 
				TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
				echo "mysqldump error at ${TIME_MISC}" >> ${SH_DIR}backup.log
				exit 5
	fi
  else
	TIME_MISC=$(date +%Y-%m-%d_%H:%M:%S)
	echo "clean the old backup error at ${TIME_MISC}" >> ${SH_DIR}backup.log
	exit 6
fi
echo "--------------------------------${TIME_LINE}-----------------------------" >> ${SH_DIR}backup.log
