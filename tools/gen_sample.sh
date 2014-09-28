#!/bin/sh

TEMP=`mktemp -d`
TARGET_DIR=http://download.blender.org/durian/trailer/
TARGET_FILE=sintel_trailer-480p.mp4

SAMPLE_DIR=samples

mkdir -p $SAMPLE_DIR

wget -c $TARGET_DIR/$TARGET_FILE -O $TEMP/$TARGET_FILE
tools/convert.sh $TEMP/$TARGET_FILE $SAMPLE_DIR/sintel/

rm -rf $TEMP
