
## user-data.sh (monta EFS e sobe Nextcloud)
#!/bin/bash
set -euxo pipefail

# Atualiza e instala utilitários
yum update -y
amazon-linux-extras install docker -y || yum install -y docker
yum install -y nfs-utils
systemctl enable --now docker

# Montagem do EFS
EFS_DNS="${efs_dns}"
mkdir -p /mnt/nextcloud
# TLS recomendado para NFS EFS
mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 ${EFS_DNS}:/ /mnt/nextcloud

# Permissões compatíveis com container Nextcloud (www-data = 33)
chown -R 33:33 /mnt/nextcloud

# Diretórios persistentes
mkdir -p /mnt/nextcloud/html
chown -R 33:33 /mnt/nextcloud/html

# Pull e run do container Nextcloud (Apache)
/usr/bin/docker pull nextcloud:stable-apache

# Remove container anterior se existir
/usr/bin/docker rm -f nextcloud || true

# Variáveis
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
TRUSTED_DOMAINS="${trusted_domains}"

/usr/bin/docker run -d \
  --name nextcloud \
  --restart unless-stopped \
  -p 80:80 \
  -v /mnt/nextcloud/html:/var/www/html \
  -e POSTGRES_HOST="$DB_HOST" \
  -e POSTGRES_DB="$DB_NAME" \
  -e POSTGRES_USER="$DB_USER" \
  -e POSTGRES_PASSWORD="$DB_PASS" \
  -e NEXTCLOUD_TRUSTED_DOMAINS="$TRUSTED_DOMAINS" \
  nextcloud:stable-apache

# Health endpoint: status.php fica em /status.php após instalação


