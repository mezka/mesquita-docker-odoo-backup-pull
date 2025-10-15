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

Si no logra logearse el script terminara su ejecución de manera ordenada.
