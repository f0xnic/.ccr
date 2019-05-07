#!/bin/bash
#Update script for ".ccr" on BIND9/Ubuntu 18.04

#Variables
TLD='ccr'
NS='ns1.foxnic.rfx.fi.'
EMAIL='r3df0x.r3df0x.net.'
CHECKZONE=/usr/sbin/named-checkzone
TMP_DEST='/tmp/db.ccr'
WORK_DIR='/root/registrar/ccr/'
FILE_NAME='db.ccr'
OUTPUT_DIR='/etc/bind/tld/'
FILES=${WORK_DIR}ccr/*

cd $WORK_DIR
git fetch origin master > /dev/null
git reset --hard origin/master > /dev/null

# ADD NEW SOA!
{ echo "@		IN	SOA	$NS $EMAIL ("
  echo "        `date +%s`  ; serial"
  echo "        300    ; refresh"
  echo "        180    ; retry"
  echo "        604800    ; expire"
  echo "        3600    ; minimum"
  echo "        )"
} >> $WORK_DIR$FILE_NAME

# ADD NAMESERVERS!
{ echo "; TLD information"
  echo "		IN	NS	ns1.foxnic.rfx.fi."
  echo "		IN	NS	ns2.foxnic.rfx.fi."
  echo ";"
  echo "; Additional zones"
  echo ";"
} >> $WORK_DIR$FILE_NAME


for f in $FILES
do
  cp $WORK_DIR$FILE_NAME $TMP_DEST
  cat $f >> $TMP_DEST

  TEST=$($CHECKZONE $TLD "$TMP_DEST" | tail -n 1)
  if [ "$TEST" != "OK" ]; then
    echo "Failed to add ${f}.ccr to the main zone!"
  else
    echo "Processed ${f}.ccr Successfully"
    echo "; `git log --oneline -- $f | tail -n 1`" >> $FILE_NAME
    cat $f >> $FILE_NAME
  fi

  VERIFY=$($CHECKZONE $TLD "$WORK_DIR$FILE_NAME" | tail -n 1)
  if [ "$VERIFY" != "OK" ]; then
    echo "Some unknown error occured: $WORK_DIR$FILE_NAME"
    exit 1
  fi
done

rm ${OUTPUT_DIR}db*
cp $WORK_DIR$FILE_NAME $OUTPUT_DIR

systemctl reload bind9
