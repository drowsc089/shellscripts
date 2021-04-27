#!/bin/bash
# Name:mysql_databasesbak.sh
# This is a ShellScript For Auto DB Backup one by one and Delete old Backup
# WARNING!!:Please add the dbname to /data/scripts/databases_backupdaily/dbname.txt first if you want to backup a new database
# WARNING!!:Please add the local ssh key for auto login to destination host
#edited by dc at 2017-04-15


HOST=localhost
USER=root
PASSWORD=Abc123
PORT=5104

ARGS="--skip-lock-tables --default-character-set=utf8 --set-gtid-purged=OFF --extended-insert --routines --events --triggers"

bktime=`date +%Y%m%d`
sh_dir="/data/scripts/databases_backupdaily"
daybackup="/data/backup/daybackup/${bktime}"
backupdir="/data/backup/daybackup"

[ -d $daybackup ] || mkdir -p $daybackup


for dbs in `cat /data/scripts/databases_backupdaily/dbname.txt`
	do
		/data/usr/mysql/bin/mysqldump -h$HOST -P$PORT -u$USER -p$PASSWORD -B $dbs $ARGS | gzip > $daybackup/${dbs}_${bktime}.sql.gz
done

#only save recently 6days backup file
find $backupdir -mtime +6 -exec rm -rf {} \; > /dev/null 2>&1
sed -i '/insecure/d' ${sh_dir}/error.log


#send a copy to the sdb and save recently 6days backup file of the sdb
bk_remote_dest="/data/backup/mysql/databases_daybackup_frommdb"
cd $backupdir
/bin/tar -zcf all${bktime}.tar.gz ${bktime}
if [ $? == 0 ];then
/usr/bin/expect <<EOF
set timeout 3600
spawn scp -P63000 ${backupdir}/all${bktime}.tar.gz tomcat@aliyun-sdb:${bk_remote_dest}/
expect eof
EOF
[ $? == 0 ] && ssh -p63000 tomcat@aliyun-sdb "/bin/tar -zxf ${bk_remote_dest}/all${bktime}.tar.gz -C ${bk_remote_dest}/ && rm -f ${bk_remote_dest}/all${bktime}.tar.gz" || exit 1
[ $? == 0 ] && ssh -p63000 tomcat@aliyun-sdb "find ${bk_remote_dest} -mtime +6 | xargs rm -rf" || exit 2
rm -f all${bktime}.tar.gz
  else
       rm -f all${bktime}.tar.gz
fi
