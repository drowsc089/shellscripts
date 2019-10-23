#!/bin/bash

SERVICE=$1
PORT=$2

if [ $# != 2 ] ; then
	echo "USAGE: $0 service-name port"
	exit 1;
fi 

nginx_conf_file="/etc/nginx/conf.d/${SERVICE}.bondwebapp.com.conf"
localserver_alias="aliyun-web1"
remoteserver_alias="aliyun-web2"


grep "${localserver_alias}" ${nginx_conf_file}
if [ $? = '0' ];then
        sed -i "s/${localserver_alias}/${remoteserver_alias}/" $nginx_conf_file && sudo /etc/init.d/nginx reload
else
        grep "${remoteserver_alias}" $nginx_conf_file || ( echo "conf file error." && exit 2 )
fi
