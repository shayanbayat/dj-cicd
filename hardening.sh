#! /bin/bash
# Time Variable Section --------------------------------------
HOUR=`date +%H`
WEEK=`date +%A`
MONTH=`date +%Y-%d`
DAY=`date +%Y-%m-%d`
NOW="$(date +"%Y-%m-%d_%H-%M-%S")"
# Variable Section -------------------------------------------
DOMAIN_NAME=boomsar.com
HostName=$DOMAIN_NAME
SSH_PORT=454546
BAC_DIR=/opt/backup/files_$NOW
# docker config destination
DOCKER_DEST=/etc/systemd/system/docker.service.d/
MIRROR_REGISTRY=https://docker.jamko.ir
#-------------------------------------------------------------

echo "Info: ------------------------------------"
echo -e "DNS Address:\n`cat /etc/resolv.conf`"
echo -e "Hostname: $HOSTNAME"
echo -e "OS Info:\n`lsb_release -a`"
echo -e "ssh port: $SSH_PORT"
echo "------------------------------------------"

# create directory backup ------------------------------------
if [ -d $BAC_DIR ] ; then
   echo "backup directory is exist"
else
   mkdir -p $BAC_DIR
fi   

# Preparing os ----------------------------------------------------
# Update OS
apt update && apt upgrade -y 

# Remove unuse package
apt remove -y snapd && apt purge -y snapd

# install tools
apt install -y wget git vim nano bash-completion curl htop iftop jq ncdu unzip net-tools dnsutils \
               atop sudo ntp fail2ban software-properties-common apache2-utils tcpdump telnet axel

#Copy Public Key -------------------------------------------
#cat <<EOT >> /root/.ssh/authorized_keys
# AmirBahador
# ssh-rsa YOURSSH KEY
#EOT

# fail2ban config -----------------------------------------
cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
# ssh config 
sed -i '/^\[sshd\]/a enabled = true' /etc/fail2ban/jail.local
sed -i 's/port    = ssh/port    = '$SSH_PORT'/g' /etc/fail2ban/jail.local
sed -i 's/port     = ssh/port    = '$SSH_PORT'/g' /etc/fail2ban/jail.local
# service restart and status service
{
systemctl enable fail2ban.service 
systemctl restart fail2ban.service
systemctl is-active --quiet fail2ban && echo -e "\e[1m \e[96m fail2ban service: \e[30;48;5;82m \e[5mRunning \e[0m" || echo -e "\e[1m \e[96m fail2ban service: \e[30;48;5;196m \e[5mNot Running \e[0m"
sleep 2
fail2ban-client status
}
# Install Docker --------------------------------------------------------------------
echo -e " \e[30;48;5;56m \e[1m \e[38;5;15mDocker Installation\e[0m" 
which docker || { curl -fsSL https://get.docker.com | bash; }
{
systemctl enable docker
systemctl restart docker
systemctl is-active --quiet docker && echo -e "\e[1m \e[96m docker service: \e[30;48;5;82m \e[5mRunning \e[0m" || echo -e "\e[1m \e[96m docker service: \e[30;48;5;196m \e[5mNot Running \e[0m"
}

# Configur Docker --------------------------------------------------------------------
if [ -d $DOCKER_DEST ] ; then
   echo "file exist"
else
   mkdir -p /etc/systemd/system/docker.service.d/
   touch /etc/systemd/system/docker.service.d/override.conf
fi   

cat <<EOT > /etc/systemd/system/docker.service.d/override.conf
[Service]
ExecStart=
ExecStart=/usr/bin/dockerd --registry-mirror $MIRROR_REGISTRY --log-opt max-size=500m --log-opt max-file=5
EOT
cat /etc/systemd/system/docker.service.d/override.conf
{
systemctl daemon-reload
systemctl restart docker
systemctl is-active --quiet docker && echo -e "\e[1m \e[96m docker service: \e[30;48;5;82m \e[5mRunning \e[0m" || echo -e "\e[1m \e[96m docker service: \e[30;48;5;196m \e[5mNot Running \e[0m"
}

# Install docker-compose --------------------------------------------------------------------
echo -e " \e[30;48;5;56m \e[1m \e[38;5;15mdocker-compose Installation\e[0m" 
which docker-compose || { sudo curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose; chmod +x /usr/local/bin/docker-compose; }

{
docker-compose --version
}

# ------------------------------------------------------------------------------
#Docker Services WARNING
docker info | grep WARNING

# Remove all unused packages -------------------------------------------------------
apt autoremove -y

# timezone config ------------------------------------------------------------------
apt install -y ntp
timedatectl set-timezone Asia/Tehran
timedatectl | grep Time | cut -d ":" -f2 | cut -d " " -f2

{
   systemctl enable ntp
   systemctl restart ntp
   systemctl is-active --quiet ntp && echo -e "\e[1m \e[96m ntp service: \e[30;48;5;82m \e[5mRunning \e[0m" || echo -e "\e[1m \e[96m ntp service: \e[30;48;5;196m \e[5mNot Running \e[0m"
}

# bashrc configuration --------------------------------------------------------------
