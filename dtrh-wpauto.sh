#!/usr/bin/env bash

# ######################################
#  ------------------------------------
#    ██████╗ ████████╗██████╗ ██╗  ██╗     Title      : Wordpress Auto Installer
#    ██╔══██╗╚══██╔══╝██╔══██╗██║  ██║     Filename   : dtrh-wpauto.sh
#    ██║  ██║   ██║   ██████╔╝███████║     Version    : 1.0.0
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

# Initialize global variables
__HELP__=0
__NO_BANNER__=0
__COLOR__=1
__VERBOSE__=0
__INTERACTIVE__=0
__UNEXPECTED__=0
__LOG_FILE__="/tmp/wpauto.log"
__bad_opt__=""
__INSTALL_DIR__=""
__INSTALL_USR__=""
declare -a __ARGS__


# Define colour variables
NC="\033[0m"
BNC="\033[1m"
BLK="\033[0;30m"
BBLk="\033[1;30m"
RED="\033[0;31m"
BRED="\033[1;31m"
GRN="\033[0;32m"
BGRN="\033[1;32m"
YLW="\033[0;33m"
BYLW="\033[1;33m"
BLU="\033[0;34m"
BBLU="\033[1;34m"
PPL="\033[0;35m"
BPPL="\033[1;35m"
CYN="\033[0;36m"
BCYN="\033[1;36m"

# Root check
if [ ${EUID} -ne 0 ]; then
  echo -n -e "${BYLW}[${__base^^}] ${BRED}ERROR:\n${NC}Run script with ${BNC}root ${NC}privileges!"
  exit
fi

# Function definitions -----------------------------------------------------------------------------

# Function : Banner - Display DTRH banner
__banner() {
  if [ ${__NO_BANNER__} = 0 ]; then
    cat <<EOF 
# ######################################
#  ------------------------------------
#    ██████╗ ████████╗██████╗ ██╗  ██╗     Title      : Wordpress Auto Installer
#    ██╔══██╗╚══██╔══╝██╔══██╗██║  ██║     Filename   : dtrh-wpauto.sh
#    ██║  ██║   ██║   ██████╔╝███████║     Version    : 0.0.1
#    ██║  ██║   ██║   ██╔══██╗██╔══██║     Date       : 09.09.23
#    ██████╔╝   ██║   ██║  ██║██║  ██║
#    ╚═════╝    ╚═╝   ╚═╝  ╚═╝╚═╝  ╚═╝     Additional : README.md
#            https://dtrh.net
#  ------------------------------------
# ######################################


EOF
  fi
}

# Function : Usage - Display simple usage information
__usage() {
  __banner
cat <<EOF
Usage: ${__me} [OPTION]... [FLAG]...  [USER]
OR     ${__me} -i [OPTION]... [FLAG]...

       
EOF
}

# Function : Help - Display detailed usage information 
__help() {
  __banner
  echo -n -e "${BYLW}[${__base^^}] ${BBLU}HELP:${NC}\n"
  cat <<EOF

Usage: ${__me} [OPTION]... [FLAG]... [USER]
OR     ${__me} -i [OPTION]... [FLAG]...  


Options:
  -l [FILE]      Create logfile. Write to [FILE]
  
Flags:
  -h             Display this text
  -b             Disable banner    [Default: Disabled]
  -c             Disable color     [Default: Disabled]
  -i             Interactive Mode  [Default: Disabled]
  -v             Verbose output    [Default: Disabled]
EOF
  exit 1
}

# getopts loop : Interpret user input & sort
while getopts :bhl:icv opt; do
  case "${opt}" in
    b) __NO_BANNER__=1;;
    h) __HELP__=1;; 
    l) __LOG_FILE__="${OPTARG}";;
    :) __UNEXPECTED__=2;;
    i) __INTERACTIVE__=1;;
    c) __NO_COLOR__=1;;
    v) __VERBOSE__=1;;
    \?) __UNEXPECTED__=1; __bad_opt__=${opt};;
  esac
done

# Shift through options index one by one
shift $((${OPTIND} - 1))

# TODO: This checks if nothing but the script is run (no user input otherwise).
#       Because the array to hold arguments is of an unknown size, initializing it
#       properly is problematic for the argument count. Fix. Likely use 'unset' 
#       before counting args, and remove this snippet.
if [ ${#} = 0 ]; then
  __usage
  echo -n -e "${BYLW}[${__base^^}] ${BRED}ERROR:\n"
  echo -n -e "0 arguments supplied for non-interactive mode. Required: 2\n\n"
  echo -n -e "${NC}Use ${BNC}[ -h ] ${NC}or see ${BNC}README.md${NC}\n"
  exit 1
fi

# With all options parsed, store remaining arguments in an array
while test ${#} -gt 0; do
  __ARGS__[${#}]=$1
  # echo ${__ARGS__[${#}]}
  shift
done

# Begin calls after sorting or no-banner/no-color etc may not be processed properly
# eg. ${__me} -h -b   will call help first before switching the no-banner flag
#                     resulting in banner displaying. This is why functions are not
#                     called directly in getopts loop.
if [ ${__HELP__} = 1 ]; then 
  __help
fi

# Options are parsed out, expectation is two arguments remain
# Throw appropriate errors if array is not expected size
if [ ! ${#__ARGS__[@]} = 1 ]; then 
  __usage
  echo -n -e "${BYLW}[${__base^^}] ${BRED}ERROR:\n"
  echo -n -e "${#__ARGS__[@]} arguments supplied for non-interactive mode. Required: 1\n\n"
  echo -n -e "${NC}Use ${BNC}[ -h ] ${NC}or see ${BNC}README.md${NC}\n"
  exit 1
fi

# Check for unexpected input errors among the options and throw appropriate errors
if [ ! ${__UNEXPECTED__} = 0 ]; then
  __usage
  echo -n -e "${BYLW}[${__base^^}] ${BRED}ERROR:\n"
    if [ ${__UNEXPECTED__} = 1 ]; then
      # It turns out invalid opts are indexed as '?'. This was an attempt to return
      # the invalid option and display it for the user. 
      # TODO : Fix or remove
      echo -n -e "${RED}Unknown option(s): ${BNC}${__bad_opt__}\n\n"
    elif [ ${__UNEXPECTED__} = 2 ]; then
      echo -n -e "${RED}Missing mandatory log file parameter${NC}\n\n"
    fi
    echo -n -e "${NC}Use ${BNC}[ -h ] ${NC}or see ${BNC}README.md${NC}\n"
    exit 1
fi

# Main entry
__banner

echo -n -e "${BYLW}[${__base^^}] ${BNC}: Updating package index & upgrading packages..\n${NC}"
apt-get update && apt-get upgrade -y
echo -n -e "${BNC}Done!${NC}\n\n"
sleep .5

echo -n -e "${BYLW}[${__base^^}] ${BNC}: Installing dependencies..\n${NC}"
apt install apache2 \
  ghostscript \
  libapache2-mod-php \
  php \
  php-bcmath \
  php-curl \
  php-imagick \
  php-intl \
  php-json \
  php-mbstring \
  php-mysql \
  php-xml \
  php-zip
echo -n -e "${BNC}Done!${NC}\n\n"
sleep .5

# TODO : Having issues with kali
# echo -n -e "${BYLW}[${__base^^}] ${BNC}: Installing MySQL server..\n${NC}"
# mysql_secure_installation
# echo -n -e "${BNC}Done!${NC}\n\n"
# sleep .5

echo -n -e "${BYLW}[${__base^^}] ${BNC}: Setting up user and directory..\n${NC}"
__INSTALL_USR__=${__ARGS__[1]}
__INSTALL_DIR__="/var/www/html"
sleep .5

if id -u ${__INSTALL_USR__} >/dev/null 2>&1; then
  echo -n -e "User ${BNC}${__INSTALL_USR__}${NC} exists. Adding to ${BNC}www-data${NC} group.\n"
  # useradd -g www-data ${__INSTALL_USR__}
else
  echo -n -e "User ${BNC}${__INSTALL_USR__}${NC} doesn't exist. Creating user and adding to ${BNC}www-data${NC} group.\n"
  # useradd -g www-data ${__INSTALL_USR__}
fi
sleep .5

if [ -d ${__INSTALL_DIR__} ]; then
  echo -n -e "Directory ${BNC}${__ARGS__[1]}${NC} exists.. Setting permissions to ${BNC}${__INSTALL_DIR__}${NC} for user ${BNC}${__INSTALL_USR__}${NC}\n"
else
  echo -n -e "Directory ${BNC}${__ARGS__[1]}${NC} does not exist.. Creating and setting permissions to ${BNC}${__INSTALL_DIR__}${NC} for user ${BNC}${__INSTALL_USR__}${NC}\n"
  mkdir -p ${__INSTALL_DIR__}
fi

chown ${__INSTALL_USR__}: ${__INSTALL_DIR__}
sleep .5
echo -n -e "${BNC}Done!${NC}\n\n"

echo -n -e "${BYLW}[${__base^^}] ${BNC}: Configuring Apache web server..\n${NC}"
cat <<EOF > /etc/apache2/sites-available/wordpress.conf
<VirtualHost *:80>
    DocumentRoot ${__INSTALL_DIR__}/wordpress
    <Directory ${__INSTALL_DIR__}/wordpress>
        Options FollowSymLinks
        AllowOverride Limit Options FileInfo
        DirectoryIndex index.php
        Require all granted
    </Directory>
    <Directory ${__INSTALL_DIR__}/wordpress/wp-content>
        Options FollowSymLinks
        Require all granted
    </Directory>
</VirtualHost>
EOF
echo -n -e "${NC}Created file: ${BNC}wordpress.conf${NC} in directory ${BNC}/etc/apache2/sites-available${NC}\n"
echo -n -e "${BNC}Done!${NC}\n\n"
sleep .5

echo -n -e "${BYLW}[${__base^^}] ${BNC}: Downloading and extracting wordpress..\n${NC}"
echo -n -e "Downloading latest version of wordpress and extracting to ${BNC}${__INSTALL_DIR__}${NC} in subfolder ${BNC}wordpress${NC}\n"
echo -n -e "Working ...\n\n"
curl -sL -o- https://en-ca.wordpress.org/latest-en_CA.tar.gz | sudo -u ${__INSTALL_USR__} tar -xz -C ${__INSTALL_DIR__}
sleep .5
echo -n -e "${BNC}Done!${NC}\n\n"

echo -n -e "${BYLW}[${__base^^}] ${BNC}: Restarting Apache web server..\n${NC}"
a2enmod rewrite
# a2ensite wordpress
service apache2 reload
echo -n -e "${BNC}Done!${NC}\n\n"

echo -n -e "${BYLW}[${__base^^}] ${BNC}: Setting final permissions..\n${NC}"
chmod -R 755 ${__INSTALL_DIR__}/wordpress
sleep .5
echo -n -e "${BNC}Done!${NC}\n\n\n"

echo -n -e "${BYLW}[${__base^^}] ${BNC}: RESULTS\n\n${NC}."
echo -n -e "${NC}Wordpress installation folder: ${BNC}${__INSTALL_DIR__}${NC}\n"
echo -n -e "${NC}Website owner: ${BNC}${__INSTALL_USR__}${NC}\n"
echo -n -e "${NC}Apache configuration: ${BNC}/etc/apache2/sites-available/wordpress.conf${NC}\n"
echo -n -e "${NC}Local address: ${BNC}http://127.0.0.1/wordpress${NC}\n\n"

echo -n -e "${BYLW}This script is not complete. Please be sure to read ${BNC}README.md ${BYLW}for full details\n${BNC}$(date)"






