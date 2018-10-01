#
# Copyright © 2016, Varun Chitre "varun.chitre15" <varun.chitre15@gmail.com>
# Copyright © 2017, Ritesh Saxena <riteshsax007@gmail.com>
# Copyright © 2018, Mohd Faraz <mohd.faraz.abc@gmail.com>
#
# Custom build script
#
# This software is licensed under the terms of the GNU General Public
# License version 2, as published by the Free Software Foundation, and
# may be copied, distributed, and modified under those terms.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# Please maintain this if you use this script or any part of it
#
KERNEL_DIR=$PWD
KERN_IMG=$KERNEL_DIR/arch/arm64/boot/Image.gz
DTBTOOL=$KERNEL_DIR/tools/dtbToolCM
BUILD_START=$(date +"%s")
blue='\033[0;34m'
cyan='\033[0;36m'
green='\e[0;32m'
yellow='\033[0;33m'
red='\033[0;31m'
nocol='\033[0m'
purple='\e[0;35m'
white='\e[0;37m'
DEVICE="LS-5015"
J="-j$(grep -c ^processor /proc/cpuinfo)"
make $J clean mrproper

# Get Toolchain

Toolchain=$KERNEL_DIR/../Toolchain

function TC() {

if [[ -d ${Toolchain} ]]; then
	if [[ -d ${Toolchain}/.git ]]; then
			cd ${Toolchain}
			git fetch origin
                        git reset --hard origin/master
                        git clean -fxd > /dev/null 2>&1
                        cd ${KERNEL_DIR}
	else
		rm -rf ${Toolchain}
	fi
else
	git clone https://github.com/AndroiableDroid/aarch64-linux-kernel-linaro-7.x.git $Toolchain
fi
}

# Modify the following variable if you want to build
export CROSS_COMPILE=$Toolchain/bin/aarch64-linaro-linux-gnu-
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="Faraz"
export KBUILD_BUILD_HOST="TimeMachine"
export USE_CCACHE=1
BUILD_DIR=$KERNEL_DIR/build
VERSION="X4"
DATE=$(date -u +%Y%m%d-%H%M)
ZIP_NAME=Nichrome-$DEVICE-$VERSION-$DATE

compile_kernel ()
{
echo -e "$cyan****************************************************"
echo "             Compiling Nichrome kernel        "
echo -e "****************************************************"
echo -e "$nocol"
rm -f $KERN_IMG
make test01a_msm_defconfig
make $J
echo "$cyan Making dt.img"
echo -e "$nocol"
$DTBTOOL -2 -o $KERNEL_DIR/arch/arm64/boot/dt.img -s 2048 -p $KERNEL_DIR/scripts/dtc/ $KERNEL_DIR/arch/arm/boot/dts/
if ! [ -a $KERN_IMG ];
then
echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
fi


make_zip
}

make_zip ()
{
if [[ $( ls ${KERNEL_DIR}/arch/arm64/boot/Image.gz 2>/dev/null | wc -l ) != "0" ]]; then
	BUILD_RESULT_STRING="BUILD SUCCESSFUL"
	echo "Making Zip"
	rm $BUILD_DIR/*.zip
	rm $BUILD_DIR/zImage
	cp $KERNEL_DIR/arch/arm64/boot/Image.gz $BUILD_DIR/zImage
        cp $KERNEL_DIR/arch/arm64/boot/dt.img $BUILD_DIR/dt.img
	cd $BUILD_DIR
	zip -r ${ZIP_NAME}.zip *
	cd $KERNEL_DIR
	rm -rf $KERNEL_DIR/out
	rm $BUILD_DIR/zImage
else
    BUILD_RESULT_STRING="BUILD FAILED"
fi
}

case $1 in
clean)
make ARCH=arm64 $J clean mrproper
;;
*)
TC
compile_kernel
;;
esac
BUILD_END=$(date +"%s")
DIFF=$(($BUILD_END - $BUILD_START))
if [[ "${BUILD_RESULT_STRING}" = "BUILD SUCCESSFUL" ]]; then
echo -e "$cyan****************************************************************************************$nocol"
echo -e "$cyan*$nocol${red} ${BUILD_RESULT_STRING}$nocol"
echo -e "$cyan*$nocol$yellow Build completed in $(($DIFF / 60)) minute(s) and $(($DIFF % 60)) seconds.$nocol"
echo -e "$cyan*$nocol${green} ZIP LOCATION: ${BUILD_DIR}/${ZIP_NAME}.zip$nocol"
echo -e "$cyan*$nocol${green} SIZE: $( du -h ${BUILD_DIR}/${ZIP_NAME}.zip | awk '{print $1}' )$nocol"
echo -e "$cyan****************************************************************************************$nocol"
fi
