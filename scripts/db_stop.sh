#!/bin/sh

# run everytime the shell is restarted to start postgres process
pg_ctl -D $PREFIX/var/lib/postgresql stop
