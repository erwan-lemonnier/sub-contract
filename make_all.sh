#!/bin/sh

rm MANIFEST
rm META.yml
rm -rf Sub-Contract-*

perl Makefile.PL
make
make manifest
make distdir
make disttest
make tardist
make clean
