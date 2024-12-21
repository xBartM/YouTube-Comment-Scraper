#!/bin/sh

# run everytime the shell is restarted
pg_ctl -D $PREFIX/var/lib/postgresql start
