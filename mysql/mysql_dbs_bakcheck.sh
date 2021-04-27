#!/bin/bash
#check whether the aliyun-mdb mysql single databases backup files decompress normally and send a report to aliyun-web3
#WARNING!!: Please add the ssh key of user named tomcat for auto login to destination host. 
#WARNING!!: Please notice that you should add all the database name to /data/scripts/databases_backupdaily/dbname.txt if you want to check
#powered by dc at 2017-05-02
#NAME:mysql_dbs_bakcheck.sh


BAK_TIME=`date +%Y%m%d`
YESTERDAY_TIME=`date -d"1 day ago" +%Y%m%d`
SH_HOME=/data/scripts/mysqlmdbdatabasesbak_check/
WORK_DIR=/data/backup/daybackup/${BAK_TIME}/
YESTERDAY_WORK_DIR=/data/backup/daybackup/${YESTERDAY_TIME}/

REMOTE_LOG_DIR=/data/scripts/alldatabak_check_report/

[ -f ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log ] && rm -f ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log


cd ${WORK_DIR}


echo "---------------------------- aliyun-mdb mysql mdb single databases backup from local check --------------------------" > ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
echo "" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log

for dbs in `cat /data/scripts/databases_backupdaily/dbname.txt`
    do
	/bin/gzip -dc ${dbs}_${BAK_TIME}.sql.gz > ${dbs}_${BAK_TIME}.sql
if [ $? == 0 ]
   then
        echo "aliyun-mdb mysql mdb single database backup ${dbs}_${BAK_TIME}.sql.gz decompression successed" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
   else
        echo "aliyun-mdb mysql mdb single database backup ${dbs}_${BAK_TIME}.sql.gz decompression failed , CHECK please" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
fi
done

echo "" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
echo "---------------------------- `date -d"1 day ago" +%F` --------------------------" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
echo "" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
ls -ltr ${YESTERDAY_WORK_DIR} |grep -v "total">> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
echo "" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
echo "---------------------------- `date +%F` --------------------------" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
echo "" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
ls -ltr|grep -v "total"|grep -vE "*.sql$" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
echo "" >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
du -sh *.sql >> ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log
find ${WORK_DIR} -name "*.sql"|xargs rm -f

/usr/bin/expect <<EOF
set timeout 3600
spawn scp -P63000 ${SH_HOME}mdb_mysqlmdbdatabasesbak_check.log tomcat@aliyun-web3:${REMOTE_LOG_DIR}
expect eof
EOF
        [ $? != 0 ] && NOW_TIME=`date +%Y-%m-%d_%H:%M:%S` && echo "scp mdb_mysqlmdbdatabasesbak_check.log failed at ${NOW_TIME}" > ${SH_HOME}error.log
