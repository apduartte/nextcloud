#!/bin/bash
set -euxo pipefail

############################################
# Variáveis vindas do Terraform (templatefile)
############################################
EFS_DNS="${efs_dns}"
DB_HOST="${db_host}"
DB_NAME="${db_name}"
DB_USER="${db_user}"
DB_PASS="${db_pass}"
TRUSTED_DOMAINS="${trusted_domains}"
ALB_DNS_NAME="${alb_dns_name}"

############################################
# Funções auxiliares
############################################
log() {
  echo "[$(date -Is)] $*"
}

is_mounted() {
  grep -qs " /mnt/nextcloud " /proc/mounts
}

############################################
# Atualização de pacotes e instalação
############################################

if command -v dnf >/dev/null 2>&1; then
  PKG_MGR="dnf"
else
  PKG_MGR="yum"
fi

log "Atualizando pacotes do sistema (best effort)"
$PKG_MGR update -y || true

log "Instalando Docker, NFS e EFS utils"
$PKG_MGR install -y docker nfs-utils amazon-efs-utils || $PKG_MGR install -y docker nfs-utils

systemctl enable --now docker

############################################
# Montagem do EFS com TLS (se possível)
############################################

log "Montando EFS em /mnt/nextcloud (DNS: $EFS_DNS)"
mkdir -p /mnt/nextcloud

for i in 1 2 3 4 5; do
  if is_mounted; then
    break
  fi

  # Tenta montar com EFS utils + TLS
  if mount -t efs -o tls "$EFS_DNS:/" /mnt/nextcloud 2>/dev/null; then
    break
  fi

  # Fallback para NFSv4 se EFS utils não estiver disponível
  if mount -t nfs4 -o nfsvers=4.1,rsize=1048576,wsize=1048576,hard,timeo=600,retrans=2 "$EFS_DNS:/" /mnt/nextcloud 2>/dev/null; then
    break
  fi

  log "Falha ao montar EFS ($EFS_DNS), tentativa $i/5. Aguardando 10s..."
  sleep 10
done

if ! is_mounted; then
  log "ERRO: não foi possível montar o EFS em /mnt/nextcloud"
  exit 1
fi

log "Aplicando permissões para usuário www-data (uid 33)"
chown -R 33:33 /mnt/nextcloud
mkdir -p /mnt/nextcloud/html
chown -R 33:33 /mnt/nextcloud/html

############################################
# Container Docker do Nextcloud
############################################

log "Baixando imagem nextcloud:stable-apache"
/usr/bin/docker pull nextcloud:stable-apache

log "Removendo container anterior (se existir)"
/usr/bin/docker rm -f nextcloud || true

log "Subindo container Nextcloud"
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

log "User-data concluído. Após a instalação, o health-check estará disponível em /status.php."


