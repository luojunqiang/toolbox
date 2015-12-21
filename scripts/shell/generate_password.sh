#!/usr/bin/sh

# usage: $0 [password_length] 

password_length=$1
password=`tr -dc 'a-zA-Z0-9-_%!' </dev/urandom |fold -w ${password_length:=10}|grep '[-_%!]'|grep '[0-9]'|head -n 1`
echo $password
