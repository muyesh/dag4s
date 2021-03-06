#!/bin/bash
BASE_PATH=$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )
COUNTRY=$1 #China
DATA_PATH=$BASE_PATH/data
TMP_PATH=$BASE_PATH/tmp

# make dir
mkdir -p $DATA_PATH
mkdir -p $TMP_PATH

# DOMAIN LIST
NO_CHECK_DOMAINS=$BASE_PATH/no_check_domains.txt
DOMESTIC_DOMAINS=$DATA_PATH/domestic_domains.txt
FOREIGN_DOMAINS=$DATA_PATH/foreign_domains.txt
ACL_LIST=$DATA_PATH/acl.txt
SQUID_CONF_TEMPLATE=$BASE_PATH/squid.conf.template
SQUID_CONF_RESULT=$DATA_PATH/squid.conf.result

# SQUID FILES
SQUID_LOG=/var/log/squid3/access.log
SQUID_CONF=/etc/squid3/squid.conf

# TMP FILES
TMP1=$TMP_PATH/domains.tmp1
TMP2=$TMP_PATH/domains.tmp2
TMP3=$TMP_PATH/domains.tmp3
DRESULT=$TMP_PATH/domestic_domains.tmp
FRESULT=$TMP_PATH/foreign_domains.tmp

# touch
touch $NO_CHECK_DOMAINS
touch $DOMESTIC_DOMAINS
touch $FOREIGN_DOMAINS
touch $TMP1
cat /dev/null > $TMP1
touch $TMP2
cat /dev/null > $TMP2
touch $TMP3
cat /dev/null > $TMP3

# get premitive domains
cat $SQUID_LOG \
    |awk '{print $7;}' \
    |sed 's|http://\([^/]*\)/.*|\1|g' \
    |sed 's/:443//g'|sort -u > $TMP1

# exclude known domains
cat $NO_CHECK_DOMAINS|while read domain
do
    cat $TMP1|grep -v $domain > $TMP2
    cat $TMP2 > $TMP1
done

# exclude known china domains in list
cat /dev/null > $TMP2
cat $TMP1 |while read domain
do
    # domestic
    dcnt=$(cat $DOMESTIC_DOMAINS|grep $domain|wc -l)
    # foreign
    fcnt=$(cat $FOREIGN_DOMAINS|grep $domain|wc -l)
    cnt=$(( $dcnt + $fcnt ))
    if [ $cnt -eq 0 ]
    then
        echo $domain >> $TMP2
    fi
done
cat $TMP2 > $TMP1

# check geoip
cat /dev/null > $TMP2
cat /dev/null > $TMP3
cat $TMP1 |while read domain
do
    isdomestic=$(geoiplookup $domain|grep $COUNTRY|wc -l)
    if [ $isdomestic -eq 1 ]
    then
        # domestic
        echo $domain >> $TMP2
    else
        # foreign
        echo $domain >> $TMP3
    fi
done
cat $TMP2 > $DRESULT
cat $TMP3 > $FRESULT

# domestic
cat $DOMESTIC_DOMAINS > $TMP1
cat $DRESULT >> $TMP1
cat $TMP1 |sort -u > $DOMESTIC_DOMAINS

# foreign
cat $FOREIGN_DOMAINS > $TMP1
cat $FRESULT >> $TMP1
cat $TMP1 |sort -u > $FOREIGN_DOMAINS

# Optimize
$BASE_PATH/optimize.sh $COUNTRY

# gen acl
cat /dev/null > $ACL_LIST

# top domains
cat $DOMESTIC_DOMAINS \
| grep -e'^[^\.]*\.[^\.]*$' \
| while read line
do
    echo '.'$line
done > $ACL_LIST

# IPs, sub domains
cat $DOMESTIC_DOMAINS \
| grep -e '^.*\.[^\.]*\.[^\.]*$' >> $ACL_LIST

# gen conf
cat /dev/null > $SQUID_CONF_RESULT
cat $SQUID_CONF_TEMPLATE |while read line
do
    if [ "$line" = '##ACL##' ]
    then
        echo "acl domesticList dstdomain '${ACL_LIST}'"
        echo "always_direct allow domesticList"
    else
        echo $line
    fi
done > $SQUID_CONF_RESULT

# echo result file
echo $SQUID_CONF_RESULT
