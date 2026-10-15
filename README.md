# COPIA REMOTA DE BACKUPS ODOO MESQUITA

Este script permite copiar los backups creados por [https://github.com/mezka/odoo-backup-script](https://github.com/mezka/odoo-backup-script) a una carpeta local preconfigurado para realizarse en cada boot del contenedor y diariamente en un horario determinado por el usuario.

Para provisionar, debe crearse un archivo `.env` que contendra las variables de entorno necesarias para la ejecución del script.

```
SSH_HOST=odoo@odoo.mesquita.com.ar
SSH_PASS=your-ssh-pass
SSH_PORT=22
REMOTE_DIR_DB_BACKUPS=/home/odoo/odoo-backup-script/db_backups/
REMOTE_DIR_FS_BACKUPS=/home/odoo/odoo-backup-script/fs_backups/
```

Si no se provee una SSH_PASS el script intentara utilizar la claves privadas cargadas en el agente SSH.

## Autenticacion con clave SSH

La clave debe estar cargada en un agente SSH del equipo donde se ejecuta Docker.
Tener el archivo de clave en `~/.ssh` no es suficiente. En la misma terminal donde
vas a ejecutar Docker Compose:

```sh
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed25519
ssh-add -l
docker compose up -d --build
docker compose logs -f puller
```

Reemplaza `~/.ssh/id_ed25519` por la ruta de tu clave privada. Si tiene una frase
de paso, `ssh-add` la solicitara. La clave publica correspondiente debe estar
autorizada en el servidor remoto.

`SSH_AUTH_SOCK` lo define `ssh-agent`: no debe apuntar al archivo de la clave ni
quedar fijado en `.env`, porque su ruta puede cambiar al iniciar otro agente.
Si ya tenes un agente activo, basta con cargar la clave con `ssh-add`.
Si reinicias el agente, recrea el contenedor para montar el nuevo socket:

```sh
docker compose up -d --force-recreate
```

Sin agente, Compose monta `/dev/null` en lugar del socket y el script puede usar
`SSH_PASS`. Si no hay agente ni password, el script informa el error y termina.
Si hay un agente disponible, tiene prioridad sobre `SSH_PASS`.

Si no logra logearse el script terminara su ejecución de manera ordenada.
