#
# by brad.antoniewicz@foundstone.om
# Note this file is part of a Bundle and 
# will not run by itself. Its included here
# just to be used as a reference so people
# can know how to install everything

#RUN_DIR=/cdrom/for-rob
RUN_DIR=`pwd`
BUILD_NAME=BRAD-20120703-2
BUNDLE_NAME=BT5R2-4.9Ghz-DriverBuild-$BUILD_NAME
COMPAT_VER=compat-wireless-3.3-1
CRDA_VER=crda-1.1.2
REGDB_VER=wireless-regdb-2011.04.28
DB_VER=db-ReturnTrue.txt
PATCH_NAME=$COMPAT_VER-$BUILD_NAME.patch

# compat-wireless-3.3-1-BRAD-20120703.patch

mount -o remount,rw /cdrom
#/cdrom/package/update.sh

#echo "[+] Copying $BUNDLE_NAME from the USB stick"
#cp -R $RUN_DIR ~/$BUNDLE_NAME
#RUN_DIR=~/$BUNDLE_NAME

echo "[+] Changing directories to $RUN_DIR"
cd $RUN_DIR


rm -rf $COMPAT_VER $CRDA_VER $REGDB_VER

echo "[+] Installing pre-requisites"

dpkg --install /cdrom/package/libnl-dev_1.1-5build1_i386.deb 
dpkg --install /cdrom/package/libssl-dev_0.9.8k-7ubuntu8.8_i386.deb
dpkg --install $RUN_DIR/packages/python-m2crypto_0.20.1-1ubuntu2_i386.deb

apt-get -o=dir::cache=$RUN_DIR/packages/ -f install
apt-get -o=dir::cache=$RUN_DIR/packages/ install python-m2crypto libssl-dev build-essential
apt-get -o=dir::cache=$RUN_DIR/packages/ install build-essential libssl-dev
apt-get -o=dir::cache=$RUN_DIR/packages/ install python-m2crypto

cd $RUN_DIR

echo "[+] Creating Public/Private Keys"
openssl genrsa -out key_for_regdb.priv.pem 2048
openssl rsa -in key_for_regdb.priv.pem -out key_for_regdb.pub.pem -pubout -outform PEM

echo "[+] Extracting/Installing regdb"
cd $RUN_DIR
tar -jxf $REGDB_VER.tar.bz2
cd $RUN_DIR/$REGDB_VER
mv db.txt db.orig
cp $RUN_DIR/$DB_VER db.txt 

make
./db2bin.py regulatory.bin db.txt $RUN_DIR/key_for_regdb.priv.pem 
make install
cp $RUN_DIR/key_for_regdb.pub.pem /usr/lib/crda/pubkeys/


echo "[+] Extracting/Installing CRDA"
cd $RUN_DIR
tar -jxf $CRDA_VER.tar.bz2
cd $RUN_DIR/$CRDA_VER
cp $RUN_DIR/key_for_regdb.pub.pem pubkeys/
make
make install

#echo "[+] Unloading Old Drivers"
#rmmod b43 ath5k iwlwifi ath iwlagn mac80211 cfg80211

#exit

echo "[+] Setting up modules"
ln -s /usr/src/linux /lib/modules/`uname -r`/build

#echo "Downloading"
#wget http://linuxwireless.org/download/compat-wireless-2.6/compat-wireless-2011-07-14.tar.bz2
#wget http://www.backtrack-linux.org/2.6.39.patches.tar


echo "[+] Extracting compat-wireless"
cd $RUN_DIR
tar -jxf $COMPAT_VER.tar.bz2  

echo "[+] Unloading old drivers"
cd $RUN_DIR/$COMPAT_VER
scripts/wlunload.sh

echo "[+] Using driver-select for ath5k"
scripts/driver-select ath5k

echo "[+] Patching compat-wireless with aircrack-ng patches"
cd $RUN_DIR/$COMPAT_VER

patch -p1 < $RUN_DIR/patches/mac80211-2.6.29-fix-tx-ctl-no-ack-retry-count.patch
patch -p1 < $RUN_DIR/patches/mac80211.compat08082009.wl_frag+ack_v1.patch
patch -p1 < $RUN_DIR/patches/zd1211rw-2.6.28.patch
patch -p1 < $RUN_DIR/patches/ipw2200-inject.2.6.36.patch

echo "[+] Applying shady brad patch"
#patch -p1 < $RUN_DIR/compat-wireless-3.2.5-1-EnablePS-BA.patch
#patch -p1 < $RUN_DIR/$COMPAT_VER-ReturnTrue-BA.patch
#patch -p1 < $RUN_DIR/$COMPAT_VER-devRADAR-1.patch
patch -p1 < $RUN_DIR/$PATCH_NAME


echo "[+] Building"
make
make install
make wlunload

echo "[+] Loading new drivers"
modprobe ath5k 

#um /lib/modules/2.6.39.4/kernel/drivers/net/wireless/ath/ath5k/ath5k.ko
#942e1f025d5065174dc2aac6a4d39155  /lib/modules/2.6.39.4/kernel/drivers/net/wireless/ath/ath5k/ath5k.ko


echo "[+] Uninstalling BT5R2's kismet"
dpkg -r kismet

echo "[+] Installing Kismet SVN 3505"
dpkg --install $RUN_DIR/packages/kismet_svn-3505-1_i386.deb

echo "[+] Copying over kismet.conf"
cd /usr/local/etc
mv kismet.conf kismet.conf.old
#cp $RUN_DIR/kismet-ReturnTrue.conf kismet.conf
cp $RUN_DIR/kismet-devRADAR-1.conf kismet.conf

cd $RUN_DIR

echo "-------------------------------------"
echo "[+] Ok! All done!"
echo "[+] Load with:"
echo -e "\tmodprobe ath5k default_bwmode=1\n"
echo -e "\tdefault_bwmode can be:\n"
echo -e "\t0=20MHz; 1=5MHz; 2=10MHz; 3=40MHz\n"
