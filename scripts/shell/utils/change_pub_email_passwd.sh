#!/bin/sh

set -x -e
PATH=/usr/sbin/:/usr/bin:$PATH
LANG=C
export LANG PATH

change_domain_passwd() {
    # Check wether password has already been change.
    if echo |smbclient -U send_user //domain.corp.com/ipc$ ${new_passwd}
    then
        echo "  domain password is already changed!"
        return 0
    fi

    # Wait domain controller available.
    _retry_count=0
    until echo |smbclient -U send_user //domain.corp.com/ipc$ ${old_passwd}
    do
        sleep 600
        _retry_count=$((retry_count+1))
        if test $retry_count -gt 7
        then
            echo  tried old_pass too many times!
            exit
        fi
    done

    # Change domain password.
    #smbpasswd -D10 -r domain -U send_user -s <<!
    smbpasswd -r domain -U send_user -D10 -s <<!
${old_passwd}
${new_passwd}
${new_passwd}
!

    _retry_count=0
    until echo |smbclient -U send_user //domain.corp.com/ipc$ ${new_passwd}
    do
        smbpasswd -r domain -U send_user -s <<!
${old_passwd}
${new_passwd}
${new_passwd}
!
        sleep 7
        _retry_count=$((retry_count+1))
        if test $retry_count -gt 7
        then
            echo  tried too many times!
            exit
        fi
    done
}  ## end change_domain_passwd

echo '--------------------------------------------------------------------------------'
date

new_passwd=`date +%y%b%m`@CORP
old_passwd=`awk '{print $2}' /etc/postfix/sasl_passwd|awk -F: '{print $2}'`

echo oldpasswd=${old_passwd}
echo newpasswd=${new_passwd}

# Change domain password
change_domain_passwd

# Change postfix email sending smtp connect password.
cp /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.`date +%Y%m%d`.bak
printf "smtps.corp.com\tsend_user:%s\n" "${new_passwd}" >/etc/postfix/sasl_passwd
printf "send_user   ${new_passwd}\n" >/data/all_config/common_passwd.txt

postmap /etc/postfix/sasl_passwd
ls -l /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

# Change ldap connect password.
cp /etc/postfix/corp-ldap-notes.cf /etc/postfix/corp-ldap-notes.cf.`date +%Y%m%d`.bak
sed -e "s/^bind_pw.*$/bind_pw = ${new_passwd}/" /etc/postfix/corp-ldap-notes.cf >/etc/postfix/corp-ldap-notes.cf.tmp
mv -f /etc/postfix/corp-ldap-notes.cf.tmp /etc/postfix/corp-ldap-notes.cf

# Restart postfix.
service postfix restart

# Notify password changed.
this_ip=`ip addr|grep inet|grep -v inet6|grep -v '127.0.0.1'|awk '{print $2}'|cut -d/ -f1`
dir_name=`dirname $0`
svn_url=`svn info $dir_name|grep ^URL|awk '{print $2}'`

cat <<! |
Domain account [send_user]'s password has been changed from [${old_passwd}] to [${new_passwd}].



- script name: $0
- svn url: $svn_url
- execute user: `id -un`
- machine: `hostname`[$this_ip]
- related crontab content:
  ---
`crontab -l|grep $0`
  ---

!
  mutt -s "account [send_user]'s password changed" -c x@corp.com main@corp.com

