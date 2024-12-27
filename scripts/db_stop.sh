#!/bin/sh

# run everytime the shell is restarted to start postgres process
pg_ctl \
 --pgdata=$PREFIX/var/lib/postgresql \
 --mode=smart \
 stop
