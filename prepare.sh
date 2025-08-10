#!/bin/sh
set -e

# 1. Ensure Docker is running
if ! (docker ps > /dev/null 2>&1); then
  echo "docker daemon not running, will exit here!"
  exit 1
fi

# 2. Auto-create .env with random password if not exists
if [ ! -f .env ]; then
  echo "No .env found — generating one..."
  POSTGRES_PASSWORD=$(openssl rand -base64 32)
  cat > .env <<EOF
POSTGRES_PASSWORD=${POSTGRES_PASSWORD}
POSTGRES_USER=guacamole_user
POSTGRES_DB=guacamole_db
EOF
  echo ".env file created."
else
  echo ".env already exists — using existing configuration."
fi

# 3. Prepare init and record directories, run initdb.sh
echo "Preparing folder init and creating ./init/initdb.sql"
mkdir -p ./init 2>/dev/null
chmod -R +x ./init
docker run --rm 'guacamole/guacamole:1.6.0' \
  /opt/guacamole/bin/initdb.sh --postgresql > ./init/initdb.sql
echo "done"

echo "Preparing folder record and setting permissions"
mkdir -p ./record 2>/dev/null
chmod -R 777 ./record
echo "done"

# 4. Create self-signed SSL certificates
echo "Creating SSL certificates"
mkdir -p ./nginx/ssl 2>/dev/null
openssl req -nodes -newkey rsa:2048 -new -x509 \
  -keyout nginx/ssl/self-ssl.key \
  -out nginx/ssl/self.cert \
  -subj '/C=DE/ST=BY/L=Hintertupfing/O=Dorfwirt/OU=Theke/CN=www.createyourown.domain/emailAddress=docker@createyourown.domain'
echo "done"
echo "You can use your own certs by replacing nginx/ssl/self-ssl.key and .cert."
