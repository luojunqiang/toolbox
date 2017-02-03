#!/bin/sh

set -x -e
PATH=/usr/sbin/:/usr/bin:$PATH
LANG=C
export LANG PATH

V_DOMAIN_NAME=my_domain
V_DOMAIN_URL=//my_domain.my_corp.com/ipc$
V_USER_NAME=domain_user
V_POSTFIX_CONF=ldap-notes.cf
V_SMTP_SERVER=smtps.my_corp.com
V_PASSWORD_CONF_FILE=/data/common_passwd.txt
V_MUTT_MAIL_TO_OPT="-c me@my_corp.com domain_user@my_corp.com"

change_domain_passwd() {
    # Check wether password has already been change.
    if echo |smbclient -U ${V_USER_NAME} ${V_DOMAIN_URL} ${new_passwd}
    then
        echo "  domain password is already changed!"
        return 0
    fi

    # Wait domain controller available.
    retry_count=0
    until echo |smbclient -U ${V_USER_NAME} ${V_DOMAIN_URL} ${old_passwd}
    do
        sleep 600
        retry_count=$((retry_count+1))
        if test $retry_count -gt 7
        then
            echo  tried old_passwd too many times!
            exit
        fi
    done

    # Change domain password.
    #smbpasswd -D10 -r ${V_DOMAIN_NAME} -U ${V_USER_NAME} -s <<!
    smbpasswd -r ${V_DOMAIN_NAME} -U ${V_USER_NAME} -D10 -s <<! || true
${old_passwd}
${new_passwd}
${new_passwd}
!

    retry_count=0
    until echo |smbclient -U ${V_USER_NAME} ${V_DOMAIN_URL} ${new_passwd}
    do
        smbpasswd -r ${V_DOMAIN_NAME} -U ${V_USER_NAME} -s <<! || true
${old_passwd}
${new_passwd}
${new_passwd}
!
        sleep 7
        retry_count=$((retry_count+1))
        if test $retry_count -gt 7
        then
            echo  tried too many times!
            exit
        fi
    done
}  ## end change_domain_passwd

echo '--------------------------------------------------------------------------------'
date

new_passwd=`date +%y%b%m`@HUAWEI
old_passwd=`awk '{print $2}' /etc/postfix/sasl_passwd|awk -F: '{print $2}'`

echo oldpasswd=${old_passwd}
echo newpasswd=${new_passwd}

# Change domain password
change_domain_passwd

# Change postfix email sending smtp connect password.
cp /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.`date +%Y%m%d`.bak
printf "${V_SMTP_SERVER}\t${V_USER_NAME}:%s\n" "${new_passwd}" >/etc/postfix/sasl_passwd
printf "${V_USER_NAME}   ${new_passwd}\n" >${V_PASSWORD_CONF_FILE}

postmap /etc/postfix/sasl_passwd
ls -l /etc/postfix/sasl_passwd /etc/postfix/sasl_passwd.db

# Change ldap connect password.
cp /etc/postfix/${V_POSTFIX_CONF} /etc/postfix/${V_POSTFIX_CONF}.`date +%Y%m%d`.bak
sed -e "s/^bind_pw.*$/bind_pw = ${new_passwd}/" /etc/postfix/${V_POSTFIX_CONF} >/etc/postfix/${V_POSTFIX_CONF}.tmp
mv -f /etc/postfix/${V_POSTFIX_CONF}.tmp /etc/postfix/${V_POSTFIX_CONF}

# Restart postfix.
service postfix restart

# Notify password changed.
this_ip=`ip addr|grep inet|grep -v inet6|grep -v '127.0.0.1'|awk '{print $2}'|cut -d/ -f1`
dir_name=`dirname $0`
svn_url=`svn info $dir_name|grep ^URL|awk '{print $2}'`

cat <<! |
Domain account [${V_USER_NAME}]'s password has been changed from [${old_passwd}] to [${new_passwd}].



- script name: $0
- svn url: $svn_url
- execute user: `id -un`
- machine: `hostname`[$this_ip]
- related crontab content:
  ---
`crontab -l|grep $0`
  ---

!
  mutt -s "account [${V_USER_NAME}]'s password changed" $V_MUTT_MAIL_TO_OPT
