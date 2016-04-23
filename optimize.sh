#!/bin/bash
BASE_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
COUNTRY=$1 #China
DATA_PATH=$BASE_PATH/data
TMP_PATH=$BASE_PATH/tmp

# DOMAIN LIST
DOMESTIC_DOMAINS=$DATA_PATH/domestic_domains.txt
if [ ! -e $DOMESTIC_DOMAINS ]
then
    exit 1
fi

# TMP FILES
TMP1=$TMP_PATH/optimize.tmp1
TMP2=$TMP_PATH/optimize.tmp2

# touch
touch $TMP1
cat /dev/null > $TMP1
touch $TMP2
cat /dev/null > $TMP2

# make 2 words domains
cat $DOMESTIC_DOMAINS \
|sed 's/.*\.\([^\.]*\.[^\.]*$\)/\1/g' \
|sort -u > $TMP1

cat $TMP1 |while read line
do
    cnt=$(geoiplookup $line|grep $COUNTRY|wc -l)
    if [ $cnt -eq 1 ]
    then
        echo $line >> $TMP2
    fi
done
cat $TMP2 > $TMP1

# remove sub domains
touch $TMP2
cat /dev/null > $TMP2
cat $DOMESTIC_DOMAINS |while read line
do
    topdomain=$(echo $line|sed 's/.*\.\([^\.]*\.[^\.]*$\)/\1/g')
    cnt=0
    cnt=$(( $cnt + $(cat $TMP1|grep -e "^${topdomain}$"|wc -l) ))
    cnt=$(( $cnt + $(cat $TMP1|grep -e "\.${topdomain}$"|wc -l) ))
    if [ $cnt -eq 0 ]
    then
        echo $line >> $TMP2
    fi
done

# Merge List
touch ${DOMESTIC_DOMAINS}.backup
rm ${DOMESTIC_DOMAINS}.backup
cp $DOMESTIC_DOMAINS ${DOMESTIC_DOMAINS}.backup

cat $TMP1 > $DOMESTIC_DOMAINS
cat $TMP2 >> $DOMESTIC_DOMAINS
