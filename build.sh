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
KERNEL_DIR=$PWD/out
KERN_IMG=$KERNEL_DIR/arch/arm64/boot/Image.gz-dtb
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
mkdir -p $KERNEL_DIR
COMPILER=""
#make $J clean mrproper
#make $J O=$KERNEL_DIR clean mrproper

# Get Toolchain
Toolchain=$(pwd)/../Toolchain
TOOL_VER="linaro"

function TC() {

if [[ -d ${Toolchain} ]]; then
	if [[ -d ${Toolchain}/.git ]]; then
			cd ${Toolchain}
			git fetch origin
                        git reset --hard @{u}
                        git clean -fxd > /dev/null 2>&1
                        cd ${KERNEL_DIR}/..
	else
		rm -rf ${Toolchain}
	fi
else
	git clone https://github.com/AndroiableDroid/aarch64-linux-kernel-linaro-7.x.git $Toolchain
fi
}

find_compiler()
{
	COMPILER="$(find $Toolchain/bin/ | grep -oE '[^ ]+gcc' | grep -o '[^/]*$' | sed -e 's:\-gcc:\-:' | head -1)";
}

# Modify the following variable if you want to build
find_compiler
export CROSS_COMPILE=$Toolchain/bin/$COMPILER
export ARCH=arm64
export SUBARCH=arm64
export KBUILD_BUILD_USER="Faraz"
export KBUILD_BUILD_HOST="TimeMachine"
export USE_CCACHE=1
BUILD_DIR=$(pwd)/build
VERSION="XII"
DATE=$(date -u +%Y%m%d-%H%M)
ZIP_NAME=Destructive-$DEVICE-$VERSION-$DATE

compile_kernel ()
{
echo -e "$cyan****************************************************"
echo "             Compiling Destructive kernel        "
echo -e "****************************************************"
echo -e "$nocol"
rm -f $KERN_IMG
make O=$KERNEL_DIR mobee01a_defconfig
make O=$KERNEL_DIR $J
if ! [ -a $KERN_IMG ];
then
echo -e "$red Kernel Compilation failed! Fix the errors! $nocol"
fi


make_zip
}

make_zip ()
{
if [[ $( ls $KERN_IMG 2>/dev/null | wc -l ) != "0" ]]; then
	BUILD_RESULT_STRING="BUILD SUCCESSFUL"
	echo "Making Zip"
	rm $BUILD_DIR/*.zip
	rm $BUILD_DIR/zImage
	cp $KERN_IMG $BUILD_DIR/zImage
	cd $BUILD_DIR
	zip -r ${ZIP_NAME}.zip *
	cd $KERNEL_DIR/..
	rm -rf $KERNEL_DIR
	rm $BUILD_DIR/zImage
else
    BUILD_RESULT_STRING="BUILD FAILED"
fi
}

case $1 in
clean)
make ARCH=arm64 O=$KERNEL_DIR $J clean mrproper
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

