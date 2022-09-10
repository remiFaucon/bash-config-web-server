#!/bin/bash

sudo apt update

sudo apt install curl gnupg2 ca-certificates lsb-release ubuntu-keyring git snapd proftpd quota fail2ban php8.0-fpm -y
sudo snap install core
sudo snap refresh core

curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor\
| sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
| sudo tee /etc/apt/sources.list.d/nginx.list
echo -e "Package : *\nPin : origine nginx.org\nPin : version o=nginx\nPin-Priority : 900\n" \
| sudo tee /etc/apt/preferences.d/99nginx
sudo apt-get install nginx -y
### configurer etc/nginx/nginx.conf pour php   user www-data    ligne2
###                                            limit_req_zone $binary_remote_addr zone=one:10m rate=1r/s;    where i want limit req nombre per sec and in memory

curl -sL https://deb.nodesource.com/setup_12.x | sudo -E bash -
sudo apt-get install nodejs -y

#sudo git clone https://github.com/letsencrypt/letsencrypt /opt/letsencrypt --depth=1
#mkdir /opt/letsencrypt
#git config --global --add safe.directory /opt/letsencrypt
#currentDirectory=$(pwd)
#cd /opt/letsencrypt && sudo git pull
#cd currentDirectory
sudo mkdir -p /etc/nginx/ssl &&
sudo openssl rand -base64 -out /etc/nginx/ssl/ticket.key &&
sudo openssl dhparam -out /etc/nginx/ssl/dhparam4.pem 4096

sudo snap install --classic certbot
sudo ln -s /snap/bin/certbot /usr/bin/certbot

### /etc/ssh/sshd_config     AllowUsers root MON_USER_SSH

### /etc/proftpd/proftpd.conf  decommenter la ligne où se trouve DefaultRoot

### quota
####### /etc/fstab dba    ext4    errors=remount-ro,usrquota ligne du point de montage
####### sudo mount -o remount /
#######

### secu
sudo chmod +x ./confIptables.bash
sudo bash ./confIptables.bash
sudo mv ./confIptables.bash etc/init.d/
sudo update-rc.d confIptables.bash defaults

echo "[Definition]
failregex = limiting requests, excess:.* by zone.*client: <HOST>
ignoreregex =" > etc/fail2ban/filter.d/nginx-req-limit.conf

sudo cp jail.conf jail.local
echo "#
# WARNING: heavily refactored in 0.9.0 release.  Please review and
#          customize settings for your setup.
#
# Changes:  in most of the cases you should not modify this
#           file, but provide customizations in jail.local file,
#           or separate .conf files under jail.d/ directory, e.g.:
#
# HOW TO ACTIVATE JAILS:
#
# YOU SHOULD NOT MODIFY THIS FILE.
#
# It will probably be overwritten or improved in a distribution update.
#
# Provide customizations in a jail.local file or a jail.d/customisation.local.
# For example to change the default bantime for all jails and to enable the
# ssh-iptables jail the following (uncommented) would appear in the .local file.
# See man 5 jail.conf for details.
#
# [DEFAULT]
# bantime = 1h
#
# [sshd]
# enabled = true
#
# See jail.conf(5) man page for more information



# Comments: use '#' for comment lines and ';' (following a space) for inline comments


[INCLUDES]

#before = paths-distro.conf
before = paths-debian.conf

# The DEFAULT allows a global definition of the options. They can be overridden
# in each jail afterwards.

[DEFAULT]

#
# MISCELLANEOUS OPTIONS
#

# \"bantime.increment\" allows to use database for searching of previously banned ip's to increase a 
# default ban time using special formula, default it is banTime * 1, 2, 4, 8, 16, 32...
#bantime.increment = true

# \"bantime.rndtime\" is the max number of seconds using for mixing with random time 
# to prevent \"clever\" botnets calculate exact time IP can be unbanned again:
#bantime.rndtime = 

# \"bantime.maxtime\" is the max number of seconds using the ban time can reach (don't grows further)
#bantime.maxtime = 

# \"bantime.factor\" is a coefficient to calculate exponent growing of the formula or common multiplier,
# default value of factor is 1 and with default value of formula, the ban time 
# grows by 1, 2, 4, 8, 16 ...
#bantime.factor = 1

# \"bantime.formula\" used by default to calculate next value of ban time, default value bellow,
# the same ban time growing will be reached by multipliers 1, 2, 4, 8, 16, 32...
#bantime.formula = ban.Time * (1<<(ban.Count if ban.Count<20 else 20)) * banFactor
#
# more aggressive example of formula has the same values only for factor \"2.0 / 2.885385\" :
#bantime.formula = ban.Time * math.exp(float(ban.Count+1)*banFactor)/math.exp(1*banFactor)

# \"bantime.multipliers\" used to calculate next value of ban time instead of formula, coresponding 
# previously ban count and given \"bantime.factor\" (for multipliers default is 1);
# following example grows ban time by 1, 2, 4, 8, 16 ... and if last ban count greater as multipliers count, 
# always used last multiplier (64 in example), for factor '1' and original ban time 600 - 10.6 hours
#bantime.multipliers = 1 2 4 8 16 32 64
# following example can be used for small initial ban time (bantime=60) - it grows more aggressive at begin,
# for bantime=60 the multipliers are minutes and equal: 1 min, 5 min, 30 min, 1 hour, 5 hour, 12 hour, 1 day, 2 day
#bantime.multipliers = 1 5 30 60 300 720 1440 2880

# \"bantime.overalljails\" (if true) specifies the search of IP in the database will be executed 
# cross over all jails, if false (dafault), only current jail of the ban IP will be searched
#bantime.overalljails = false

# --------------------

# \"ignoreself\" specifies whether the local resp. own IP addresses should be ignored
# (default is true). Fail2ban will not ban a host which matches such addresses.
#ignoreself = true

# \"ignoreip\" can be a list of IP addresses, CIDR masks or DNS hosts. Fail2ban
# will not ban a host which matches an address in this list. Several addresses
# can be defined using space (and/or comma) separator.
#ignoreip = 127.0.0.1/8 ::1

# External command that will take an tagged arguments to ignore, e.g. <ip>,
# and return true if the IP is to be ignored. False otherwise.
#
# ignorecommand = /path/to/command <ip>
ignorecommand =

# \"bantime\" is the number of seconds that a host is banned.
bantime  = 10m

# A host is banned if it has generated \"maxretry\" during the last \"findtime\"
# seconds.
findtime  = 10m

# \"maxretry\" is the number of failures before a host get banned.
maxretry = 5

# \"maxmatches\" is the number of matches stored in ticket (resolvable via tag <matches> in actions).
maxmatches = %(maxretry)s

# \"backend\" specifies the backend used to get files modification.
# Available options are \"pyinotify\", \"gamin\", \"polling\", \"systemd\" and \"auto\".
# This option can be overridden in each jail as well.
#
# pyinotify: requires pyinotify (a file alteration monitor) to be installed.
#              If pyinotify is not installed, Fail2ban will use auto.
# gamin:     requires Gamin (a file alteration monitor) to be installed.
#              If Gamin is not installed, Fail2ban will use auto.
# polling:   uses a polling algorithm which does not require external libraries.
# systemd:   uses systemd python library to access the systemd journal.
#              Specifying \"logpath\" is not valid for this backend.
#              See \"journalmatch\" in the jails associated filter config
# auto:      will try to use the following backends, in order:
#              pyinotify, gamin, polling.
#
# Note: if systemd backend is chosen as the default but you enable a jail
#       for which logs are present only in its own log files, specify some other
#       backend for that jail (e.g. polling) and provide empty value for
#       journalmatch. See https://github.com/fail2ban/fail2ban/issues/959#issuecomment-74901200
backend = auto

# \"usedns\" specifies if jails should trust hostnames in logs,
#   warn when DNS lookups are performed, or ignore all hostnames in logs
#
# yes:   if a hostname is encountered, a DNS lookup will be performed.
# warn:  if a hostname is encountered, a DNS lookup will be performed,
#        but it will be logged as a warning.
# no:    if a hostname is encountered, will not be used for banning,
#        but it will be logged as info.
# raw:   use raw value (no hostname), allow use it for no-host filters/actions (example user)
usedns = warn

# \"logencoding\" specifies the encoding of the log files handled by the jail
#   This is used to decode the lines from the log file.
#   Typical examples:  \"ascii\", \"utf-8\"
#
#   auto:   will use the system locale setting
logencoding = auto

# \"enabled\" enables the jails.
#  By default all jails are disabled, and it should stay this way.
#  Enable only relevant to your setup jails in your .local or jail.d/*.conf
#
# true:  jail will be enabled and log files will get monitored for changes
# false: jail is not enabled
enabled = false


# \"mode\" defines the mode of the filter (see corresponding filter implementation for more info).
mode = normal

# \"filter\" defines the filter to use by the jail.
#  By default jails have names matching their filter name
#
filter = %(__name__)s[mode=%(mode)s]


#
# ACTIONS
#

# Some options used for actions

# Destination email address used solely for the interpolations in
# jail.{conf,local,d/*} configuration files.
destemail = root@localhost

# Sender email address used solely for some actions
sender = root@<fq-hostname>

# E-mail action. Since 0.8.1 Fail2Ban uses sendmail MTA for the
# mailing. Change mta configuration parameter to mail if you want to
# revert to conventional 'mail'.
mta = sendmail

# Default protocol
protocol = tcp

# Specify chain where jumps would need to be added in ban-actions expecting parameter chain
chain = <known/chain>

# Ports to be banned
# Usually should be overridden in a particular jail
port = 0:65535

# Format of user-agent https://tools.ietf.org/html/rfc7231#section-5.5.3
fail2ban_agent = Fail2Ban/%(fail2ban_version)s

#
# Action shortcuts. To be used to define action parameter

# Default banning action (e.g. iptables, iptables-new,
# iptables-multiport, shorewall, etc) It is used to define
# action_* variables. Can be overridden globally or per
# section within jail.local file
banaction = iptables-multiport
banaction_allports = iptables-allports

# The simplest action to take: ban only
action_ = %(banaction)s[name=%(__name__)s, port=\"%(port)s\", protocol=\"%(protocol)s\", chain=\"%(chain)s\"]

# ban & send an e-mail with whois report to the destemail.
action_mw = %(banaction)s[name=%(__name__)s, port=\"%(port)s\", protocol=\"%(protocol)s\", chain=\"%(chain)s\"]
            %(mta)s-whois[name=%(__name__)s, sender=\"%(sender)s\", dest=\"%(destemail)s\", protocol=\"%(protocol)s\", chain=\"%(chain)s\"]

# ban & send an e-mail with whois report and relevant log lines
# to the destemail.
action_mwl = %(banaction)s[name=%(__name__)s, port=\"%(port)s\", protocol=\"%(protocol)s\", chain=\"%(chain)s\"]
             %(mta)s-whois-lines[name=%(__name__)s, sender=\"%(sender)s\", dest=\"%(destemail)s\", logpath=\"%(logpath)s\", chain=\"%(chain)s\"]

# See the IMPORTANT note in action.d/xarf-login-attack for when to use this action
#
# ban & send a xarf e-mail to abuse contact of IP address and include relevant log lines
# to the destemail.
action_xarf = %(banaction)s[name=%(__name__)s, port=\"%(port)s\", protocol=\"%(protocol)s\", chain=\"%(chain)s\"]
             xarf-login-attack[service=%(__name__)s, sender=\"%(sender)s\", logpath=\"%(logpath)s\", port=\"%(port)s\"]

# ban IP on CloudFlare & send an e-mail with whois report and relevant log lines
# to the destemail.
action_cf_mwl = cloudflare[cfuser=\"%(cfemail)s\", cftoken=\"%(cfapikey)s\"]
                %(mta)s-whois-lines[name=%(__name__)s, sender=\"%(sender)s\", dest=\"%(destemail)s\", logpath=\"%(logpath)s\", chain=\"%(chain)s\"]

# Report block via blocklist.de fail2ban reporting service API
# 
# See the IMPORTANT note in action.d/blocklist_de.conf for when to use this action.
# Specify expected parameters in file action.d/blocklist_de.local or if the interpolation
# \`action_blocklist_de\` used for the action, set value of \`blocklist_de_apikey\`
# in your \`jail.local\` globally (section [DEFAULT]) or per specific jail section (resp. in
# corresponding jail.d/my-jail.local file).
#
action_blocklist_de  = blocklist_de[email=\"%(sender)s\", service=%(filter)s, apikey=\"%(blocklist_de_apikey)s\", agent=\"%(fail2ban_agent)s\"]

# Report ban via badips.com, and use as blacklist
#
# See BadIPsAction docstring in config/action.d/badips.py for
# documentation for this action.
#
# NOTE: This action relies on banaction being present on start and therefore
# should be last action defined for a jail.
#
action_badips = badips.py[category=\"%(__name__)s\", banaction=\"%(banaction)s\", agent=\"%(fail2ban_agent)s\"]
#
# Report ban via badips.com (uses action.d/badips.conf for reporting only)
#
action_badips_report = badips[category=\"%(__name__)s\", agent=\"%(fail2ban_agent)s\"]

# Report ban via abuseipdb.com.
#
# See action.d/abuseipdb.conf for usage example and details.
#
action_abuseipdb = abuseipdb

# Choose default action.  To change, just override value of 'action' with the
# interpolation to the chosen action shortcut (e.g.  action_mw, action_mwl, etc) in jail.local
# globally (section [DEFAULT]) or per specific section
action = %(action_)s


#
# JAILS
#

#
# SSH servers
#

[sshd]

# To use more aggressive sshd modes set filter parameter \"mode\" in jail.local:
# normal (default), ddos, extra or aggressive (combines all).
# See \"tests/files/logs/sshd\" or \"filter.d/sshd.conf\" for usage example and details.
#mode   = normal
port    = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s


[dropbear]

port     = ssh
logpath  = %(dropbear_log)s
backend  = %(dropbear_backend)s


[selinux-ssh]

port     = ssh
logpath  = %(auditd_log)s


#
# HTTP servers
#

[openhab-auth]

filter = openhab
action = iptables-allports[name=NoAuthFailures]
logpath = /opt/openhab/logs/request.log


[nginx-http-auth]

port    = http,https
logpath = %(nginx_error_log)s

[nginx-noscript]

enabled = true
port = http,https
filter = nginx-noscript
action = ufw
logpath = %(nginx_error_log)s
bantime = 3600
findtime = 300
maxretry = 6

# To use 'nginx-limit-req' jail you should have \`ngx_http_limit_req_module\`
# and define \`limit_req\` and \`limit_req_zone\` as described in nginx documentation
# http://nginx.org/en/docs/http/ngx_http_limit_req_module.html
# or for example see in 'config/filter.d/nginx-limit-req.conf'
[nginx-limit-req]

enabled = true
port = http,https
filter = nginx-req-limit
action = iptables-multiport[name=ReqLimit, port=\"http,https\", protocol=tcp]
logpath = %(nginx_error_log)s
findtime = 600
bantime = 7200
maxretry = 10

[nginx-req-limit]

enabled = true
filter = nginx-req-limit
action = iptables-multiport[name=ReqLimit, port=\"http,https\", protocol=tcp]
logpath = %(nginx_error_log)s
findtime = 600
bantime = 7200
maxretry = 10

[nginx-botsearch]

port     = http,https
logpath  = %(nginx_error_log)s
maxretry = 2

[nginx-badbots]

enabled = true
port = http,https
filter = nginx-badbots
action = ufw
logpath = %(nginx_error_log)s
bantime = 3600
findtime = 300
maxretry = 2

# Ban attackers that try to use PHP's URL-fopen() functionality
# through GET/POST variables. - Experimental, with more than a year
# of usage in production environments.

[php-url-fopen]

port    = http,https
logpath = %(nginx_access_log)s
          %(apache_access_log)s


[suhosin]

port    = http,https
logpath = %(suhosin_log)s


[lighttpd-auth]
# Same as above for Apache's mod_auth
# It catches wrong authentifications
port    = http,https
logpath = %(lighttpd_error_log)s


#
# Webmail and groupware servers
#

[roundcube-auth]

port     = http,https
logpath  = %(roundcube_errors_log)s
# Use following line in your jail.local if roundcube logs to journal.
#backend = %(syslog_backend)s


[openwebmail]

port     = http,https
logpath  = /var/log/openwebmail.log


[horde]

port     = http,https
logpath  = /var/log/horde/horde.log


[groupoffice]

port     = http,https
logpath  = /home/groupoffice/log/info.log


[sogo-auth]
# Monitor SOGo groupware server
# without proxy this would be:
# port    = 20000
port     = http,https
logpath  = /var/log/sogo/sogo.log


[tine20]

logpath  = /var/log/tine20/tine20.log
port     = http,https


#
# Web Applications
#
#

[drupal-auth]

port     = http,https
logpath  = %(syslog_daemon)s
backend  = %(syslog_backend)s

[guacamole]

port     = http,https
logpath  = /var/log/tomcat*/catalina.out

[monit]
#Ban clients brute-forcing the monit gui login
port = 2812
logpath  = /var/log/monit
           /var/log/monit.log


[webmin-auth]

port    = 10000
logpath = %(syslog_authpriv)s
backend = %(syslog_backend)s


[froxlor-auth]

port    = http,https
logpath  = %(syslog_authpriv)s
backend  = %(syslog_backend)s


#
# HTTP Proxy servers
#
#

[squid]

port     =  80,443,3128,8080
logpath = /var/log/squid/access.log


[3proxy]

port    = 3128
logpath = /var/log/3proxy.log


#
# FTP servers
#


[proftpd]

enabled  = true
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(proftpd_log)s
backend  = %(proftpd_backend)s
action   = ufw[application=\"PROFTPd\",blocktype=reject]
bantime  = 3600
findtime = 300
maxretry = 3


[pure-ftpd]

port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(pureftpd_log)s
backend  = %(pureftpd_backend)s


[gssftpd]

port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(syslog_daemon)s
backend  = %(syslog_backend)s


[wuftpd]

port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(wuftpd_log)s
backend  = %(wuftpd_backend)s


[vsftpd]
# or overwrite it in jails.local to be
# logpath = %(syslog_authpriv)s
# if you want to rely on PAM failed login attempts
# vsftpd's failregex should match both of those formats
port     = ftp,ftp-data,ftps,ftps-data
logpath  = %(vsftpd_log)s


#
# Mail servers
#

# ASSP SMTP Proxy Jail
[assp]

port     = smtp,465,submission
logpath  = /root/path/to/assp/logs/maillog.txt


[courier-smtp]

port     = smtp,465,submission
logpath  = %(syslog_mail)s
backend  = %(syslog_backend)s


[postfix]
# To use another modes set filter parameter \"mode\" in jail.local:
mode    = more
port    = smtp,465,submission
logpath = %(postfix_log)s
backend = %(postfix_backend)s


[postfix-rbl]

filter   = postfix[mode=rbl]
port     = smtp,465,submission
logpath  = %(postfix_log)s
backend  = %(postfix_backend)s
maxretry = 1


[sendmail-auth]

port    = submission,465,smtp
logpath = %(syslog_mail)s
backend = %(syslog_backend)s


[sendmail-reject]
# To use more aggressive modes set filter parameter \"mode\" in jail.local:
# normal (default), extra or aggressive
# See \"tests/files/logs/sendmail-reject\" or \"filter.d/sendmail-reject.conf\" for usage example and details.
#mode    = normal
port     = smtp,465,submission
logpath  = %(syslog_mail)s
backend  = %(syslog_backend)s


[qmail-rbl]

filter  = qmail
port    = smtp,465,submission
logpath = /service/qmail/log/main/current


# dovecot defaults to logging to the mail syslog facility
# but can be set by syslog_facility in the dovecot configuration.
[dovecot]

port    = pop3,pop3s,imap,imaps,submission,465,sieve
logpath = %(dovecot_log)s
backend = %(dovecot_backend)s


[sieve]

port   = smtp,465,submission
logpath = %(dovecot_log)s
backend = %(dovecot_backend)s


[solid-pop3d]

port    = pop3,pop3s
logpath = %(solidpop3d_log)s


[exim]
# see filter.d/exim.conf for further modes supported from filter:
#mode = normal
port   = smtp,465,submission
logpath = %(exim_main_log)s


[exim-spam]

port   = smtp,465,submission
logpath = %(exim_main_log)s


[kerio]

port    = imap,smtp,imaps,465
logpath = /opt/kerio/mailserver/store/logs/security.log


#
# Mail servers authenticators: might be used for smtp,ftp,imap servers, so
# all relevant ports get banned
#

[courier-auth]

port     = smtp,465,submission,imap,imaps,pop3,pop3s
logpath  = %(syslog_mail)s
backend  = %(syslog_backend)s


[postfix-sasl]

filter   = postfix[mode=auth]
port     = smtp,465,submission,imap,imaps,pop3,pop3s
# You might consider monitoring /var/log/mail.warn instead if you are
# running postfix since it would provide the same log lines at the
# \"warn\" level but overall at the smaller filesize.
logpath  = %(postfix_log)s
backend  = %(postfix_backend)s


[perdition]

port   = imap,imaps,pop3,pop3s
logpath = %(syslog_mail)s
backend = %(syslog_backend)s


[squirrelmail]

port = smtp,465,submission,imap,imap2,imaps,pop3,pop3s,http,https,socks
logpath = /var/lib/squirrelmail/prefs/squirrelmail_access_log


[cyrus-imap]

port   = imap,imaps
logpath = %(syslog_mail)s
backend = %(syslog_backend)s


[uwimap-auth]

port   = imap,imaps
logpath = %(syslog_mail)s
backend = %(syslog_backend)s


#
#
# DNS servers
#


# !!! WARNING !!!
#   Since UDP is connection-less protocol, spoofing of IP and imitation
#   of illegal actions is way too simple.  Thus enabling of this filter
#   might provide an easy way for implementing a DoS against a chosen
#   victim. See
#    http://nion.modprobe.de/blog/archives/690-fail2ban-+-dns-fail.html
#   Please DO NOT USE this jail unless you know what you are doing.
#
# IMPORTANT: see filter.d/named-refused for instructions to enable logging
# This jail blocks UDP traffic for DNS requests.
# [named-refused-udp]
#
# filter   = named-refused
# port     = domain,953
# protocol = udp
# logpath  = /var/log/named/security.log

# IMPORTANT: see filter.d/named-refused for instructions to enable logging
# This jail blocks TCP traffic for DNS requests.

[named-refused]

port     = domain,953
logpath  = /var/log/named/security.log


[nsd]

port     = 53
action   = %(banaction)s[name=%(__name__)s-tcp, port=\"%(port)s\", protocol=\"tcp\", chain=\"%(chain)s\", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port=\"%(port)s\", protocol=\"udp\", chain=\"%(chain)s\", actname=%(banaction)s-udp]
logpath = /var/log/nsd.log


#
# Miscellaneous
#

[asterisk]

port     = 5060,5061
action   = %(banaction)s[name=%(__name__)s-tcp, port=\"%(port)s\", protocol=\"tcp\", chain=\"%(chain)s\", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port=\"%(port)s\", protocol=\"udp\", chain=\"%(chain)s\", actname=%(banaction)s-udp]
           %(mta)s-whois[name=%(__name__)s, dest=\"%(destemail)s\"]
logpath  = /var/log/asterisk/messages
maxretry = 10


[freeswitch]

port     = 5060,5061
action   = %(banaction)s[name=%(__name__)s-tcp, port=\"%(port)s\", protocol=\"tcp\", chain=\"%(chain)s\", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port=\"%(port)s\", protocol=\"udp\", chain=\"%(chain)s\", actname=%(banaction)s-udp]
           %(mta)s-whois[name=%(__name__)s, dest=\"%(destemail)s\"]
logpath  = /var/log/freeswitch.log
maxretry = 10


# enable adminlog; it will log to a file inside znc's directory by default.
[znc-adminlog]

port     = 6667
logpath  = /var/lib/znc/moddata/adminlog/znc.log


# To log wrong MySQL access attempts add to /etc/my.cnf in [mysqld] or
# equivalent section:
# log-warnings = 2
#
# for syslog (daemon facility)
# [mysqld_safe]
# syslog
#
# for own logfile
# [mysqld]
# log-error=/var/log/mysqld.log
[mysqld-auth]

port     = 3306
logpath  = %(mysql_log)s
backend  = %(mysql_backend)s


# Log wrong MongoDB auth (for details see filter 'filter.d/mongodb-auth.conf')
[mongodb-auth]
# change port when running with \"--shardsvr\" or \"--configsvr\" runtime operation
port     = 27017
logpath  = /var/log/mongodb/mongodb.log


# Jail for more extended banning of persistent abusers
# !!! WARNINGS !!!
# 1. Make sure that your loglevel specified in fail2ban.conf/.local
#    is not at DEBUG level -- which might then cause fail2ban to fall into
#    an infinite loop constantly feeding itself with non-informative lines
# 2. Increase dbpurgeage defined in fail2ban.conf to e.g. 648000 (7.5 days)
#    to maintain entries for failed logins for sufficient amount of time
[recidive]

logpath  = /var/log/fail2ban.log
banaction = %(banaction_allports)s
bantime  = 1w
findtime = 1d


# Generic filter for PAM. Has to be used with action which bans all
# ports such as iptables-allports, shorewall

[pam-generic]
# pam-generic filter can be customized to monitor specific subset of 'tty's
banaction = %(banaction_allports)s
logpath  = %(syslog_authpriv)s
backend  = %(syslog_backend)s


[xinetd-fail]

banaction = iptables-multiport-log
logpath   = %(syslog_daemon)s
backend   = %(syslog_backend)s
maxretry  = 2


# stunnel - need to set port for this
[stunnel]

logpath = /var/log/stunnel4/stunnel.log


[ejabberd-auth]

port    = 5222
logpath = /var/log/ejabberd/ejabberd.log


[counter-strike]

logpath = /opt/cstrike/logs/L[0-9]*.log
# Firewall: http://www.cstrike-planet.com/faq/6
tcpport = 27030,27031,27032,27033,27034,27035,27036,27037,27038,27039
udpport = 1200,27000,27001,27002,27003,27004,27005,27006,27007,27008,27009,27010,27011,27012,27013,27014,27015
action  = %(banaction)s[name=%(__name__)s-tcp, port=\"%(tcpport)s\", protocol=\"tcp\", chain=\"%(chain)s\", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port=\"%(udpport)s\", protocol=\"udp\", chain=\"%(chain)s\", actname=%(banaction)s-udp]

[bitwarden]
port    = http,https
logpath = /home/*/bwdata/logs/identity/Identity/log.txt

[centreon]
port    = http,https
logpath = /var/log/centreon/login.log

# consider low maxretry and a long bantime
# nobody except your own Nagios server should ever probe nrpe
[nagios]

logpath  = %(syslog_daemon)s     ; nrpe.cfg may define a different log_facility
backend  = %(syslog_backend)s
maxretry = 1


[oracleims]
# see \"oracleims\" filter file for configuration requirement for Oracle IMS v6 and above
logpath = /opt/sun/comms/messaging64/log/mail.log_current
banaction = %(banaction_allports)s

[directadmin]
logpath = /var/log/directadmin/login.log
port = 2222

[portsentry]
logpath  = /var/lib/portsentry/portsentry.history
maxretry = 1

[pass2allow-ftp]
# this pass2allow example allows FTP traffic after successful HTTP authentication
port         = ftp,ftp-data,ftps,ftps-data
# knocking_url variable must be overridden to some secret value in jail.local
knocking_url = /knocking/
filter       = apache-pass[knocking_url=\"%(knocking_url)s\"]
# access log of the website with HTTP auth
logpath      = %(apache_access_log)s
blocktype    = RETURN
returntype   = DROP
action       = %(action_)s[blocktype=%(blocktype)s, returntype=%(returntype)s,
                        actionstart_on_demand=false, actionrepair_on_unban=true]
bantime      = 1h
maxretry     = 1
findtime     = 1


[murmur]
# AKA mumble-server
port     = 64738
action   = %(banaction)s[name=%(__name__)s-tcp, port=\"%(port)s\", protocol=tcp, chain=\"%(chain)s\", actname=%(banaction)s-tcp]
           %(banaction)s[name=%(__name__)s-udp, port=\"%(port)s\", protocol=udp, chain=\"%(chain)s\", actname=%(banaction)s-udp]
logpath  = /var/log/mumble-server/mumble-server.log


[screensharingd]
# For Mac OS Screen Sharing Service (VNC)
logpath  = /var/log/system.log
logencoding = utf-8

[haproxy-http-auth]
# HAProxy by default doesn't log to file you'll need to set it up to forward
# logs to a syslog server which would then write them to disk.
# See \"haproxy-http-auth\" filter for a brief cautionary note when setting
# maxretry and findtime.
logpath  = /var/log/haproxy.log

[slapd]
port    = ldap,ldaps
logpath = /var/log/slapd.log

[domino-smtp]
port    = smtp,ssmtp
logpath = /home/domino01/data/IBM_TECHNICAL_SUPPORT/console.log

[phpmyadmin-syslog]
port    = http,https
logpath = %(syslog_authpriv)s
backend = %(syslog_backend)s


[zoneminder]
# Zoneminder HTTP/HTTPS web interface auth
# Logs auth failures to apache2 error log
port    = http,https
logpath = %(apache_error_log)s

[traefik-auth]
# to use 'traefik-auth' filter you have to configure your Traefik instance,
# see \`filter.d/traefik-auth.conf\` for details and service example.
port    = http,https
logpath = /var/log/traefik/access.log" > etc/fail2ban/jail.local
service fail2ban restart
