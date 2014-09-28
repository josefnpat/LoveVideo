#!/bin/sh

INPUT_FILE=$1
OUTPUT_DIR=$2

TEMP=`mktemp -d`

FPS=24
OPEN_GL_TEXTURE_MAX=2048
WIDTH=`exiftool -q -p '\$ImageWidth' $INPUT_FILE`
HEIGHT=`exiftool -q -p '\$ImageHeight' $INPUT_FILE`

echo "Detecting image size of ${WIDTH}x${HEIGHT} .."

COLUMNS=`expr $OPEN_GL_TEXTURE_MAX / $WIDTH`
ROWS=`expr $OPEN_GL_TEXTURE_MAX / $HEIGHT`
TILE_COUNT=`expr $ROWS \* $COLUMNS`

FORMAT=jpg

echo "Converting $INPUT_FILE to raw $FORMAT ($TEMP) .."

avconv -i $INPUT_FILE -r $FPS -f image2 \
  -v quiet \
  $TEMP/raw-%d.$FORMAT

FRAME_COUNT=`ls $TEMP/raw-*.$FORMAT | wc -l`

COUNT=0

NEW_FRAME_TOTAL=$(( ( ${FRAME_COUNT} - ( ${FRAME_COUNT} % ${TILE_COUNT}) )/${TILE_COUNT} )) #CEIL(FRAME_COUNT/TILE_COUNT)
NEW_FRAME_INPUTS=""
NEW_FRAME_INDEX=0

mkdir -p $OUTPUT_DIR

for i in `seq 1 $FRAME_COUNT`
do
  NEW_FRAME_INPUTS="$NEW_FRAME_INPUTS $TEMP/raw-$i.$FORMAT"
  COUNT=$((COUNT+1))
  if [ $COUNT -eq $TILE_COUNT ] || [ $COUNT -eq $FRAME_COUNT ]
  then
    NEW_FRAME_INDEX=$((NEW_FRAME_INDEX+1))
    echo "Processing frame $NEW_FRAME_INDEX/$NEW_FRAME_TOTAL .."
    COUNT=0
    montage \
      $NEW_FRAME_INPUTS \
      -tile $COLUMNS -geometry +0+0 $OUTPUT_DIR/$NEW_FRAME_INDEX.$FORMAT
    NEW_FRAME_INPUTS=""
  fi
done

INFO_TARGET=$OUTPUT_DIR/info.lua
INFO_TEMPLATE=info.lua.template
echo "Generating $INFO_TARGET from $INFO_TEMPLATE .."

cp $INFO_TEMPLATE $INFO_TARGET
sed -i "s/%FORMAT%/$FORMAT/" $INFO_TARGET
sed -i "s/%FPS%/$FPS/" $INFO_TARGET
sed -i "s/%WIDTH%/$WIDTH/" $INFO_TARGET
sed -i "s/%HEIGHT%/$HEIGHT/" $INFO_TARGET
sed -i "s/%ROWS%/$ROWS/" $INFO_TARGET
sed -i "s/%COLUMNS%/$COLUMNS/" $INFO_TARGET

AUDIO_TARGET=$OUTPUT_DIR/audio.ogg
echo "Extracting audio ($AUDIO_TARGET) .."
avconv -i $INPUT_FILE  -vn -acodec libvorbis \
  -v quiet \
  $AUDIO_TARGET

echo "Cleaning up ($TEMP) .."
rm -rf $TEMP
