#!/bin/sh
set -eu

# === Variables requeridas ===
: "${SSH_HOST:?}"                         # ej: odoo@mesquita.com.ar
: "${REMOTE_DIR_DB_BACKUPS:?}"            # ej: /home/odoo/.../db_backups/
: "${REMOTE_DIR_FS_BACKUPS:?}"            # ej: /home/odoo/.../fs_backups/
SSH_PORT="${SSH_PORT:-}"                  # opcional
SSH_PASS="${SSH_PASS:-}"                  # opcional

# === Config interna ===
LOCAL_BASE="/backups"
STAMP="$(date +%F_%H%M)"
mkdir -p "$LOCAL_BASE/db/current" "$LOCAL_BASE/db/versions" \
         "$LOCAL_BASE/fs/current" "$LOCAL_BASE/fs/versions"

# === Config SSH ===
ssh_base_opts="-o StrictHostKeyChecking=accept-new -o ConnectTimeout=10 -o BatchMode=yes"
[ -n "$SSH_PORT" ] && ssh_base_opts="$ssh_base_opts -p $SSH_PORT"

# === Selección de modo de autenticación ===
if [ -S "${SSH_AUTH_SOCK:-}" ]; then
  echo "[INFO] Usando agente SSH en $SSH_AUTH_SOCK"
  auth_mode="agent"
elif [ -n "$SSH_PASS" ]; then
  echo "[INFO] Usando modo password"
  auth_mode="password"
else
  echo "[ERROR] No se detectó SSH_AUTH_SOCK ni SSH_PASS." >&2
  exit 1
fi

# === Probar conexión ===
if [ "$auth_mode" = "password" ]; then
  if sshpass -p "$SSH_PASS" \
       ssh -o StrictHostKeyChecking=accept-new \
           -o ConnectTimeout=10 \
           -o PubkeyAuthentication=no \
           -o PreferredAuthentications=password,keyboard-interactive \
           -o NumberOfPasswordPrompts=1 \
           ${SSH_PORT:+-p "$SSH_PORT"} \
           -q "$SSH_HOST" true 2>/dev/null; then
    echo "[INFO] Autenticación SSH exitosa mediante password."
  else
    echo "[ERROR] Falló autenticación por password." >&2
    exit 1
  fi
else
  if ssh $ssh_base_opts -q "$SSH_HOST" true 2>/dev/null; then
    echo "[INFO] Autenticación SSH exitosa mediante agente."
  else
    echo "[ERROR] Falló autenticación SSH (agente no válido o clave no cargada)." >&2
    exit 1
  fi
fi

# === Sincronizar DB backups ===
echo "[$(date -Is)] Sync DB backups ($auth_mode)"
if [ "$auth_mode" = "password" ]; then
  ssh_opts="-o StrictHostKeyChecking=accept-new ${SSH_PORT:+-p $SSH_PORT}"
  sshpass -p "$SSH_PASS" \
    rsync -avz --delete --backup \
      --backup-dir="$LOCAL_BASE/db/versions/$STAMP" \
      -e "ssh $ssh_opts" \
      "${SSH_HOST}:${REMOTE_DIR_DB_BACKUPS}" "$LOCAL_BASE/db/current/"
else
  rsync -avz --delete --backup \
    --backup-dir="$LOCAL_BASE/db/versions/$STAMP" \
    -e "ssh $ssh_base_opts" \
    "${SSH_HOST}:${REMOTE_DIR_DB_BACKUPS}" "$LOCAL_BASE/db/current/"
fi

# === Sincronizar FS backups ===
echo "[$(date -Is)] Sync FS backups ($auth_mode)"
if [ "$auth_mode" = "password" ]; then
  ssh_opts="-o StrictHostKeyChecking=accept-new ${SSH_PORT:+-p $SSH_PORT}"
  sshpass -p "$SSH_PASS" \
    rsync -avz --delete --backup \
      --backup-dir="$LOCAL_BASE/fs/versions/$STAMP" \
      -e "ssh $ssh_opts" \
      "${SSH_HOST}:${REMOTE_DIR_FS_BACKUPS}" "$LOCAL_BASE/fs/current/"
else
  rsync -avz --delete --backup \
    --backup-dir="$LOCAL_BASE/fs/versions/$STAMP" \
    -e "ssh $ssh_base_opts" \
    "${SSH_HOST}:${REMOTE_DIR_FS_BACKUPS}" "$LOCAL_BASE/fs/current/"
fi

echo "[$(date -Is)] Backup completo"
