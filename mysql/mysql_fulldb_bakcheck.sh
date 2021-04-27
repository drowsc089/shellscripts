#!/bin/bash
#check whether the aliyun-mdb mysql all databases backup files decompress normally
#WARNING!!: Please add the ssh key of user named tomcat for auto login to destination host
#author:dc
#Name:mysql_fulldb_bakcheck.sh


SH_HOME=/data/script/mysqlmdballbak_check/
WORK_DIR=/data/backup/mysql/daybackup_frommdb/

REMOTE_LOG_DIR=/data/scripts/alldatabak_check_report/

BAK_TIME=`date +%Y%m%d`

cd ${WORK_DIR}
        echo "-------------------- aliyun-sdb mysql mdb all databases backup from aliyun-mdb check -------------------" > ${SH_HOME}sdbmysqlmdballbak_check.log
        echo "" >> ${SH_HOME}sdbmysqlmdballbak_check.log
/bin/tar -zxf alldb_${BAK_TIME}.tar.gz
if [ $? == 0 ]
   then
        echo "aliyun-sdb mysql mdb alldatabases backup decompression successed" >> ${SH_HOME}sdbmysqlmdballbak_check.log
        echo "" >> ${SH_HOME}sdbmysqlmdballbak_check.log
	ls -ltr|grep -v "total"|grep -v "alldb-${BAK_TIME}.sql" >> ${SH_HOME}sdbmysqlmdballbak_check.log
        echo "" >> ${SH_HOME}sdbmysqlmdballbak_check.log
	du -sh alldb-${BAK_TIME}.sql >> ${SH_HOME}sdbmysqlmdballbak_check.log
/usr/bin/expect <<EOF
set timeout 3600
spawn scp -P63000 ${SH_HOME}sdbmysqlmdballbak_check.log tomcat@aliyun-web3:${REMOTE_LOG_DIR}
expect eof
EOF
        [ $? != 0 ] && NOW_TIME=`date +%Y-%m-%d_%H:%M:%S` &&  echo "scp sdbmysqlmdballbak_check.log failed at ${NOW_TIME}" > ${SH_HOME}error.log
        rm -f ${WORK_DIR}alldb-${BAK_TIME}.sql
   else
        echo "aliyun-sdb mysql mdb all databases backup decompression failed , CHECK please" > ${SH_HOME}sdbmysqlmdballbak_check.log
        echo "" >> ${SH_HOME}sdbmysqlmdballbak_check.log
	ls -ltr|grep -v "total"|grep -v "alldb-${BAK_TIME}.sql" >> ${SH_HOME}sdbmysqlmdballbak_check.log
        echo "" >> ${SH_HOME}sdbmysqlmdballbak_check.log
	[ -f ${WORK_DIR}alldb-${BAK_TIME}.sql ] && du -sh alldb-${BAK_TIME}.sql >> ${SH_HOME}sdbmysqlmdballbak_check.log
/usr/bin/expect <<EOF
set timeout 3600
spawn scp -P63000 ${SH_HOME}sdbmysqlmdballbak_check.log tomcat@aliyun-web3:${REMOTE_LOG_DIR}
expect eof
EOF
        [ $? != 0 ] && NOW_TIME=`date +%Y-%m-%d_%H:%M:%S` &&  echo "scp sdbmysqlmdballbak_check.log failed at ${NOW_TIME}" > ${SH_HOME}error.log
        [ -f ${WORK_DIR}alldb-${BAK_TIME}.sql ] && rm -f ${WORK_DIR}alldb-${BAK_TIME}.sql
fi
