#!/usr/bin/env bash

# ######################################
#  ------------------------------------
#    ██████╗ ████████╗██████╗ ██╗  ██╗     Title      : Wordpress Auto Installer
#    ██╔══██╗╚══██╔══╝██╔══██╗██║  ██║     Filename   : dtrh-wpauto.sh
#    ██║  ██║   ██║   ██████╔╝███████║     Version    : 1.1.0
#    ██║  ██║   ██║   ██╔══██╗██╔══██║     Date       : 09.09.23
#    ██████╔╝   ██║   ██║  ██║██║  ██║
#    ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝     Additional : README.md
#            https://dtrh.net
#  ------------------------------------
# ######################################

# Set shell options
set -o posix
set -o errexit
set -o errtrace
set -o nounset
set -o pipefail

# Clear terminal
clear

# Initialize magic variables
__dir="$(cd "$(dirname "${BASH_SOURCE}")" && pwd)"
__file="${__dir}/$(basename "${BASH_SOURCE}")"
__base="$(basename "${__file}" .sh)"
__me="${BASH_SOURCE}"

# Global variable initialization
__help="0"
wp_admin=""
wp_dir=""
_log="0"
log_file="/tmp/wp_auto.log"
bad_opt=""
declare -a sh_args
sql_user=""
sql_pass=""
sql_wpdb=""
wp_host=""


# Root check
[ ${EUID} -ne 0 ] &&  echo -e "${__base^^}\n\n ERROR:\nRun script with root privileges!\n\n"
case "${EUID}" in
  0) echo "Checking for root priviliges..."; sleep "0.5"; echo -e "Done.\n\n";;
  *) exit 1 ;;
esac

# Function : Banner - Display DTRH banner
__banner() {
cat <<EOF 
# ######################################
#  ------------------------------------
#    ██████╗ ████████╗██████╗ ██╗  ██╗     Title      : Wordpress Auto Installer
#    ██╔══██╗╚══██╔══╝██╔══██╗██║  ██║     Filename   : wp_auto-1.1-0.sh
#    ██║  ██║   ██║   ██████╔╝███████║     Version    : 1.1-0
#    ██║  ██║   ██║   ██╔══██╗██╔══██║     Date       : 10.06.23
#    ██████╔╝   ██║   ██║  ██║██║  ██║
#    ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝     Additional : README.md
#            https://dtrh.net
#  ------------------------------------
# ######################################


EOF
}

# Function : Usage - Display simple usage information
__usage() {
  __banner
cat <<EOF
Usage: ${__me} [USER]

       
EOF
}

# Function : Help - Display detailed usage information 
__help() {
  __banner
  echo -e "${__base^^} HELP:\n"
  cat <<EOF

Usage: ${__me} [USER]

wp_auto.sh installs a fresh copy of the latest version of weordpress to
your /var/www/html folder, in the subfolder named 'wordpress'. It takes
one argument, a user name for the admin/ownef of the wordpress website
being installed. 

See README.md for more information on tweaking this script.

Options:
  -l [FILE]      Create logfile. Write to [FILE]
  -h             Display this text
  -v             Display script version


EOF
exit 1; }

# getopts loop : Interpret user input & sort
while getopts :hl:v opt; do
  case "${opt}" in
    h) __help="1";; 
    l) log_file="${OPTARG}" && _log="1";;
    :) bad_opt="2";;   # Missing log file
    \?) bad_opt="1";;  # Unrecognized opt
  esac
done

# Shift through options index one by one
shift $((${OPTIND} - 1))

#if [ ! command -v screen ] && [ ${_log} = "1" ]; then 
#echo -e "You are missing a dependency: screen. The script will be sure to install it momentarily. Pleaae restart the script to #continue.." && exit 1;
# elif [ command -v screen ]; then
#   if [ ! -f ${log_file} ]; then 
#     echo -e "\n\n$(date) - wp_auto log file" > ${log_file}
#     screen -L -Logfile ${log_file}
#fi

if [ ${#} = 0 ]; then 
  __usage
  echo -e "$[{__base^^}] ERROR:\n\n"
  echo -e "0 arguments were supplied. Required: 2\n\n"
  echo -e "Use [ -h ] option or see README.md for more information"
  exit 1
 fi 
 
# With all options parsed, store remaining arguments in an array
while test ${#} -gt 0; do
  sh_args[${#}]=$1
  shift
done

# Begin calls after sorting or no-banner/no-color etc may not be processed properly
# eg. ${__me} -h -b   will call help first before switching the no-banner flag
#                     resulting in banner displaying. This is why functions are not
#                     called directly in getopts loop.
if [ ${__help} = 1 ]; then 
  __help
fi

# Options are parsed out, only expect username..
if [ ! ${#sh_args[@]} = 1 ]; then 
  __usage
  echo -e "[${__base^^}] ERROR:\n"
  echo -e "${#sh_args[@]} arguments supplied for non-interactive mode. Required: 1\n\n"
  echo -e "Use [ -h ] or see README.md\n"
  exit 1
fi

# Check for unexpected input errors among the options and throw appropriate errors
if [ ! ${bad_opt} = 0 ]; then
  __usage
  echo  -e "[${__base^^}] ERROR:\n"
    if [ ${bad_opt} = 1 ]; then
      echo  -e "Unknown option(s)\n\n"
    elif [ ${bad_opt} = 2 ]; then
      echo  -e "Missing mandatory log file parameter\n\n"
    fi
  echo  -e "Use [ -h ] or see README.md\n"
  exit 1
fi

# Most checking complete, time to do things..
__banner

echo -e "[${__base^^}] : Updating package index & upgrading packages..\n"
apt-get update && apt-get upgrade -y
echo -e "Done!\n\n"
sleep .5

echo -e "[${__base^^}] : Installing dependencies..\n"
apt install apache2 \
            curl \
            ghostscript \
            libapache2-mod-php \
            php \
            mysql-server \
            php-bcmath \
            php-curl \
            php-imagick \
            php-intl \
            php-json \
            php-mbstring \
            php-mysql \
            php-xml \
            php-zip -y
echo -e "Done!\n\n"
sleep .5

echo -e "[${__base^^}] : Installing MySQL server..\n"
echo -e "The script will now ask a few questions to properly set up the wordpress database and associated accounts/passwords\n"
mysql_secure_installation 
echo -e "Name of database user/admin: "; read sql_user
echo -e "Password for user ${sql_user}: "; read sql_pass
echo -e "Wordpress database name: "; read sql_wpdb
echo -e "Database host is 'localhost "; db_host="localhost"
sleep .5
echo -e "done.\n"

echo  -e "[${__base^^}] : Setting up user and directory..\n"
wp_usr=${sh_args[1]}
wp_dir="/var/www/html"
sleep .5

if id -u ${wp_usr} >/dev/null 2>&1; then
  echo  -e "User ${wp_usr} exists. Adding to www-data group.\n"
  usermod -aG www-data ${wp_usr}
else
  echo  -e "User ${wp_usr} doesn't exist. Creating user and adding to www-data group.\n"
  useradd -g www-data ${wp_usr}
  usermod -aG www-data sudo ${wp_usr}
fi
sleep .5

if [ -d ${wp_dir} ]; then
  echo -e "Directory ${sh_args[1]} exists.. Setting permissions for ${wp_dir} and user ${wp_usr}\n"
else
  echo  -e "Directory ${sh_args[1]} does not exist.. Creating directory ${wp_dir} and fixing permissions for user ${wp_usr}\n"
  mkdir -p ${wp_dir}
fi

chown ${wp_usr}: ${wp_dir}
sleep .5
echo  -e "Done!\n\n"

echo  -e "[${__base^^}]: Configuring Apache web server..\n"
cat <<EOF > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot ${wp_dir}/wordpress
    <Directory ${wp_dir}/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory ${wp_dir}/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF

echo -e "Creating apache configuration filr wordpress.conf in directory /etc/apache2/sites-available\n"
echo  -e "Done!\n\n"
sleep .5

echo  -e "[${__base^^}] : Downloading and extracting wordpress..\n"
echo  -e "Downloading latest version of wordpress and extracting to ${wp_dir} in subfolder wordpress\n"
echo  -e "Working ...\n\n"
curl -sL -o- https://en-ca.wordpress.org/latest-en_CA.tar.gz | sudo -u ${wp_usr} tar -xz -C ${wp_dir}
sleep .5
echo  -e "Done!\n\n"

echo  -e "[${__base^^}] : Restarting Apache web server..\n"
a2enmod rewrite
a2ensite wordpress
service apache2 reload
echo  -e "Done!\n\n"


# Print Results 

echo  -e "[${__base^^}] : Setting final permissions..\n"
chmod -R 755 ${wp_dir}/wordpress
sleep .5
echo  -e "Done!\n\n\n"

echo  -e "[${__base^^}] : RESULTS\n\n."
echo  -e "Wordpress installation folder: ${wp_dir}.\n"
echo  -e "Website owner: ${wp_usr}.\n"
echo  -e "Apache configuration: /etc/apache2/sites-available/wordpress.conf\n"
echo -e "MySql username; ${sql_user}"
echo -e "MySql Password: ${sql_pass}"
echo -e "Wordpress DB: ${sql_wpdb}"
echo -e "DB host: ${sql_host}"
echo  -e "Local address: http://127.0.0.1/wordpress\n\n"


echo  -e "This script is not complete. Please be sure to read README.md for full details\n$(date)"

