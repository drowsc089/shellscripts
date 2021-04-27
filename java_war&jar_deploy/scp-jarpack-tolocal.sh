#!/bin/bash
#scp the app jar packet from remote to local directory then deploy
#author:dc


servicename=$1
jar_home=$2

if [ $# -ne '2' ]
   then
        echo "usage:$0 servicename appport"
        exit 2
fi

/usr/bin/expect <<EOF
set timeout -1
spawn scp -P63000 tomcat@aliyun-web2:/data/ci/upload/${servicename}/${servicename}.zip /data/ci/upload/${servicename}/
expect eof
EOF

if [ $? == 0 ]
   then
        /data/ci/script/deploy-jar-service.sh ${servicename} ${jar_home}
   else
        echo "scp found error,check please"
fi
