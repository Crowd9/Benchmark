#!/bin/sh

echo "Checking for required dependencies"

TO_INSTALL=""

if [ `perl -MTime::HiRes -e 1 2>/dev/null; echo $?` -ne 0 ]; then
  TO_INSTALL="$TO_INSTALL perl-Time-HiRes"
fi

if [ `which make 2>/dev/null; echo $?` -ne 0 ]; then
  TO_INSTALL="$TO_INSTALL make"
fi

if [ $TO_INSTALL != '' ]; then
  echo "Using yum to install$TO_INSTALL"
  yum install -y $TO_INSTALL
fi 


PID=`cat .pid 2>/dev/null`
UNIX_BENCH_VERSION='5.1.3'
UNIX_BENCH_DIR=UnixBench-$UNIX_BENCH_VERSION
UPLOAD_ENDPOINT='http://promozor.com/uploads.text'

if [ -e "`pwd`/.pid" ] && ps -p $PID >&- ; then
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

nohup ./run-upload.sh > sb-script.log &

echo $! > .pid

tail -f sb-script.log
