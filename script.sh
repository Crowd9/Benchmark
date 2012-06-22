#!/bin/bash

echo "
################################################################################
#               ServerBear (http://serverbear.com) benchmarker                 #
################################################################################

This script will:
  * Download and install packages to run UnixBench
  * Download and run UnixBench
  * Upload to ServerBear the UnixBench output and information about this computer

This script has been tested on Ubuntu, Debian, and CentOs.  Running it on other environments not work correctly.

To improve consistency, we recommend that you stop any services you may be running (e.g. web server, database, etc) to get the environment as close as possible to the original configuration.

WARNING: You run this script entirely at your own risk.
ServerBear accepts no responsibility for any damage this script may cause.

Please review the code at https://github.com/Crowd9/Benchmark if you have any concerns

If you accept these conditions: please type \"yes\" to continue"
read ACCEPTED
if [ "$ACCEPTED" != 'yes' ]; then
  echo "You must type 'yes' to accept the conditons to execute this script.  Exiting..."
  exit 1
fi


echo "Checking for required dependencies"

function requires() {
  if [ `$1 >/dev/null; echo $?` -ne 0 ]; then
    TO_INSTALL="$TO_INSTALL $2"
  fi 
}
function requires_command() { 
  requires "which $1" $1 
}

TO_INSTALL=""

if [ `which apt-get >/dev/null 2>&1; echo $?` -ne 0 ]; then
  PACKAGE_MANAGER='yum'

  requires 'yum list installed kernel-devel' 'kernel-devel'
  requires 'yum list installed gcc-c++' 'gcc-c++'
else
  PACKAGE_MANAGER='apt-get'
  MANAGER_OPTS='--fix-missing'
  UPDATE='apt-get update'

  requires 'dpkg -s build-essential' 'build-essential'
fi

requires 'perl -MTime::HiRes -e 1' 'perl-Time-HiRes'

requires_command 'gcc'
requires_command 'make'

if [ "$TO_INSTALL" != '' ]; then
  echo "Using $PACKAGE_MANAGER to install$TO_INSTALL"
  if [ "$UPDATE" != '' ]; then
    echo "Doing package update"
    sudo $UPDATE
  fi 
  sudo $PACKAGE_MANAGER install -y $TO_INSTALL $MANAGER_OPTS
fi 

PID=`cat .sb-pid 2>/dev/null`
UNIX_BENCH_VERSION='5.1.3'
UNIX_BENCH_DIR=UnixBench-$UNIX_BENCH_VERSION
UPLOAD_ENDPOINT='http://promozor.com/uploads.text'

if [ -e "`pwd`/.sb-pid" ] && ps -p $PID >&- ; then
  echo "ServerBear job is already running (PID: $PID)"
  exit 0
fi

cat > run-upload.sh << EOF
#!/bin/sh

rm -rf UnixBench

if ! [ -e "`pwd`/$UNIX_BENCH_DIR" ]; then
  echo "Getting UnixBench $UNIX_BENCH_VERSION..."
  curl -s https://byte-unixbench.googlecode.com/files/UnixBench5.1.3.tgz | tar -xz
  mv UnixBench $UNIX_BENCH_DIR
fi

echo "Running UnixBench as a background task."
echo "This can take several hours.  ServerBear will email you when it's done."
echo "You can log out/Ctrl-C any time while this is happening (it's running through nohup)."

cd $UNIX_BENCH_DIR
echo "distro: " > sb-output.log
cat /etc/issue >> sb-output.log
echo "disk space: " >> sb-output.log
df --total >> sb-output.log
echo "free: " >> sb-output.log
free >> sb-output.log

./Run >> sb-output.log 2> sb-error.log

RESPONSE=\`curl -s -F "upload[upload_type]=unix-bench-output" -F "upload[data]=<sb-output.log" -F "upload[key]=$SBK" $UPLOAD_ENDPOINT\`
RESPONSE=\`curl -s -F "upload[upload_type]=unix-bench-error" -F "upload[data]=<sb-error.log" -F "upload[key]=$SBK" $UPLOAD_ENDPOINT\`

echo "Uploading results..."
echo "Response: \$RESPONSE"
echo "Done"

exit 0
EOF

chmod u+x run-upload.sh

nohup ./run-upload.sh > sb-script.log 2>&1 >/dev/null

echo $! > .sb-pid

tail -f sb-script.log
