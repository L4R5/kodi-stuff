#!/bin/bash

FIFO=/tmp/yd-fifo

echo $* >> $FIFO
echo added: $*
