#!/bin/bash


# Standard strict mode and error handling boilderplate...

set -eEu 
set -o pipefail
set -o functrace

export PS4='(${BASH_SOURCE}:${LINENO}): - [${SHLVL},${BASH_SUBSHELL},$?] $ '

function handle_failure() {
  local lineno=$2
  local fn=$3
  local exitstatus=$4
  local msg=$5
  local lineno_fns=${1% 0}
  if [[ "$lineno_fns" != "0" ]] ; then
    lineno="${lineno} ${lineno_fns}"
  fi
  echo "${BASH_SOURCE[1]}: Function: ${fn} Line Number : [${lineno}] Failed with status ${exitstatus}: $msg"
}

trap 'handle_failure "${BASH_LINENO[*]}" "$LINENO" "${FUNCNAME[*]:-script}" "$?" "$BASH_COMMAND"' ERR


# Start actual script logic here...


function global-configureAptRepos()

{

echo "Now running $FUNCNAME...."

echo "deb http://download.webmin.com/download/repository sarge contrib" > /etc/apt/sources.list.d/webmin.list
curl --insecure -s https://webmin.com/jcameron-key.asc | gpg --dearmor >/etc/apt/trusted.gpg.d/jcameron-key.gpg 

echo "deb https://packages.cisofy.com/community/lynis/deb/ stable main" > /etc/apt/sources.list.d/cisofy-lynis.list
curl --insecure -s https://packages.cisofy.com/keys/cisofy-software-public.key | apt-key add -


echo "Completed running $FUNCNAME"

}

function global-shellScripts()

{

echo "Now running $FUNCNAME...."

cp distro /usr/local/bin/distro && chmod +x /usr/local/bin/distro
cp upsnotify.sh /usr/local/bin/upsnotify.sh && chmod +x /usr/local/bin/upsnotify.sh
cp up2date.sh /usr/local/bin/up2date.sh && chmod +x /usr/local/bin/up2date.sh

echo "Completed running $FUNCNAME"

}

function global-profileScripts()
{

echo "Now running $FUNCNAME...."

cp profiled-tsys-shell.sh /etc/profile.d/tsys-shell.sh
cp profiled-tmux.sh /etc/profile.d/tmux.sh

echo "Completed running $FUNCNAME"

}


function global-oam()

{

echo "Now running $FUNCNAME...."

rm -rf /usr/local/librenms-agent
cp librenms.tar.gz /usr/local/librenms.tar.gz
cd /usr/local && tar xfz librenms.tar.gz && rm -f /usr/local/librenms.tar.gz

echo "Completed running $FUNCNAME"

}


if [[ ! -f /root/ntpserver ]]; then
cp ntp.conf /etc/ntp.conf 
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install ntp ntpdate
systemctl stop ntp && ntpdate pfv-dc-02.turnsys.net && systemctl start ntp
fi

function global-systemServiceConfigurationFiles()

{

echo "Now running $FUNCNAME...."


cp aliases /etc/aliases 
cp rsyslog.conf /etc/rsyslog.conf

#Need to root cause why this breaks DNS.... look in legacy code to find DNS handle/fix bits and merge here...
#curl -s http://dl.turnsys.net/resolv.conf > /etc/resolv.conf

cp nsswitch.conf /etc/nsswitch.conf


if [ ! -d /root/.ssh ]; then 
mkdir /root/.ssh/
fi 

if [ ! -L /root/.ssh/authorized_keys ]; then
cp ssh-authorized-keys /root/.ssh/authorized_keys && chmod 400 /root/.ssh/authorized_keys
fi

echo "Completed running $FUNCNAME"

}

function global-installPackages()

{

echo "Now running $FUNCNAME...."

#
#Ensure system time is correct, otherwise can't install packages...
#



#
#Patch the system
#

/usr/local/bin/up2date.sh

#
#Remove stuff we don't want, add stuff we do want
#
 
export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" --purge remove nano

MAIL_HOST="$(hostname -f)"
debconf-set-selections <<< "postfix postfix/mailname string $MAIL_HOST"
debconf-set-selections <<< "postfix postfix/main_mailer_type string Internet with smarthost"
debconf-set-selections <<< "postfix postfix/relayhost string pfv-toolbox.turnsys.net"

export DEBIAN_FRONTEND="noninteractive" && apt-get -qq --yes -o Dpkg::Options::="--force-confold" install \
htop  \
dstat  \
snmpd  \
ncdu \
iftop \
acct \
nethogs \
sysstat \
ngrep \
lsb-release  \
screen  \
tmux  \
lldpd  \
net-tools  \
gpg  \
molly-guard  \
lshw  \
sudo  \
mailutils \
clamav \
sl \
rsyslog  \
logwatch \
git \
rsync \
tshark \
tcpdump \
lynis \
qemu-guest-agent \
zsh \
sssd \
sssd-ad \
krb5-user \
samba \
autofs \
adcli \
telnet \
postfix \
webmin 


bash <(curl -Ss https://my-netdata.io/kickstart.sh) --dont-wait
cp netdata-stream.conf /etc/netdata/stream.conf  && systemctl stop netdata && systemctl start netdata

echo "Completed running $FUNCNAME"

}

function global-postPackageConfiguration()

{

echo "Now running $FUNCNAME...."

###Post package deployment bits
systemctl stop snmpd  && /etc/init.d/snmpd stop
sed -i "s|-Lsd|-LS6d|" /lib/systemd/system/snmpd.service 
cp snmpd.conf /etc/snmp/snmpd.conf
systemctl daemon-reload && systemctl restart  snmpd && /etc/init.d/snmpd restart

/etc/init.d/rsyslog stop && /etc/init.d/rsyslog start && logger "hi hi from $(hostname)"

systemctl restart ntp 
systemctl restart postfix

accton on

echo "Completed running $FUNCNAME"

}

##################################################
# Things todo on all TSYS systems
##################################################

####################################################################################################
#Download configs and support bits to onfigure things in the TSYS standard model
####################################################################################################

global-configureAptRepos
global-shellScripts
global-profileScripts
global-oam
global-systemServiceConfigurationFiles


####################################################################################################
#Install packages and preserve existing configs...
####################################################################################################
global-installPackages
global-postPackageConfiguration


##################################################
# Things todo on certain types of systems
##################################################

###
# Proxmox servers
###

###
# Raspberry Pi
###

###
# Jetson nano
###
