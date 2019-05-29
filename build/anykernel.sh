
# shell variables
block=/dev/block/bootdevice/by-name/boot;

## end setup


## AnyKernel methods (DO NOT CHANGE)
# set up extracted files and directories
project=/tmp/anykernel/project/*;
bin=/tmp/anykernel/tools;
split_img=/tmp/anykernel/split_img;
patch=/tmp/anykernel/patch;
kernel=/tmp/anykernel/zImage;

chmod -R 755 $bin;
mkdir $split_img;
#ramdisk=/tmp/anykernel/split_img/ramdisk;

# dump boot and extract ramdisk
dump_boot() {
  dd if=$block of=/tmp/anykernel/boot.img;
  $bin/unpackbootimg -i /tmp/anykernel/boot.img -o $split_img;
  if [ $? != 0 ]; then
    ui_print " "; ui_print "Dumping/unpacking image failed. Aborting...";
    echo 1 > /tmp/anykernel/exitcode; exit;
  fi;
}

ramdisk() {
  mkdir $ramdisk;
  cd $ramdisk;
  gzip -dc ../boot.img-ramdisk.gz | cpio -i;
  rm -rf ../boot.img-ramdisk.gz;
  cp $project $ramdisk;
  find . | cpio -o -H newc | gzip > ../boot.img-ramdisk.gz
  ui_print "Ramdisk Fixing Done";

}
  

# repack ramdisk then build and write image
write_boot() {
  cd $split_img;
  cmdline=`cat *-cmdline`;
  board=`cat *-board`;
  base=`cat *-base`;
  pagesize=`cat *-pagesize`;
  kerneloff=`cat *-kerneloff`;
  ramdiskoff=`cat *-ramdiskoff`;
  tagsoff=`cat *-tagsoff`;
  if [ -f *-second ]; then
    second=`ls *-second`;
    second="--second $split_img/$second";
    secondoff=`cat *-secondoff`;
    secondoff="--second_offset $secondoff";
  fi;
  $bin/mkbootimg --kernel $kernel --ramdisk /tmp/anykernel/split_img/boot.img-ramdisk.gz $second --cmdline "$cmdline" --board "$board" --base $base --pagesize $pagesize --kernel_offset $kerneloff --ramdisk_offset $ramdiskoff $secondoff --tags_offset $tagsoff --output /tmp/anykernel/boot-new.img;
  if [ $? != 0 -o `wc -c < /tmp/anykernel/boot-new.img` -gt `wc -c < /tmp/anykernel/boot.img` ]; then
    ui_print " "; ui_print "Repacking image failed. Aborting...";
    echo 1 > /tmp/anykernel/exitcode; exit;
  fi;
  dd if=/tmp/anykernel/boot-new.img of=$block;
}

dump_boot;

#ramdisk;

write_boot;

## end install

