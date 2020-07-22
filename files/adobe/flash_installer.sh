set -e

DIST="/tmp/flash_player_npapi_linux.x86_64.tar.gz"
TMP_DIR="/tmp/flash_dir"
PLUGINS_DIR=/usr/lib/mozilla/plugins

#SANITY CHECKS
test -f    $DIST           ||  { echo "tarball $DIST" not found ; exit 1 ; }
test -d    $PLUGINS_DIR    ||  { echo "Dir $PLUGINS_DIR/" not found ; exit 1 ; }

# 1. Go to https://get.adobe.com/flashplayer/otherversions/
# 2. wget https://fpdownload.adobe.com/get/flashplayer/pdc/32.0.0.255/flash_player_npapi_linux.x86_64.tar.gz

mkdir -p $TMP_DIR 

(cd $TMP_DIR; tar -zxf $DIST)

cp  ${TMP_DIR}/libflashplayer.so    $PLUGINS_DIR
rsync -av  ${TMP_DIR}/usr/*         /usr

#https://helpx.adobe.com/flash-player.html

rm -rf $TMP_DR
