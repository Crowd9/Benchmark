#!/bin/sh

PID=`cat .pid`
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
echo "distro: " > sz-output.log
cat /etc/issue >> sz-output.log
echo "disk space: " >> sz-output.log
df --total >> sz-output.log
echo "free: " >> sz-output.log
free >> sz-output.log

./Run >> sz-output.log 2> sz-error.log

RESPONSE=\`curl -s -F "upload[upload_type]=unix-bench-output" -F "upload[data]=<sz-output.log" -F "upload[key]=$SZK" $UPLOAD_ENDPOINT\`
RESPONSE=\`curl -s -F "upload[upload_type]=unix-bench-error" -F "upload[data]=<sz-error.log" -F "upload[key]=$SZK" $UPLOAD_ENDPOINT\`

echo "Uploading results..."
echo "Response: \$RESPONSE"
echo "Done"

exit 0
EOF

chmod u+x run-upload.sh

nohup ./run-upload.sh > sz-script.log &

echo $! > .pid

tail -f sz-script.log
