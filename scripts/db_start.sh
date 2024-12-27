#!/bin/sh

# check if YTKP_DIR is set
if [ -z "${YTKP_DIR}" ] ; then
    echo "YTKP_DIR is not set."
    exit 1
fi

# run everytime the shell is restarted to start postgres process
pg_ctl \
 --pgdata=$PREFIX/var/lib/postgresql \
 --log=${YTKP_DIR}/database/logs/pg_ctl.log \
 start
