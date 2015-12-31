#!/usr/bin/sh

day_offset=$1
day_offset=${day_offset:=-1}
day=`perl -MPOSIX -le '@now=localtime; $now[3]+='$day_offset'; print strftime("%Y%m%d", localtime(mktime(@now)))'`
echo $day
