#!/bin/bash
#scp the app war packet from remote to local directory then deploy
#powered by dc at 2018-10-24


servicename=$1
appport=$2

if [ $# -ne '2' ]
   then
        echo "usage:$0 servicename appport"
        exit 2
fi

/usr/bin/expect <<EOF
set timeout -1
spawn scp -P63000 tomcat@aliyun-web2:/data/ci/upload/${servicename}/${servicename}.war /data/ci/upload/${servicename}/
expect eof
EOF

if [ $? == 0 ]
   then
        /data/ci/script/deploy-web.sh ${servicename} ${appport}
   else
        echo "scp found error,check please"
fi
