#!/bin/sh

# run once after fresh postgres install
mkdir -p $PREFIX/var/lib/postgresql
initdb $PREFIX/var/lib/postgresql
