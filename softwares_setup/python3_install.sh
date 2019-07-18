#!/bin/bash
#for install python3 with sourcecode on server automaticly
#powered by dc at 2017-05-25
#python3_install.sh


SH_HOME="/data/scripts/python3_install/"


[ ! -d ${SH_HOME} ] && mkdir -p ${SH_HOME}
[ -f ${SH_HOME}run.log ] && rm -f ${SH_HOME}run.log


yum install -y zlib-devel bzip2-devel openssl openssl-lib openssl-devel ncurses-devel sqlite-devel readline-devel tk-devel gcc make

wget -P /data/src/ https://www.python.org/ftp/python/3.6.1/Python-3.6.1.tgz

if [ $? == '0' ]
   then
	tar -zxf /data/src/Python-3.6.1.tgz -C /data/src/
	if [ $? == '0' ]
	   then
		[ ! -d /data/usr/python3 ] && mkdir -p /data/usr/python3
		cd /data/src/Python-3.6.1
		./configure --prefix=/data/usr/python3
		#使用系统CPU虚拟核一半减2的数量的CPU进行编译
		pro_num=$(cat /proc/cpuinfo |grep processor|wc -l)
		let make_pro_num=${pro_num}/2-2
		make -j ${make_pro_num}
		if [ $? == '0' ]
		   then
			make install
			if [ $? == '0' ]
			   then
				echo "" >> /etc/profile
				echo "# python3" >> /etc/profile
				echo 'PATH=$PATH:/data/usr/python3/bin' >> /etc/profile
				source /etc/profile
				/bin/ln -s /data/usr/python3/bin/python3.6 /usr/bin/python3
				/bin/rm -rf /data/src/Python-3.6.1
			   else
				echo "sourcecode make install error" >> ${SH_HOME}run.log
				exit 1
			fi
		   else
			echo "sourcecode make error" >> ${SH_HOME}run.log
			exit 2
		fi
	   else
		echo "decompress Python-3.6.1.tgz error" >> ${SH_HOME}run.log
		exit 3
	fi
   else
	echo "wget download source code error" >> ${SH_HOME}run.log
	exit 4
fi				
