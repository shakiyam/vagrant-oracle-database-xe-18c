#!/bin/bash
set -eu -o pipefail

file=oracle-database-xe-18c-1.0-1.x86_64.rpm
checksum=308c044444342b9a3a8d332c68b12c540edf933dc8162d8eda3225e662433f1b

script_dir="$(cd "$(dirname "$0")" && pwd)"

# load environment variables from .env
set -a
if [ -e "$script_dir"/.env ]; then
  # shellcheck disable=SC1090
  . "$script_dir"/.env
else
  echo 'Environment file .env not found. Therefore, dotenv.sample will be used.'
  # shellcheck disable=SC1090
  . "$script_dir"/dotenv.sample
fi
set +a

# Verify SHA256 checksum
echo "$checksum  $script_dir/$file" | sha256sum -c

# Install rlwrap
yum -y --enablerepo=ol7_developer_EPEL install rlwrap

# Install the database software
yum -y localinstall "$script_dir/$file"

# Creating and Configuring an Oracle Database
echo -e "${ORACLE_PASSWORD}\n${ORACLE_PASSWORD}" | /etc/init.d/oracle-xe-18c configure

# Set environment variables
cat <<EOT >> /home/vagrant/.bash_profile
export ORACLE_BASE=/opt/oracle/product/18c/dbhomeXE
export ORACLE_HOME=/opt/oracle/product/18c/dbhomeXE
export ORACLE_SID=XE
export PATH=\$PATH:\$ORACLE_HOME/bin
EOT

# Set alias
cat <<EOT >> /home/vagrant/.bashrc
alias sqlplus='rlwrap sqlplus'
EOT

# Automating Shutdown and Startup
systemctl daemon-reload
systemctl enable oracle-xe-18c
