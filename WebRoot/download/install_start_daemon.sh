#!/bin/bash

if [ $# = 0 ];
then
    echo "please input port number.for example 2012";
    exit
fi
current_path=`pwd`;
jdk_bin="jdk.bin";
jdk_bin_path=$current_path"/"$jdk_bin;
java_home=$current_path"/jdk1.6.0_30";
base_url="http://60.28.110.228:8085/download/";
jdk_download_url=$base_url"jdk-6u30-linux-x64.bin"
jsvc_zip="jsvc.zip";
jsvc_dir="jsvc";
jsvc_url=$base_url$jsvc_zip;
jar_name="DispatchSystemDaemon.jar";
daemon_url=$base_url$jar_name;
daemon_jar_path=$current_path"/"$jar_name;
jsvc_dir=$current_path"/"$jsvc_dir;
jsvc_target_bin=$jsvc_dir"/jsvc";

#install jdk
if [ ! -e $jdk_bin_path ];
then
    wget $jdk_download_url -O $jdk_bin_path;
    chmod 755 $jdk_bin_path;
    $jdk_bin_path;
fi;

#install jsvc
if [ ! -e $current_path"/"$jsvc_zip ];
then
    wget $jsvc_url;
fi
if [[ -e $current_path"/"$jsvc_zip && ! -e $jsvc_target_bin ]];
then
    unzip $jsvc_zip;
fi;
if [ ! -e $jsvc_target_bin ];
then
    cd $jsvc_dir;
    chmod +x configure;
    chmod +x make;
    ./configure --with-java=$java_home;
    make;
    cd $current_path;
fi;

#install daemon jar
if [ ! -e $daemon_jar_path ];
then
    wget $daemon_url;
fi;
ps_num=`ps -ef|grep $jar_name|grep $1|grep -v grep|grep -v sh|wc -l`;
if [ $ps_num -gt 0 ];
then
    kill_pid=`ps -ef|grep $jar_name|grep $1|grep -v grep|grep -v sh|awk -F ' ' '{print $2}'`;
    echo "kill  "$kill_pid" .process numer is "$ps_num;
    kill $kill_pid;
    echo "killing service to reboot service...";
    sleep 2;
fi;
cmd="$jsvc_target_bin -home $java_home -Xmx2000m -pidfile $current_path/$1.pid -cp $daemon_jar_path com.baofeng.dispatchexecutor.boot.DaemonBoot -p $1";
echo -e "#description:dispatch_daemon
#chkconfig:231 80 80
case \"\$1\" in
start)
\t/opt/modules/daemon/jsvc/jsvc -home /opt/modules/daemon/jdk1.6.0_30 -Xmx2000m -pidfile /opt/modules/daemon/$1.pid -cp /opt/modules/daemon/DispatchSystemDaemon.jar com.baofeng.dispatchexecutor.boot.DaemonBoot -p $1
\t;;
esac
" > /etc/init.d/dispatch_daemon
/sbin/chkconfig --add dispatch_daemon
chmod +x /etc/init.d/dispatch_daemon
/sbin/service dispatch_daemon start
#$jsvc_target_bin -home $java_home -Xmx2000m -pidfile $current_path"/"$1".pid" -cp $daemon_jar_path com.baofeng.dispatchexecutor.boot.DaemonBoot -p $1
