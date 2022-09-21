#!/bin/sh

####### START OF CONFIGURATION ############################

hostname="alpinelaptop"
keyboard_language="us us"
timezone="EST"
username="test"

####### END OF CONFIGURATION ##############################
#
# Do not change anything below here
#

readonly DEFAULT_FILE="alpine-standard-3.16.2-x86_64.iso"
readonly NEW_ISO_FILENAME="modified-alpine.iso"
readonly PREPARE_SCRIPT="prepare-alpine"

_tmp_dir_base="${TMPDIR:-$PWD}"
_new_iso_dir="$_tmp_dir_base/create-iso"
_new_iso_file="$PWD/$NEW_ISO_FILENAME"


check_programs_installed ()
{
  if type -f mkisofs ; then
    :    
  fi
}

error_cleanup() {
  # Ensure not in any directory likely to be removed
  cd

  if [ -d $_new_iso_dir ]; then
    sudo rm -Rf $_new_iso_dir
  fi

  sudo umount /mnt
}


###check_program_installed mkisofs

_iso_file=$DEFAULT_FILE
if [ $# -eq 1 ]; then
  _iso_file="$1"
fi

if [ ! -f "$_iso_file" ]; then
  echo "file $_iso_file does not exist! Aborting..."
  exit 1
fi
echo "Using ISO file $_iso_file"

# Mount the existing ISO file via loopback
sudo mount -t iso9660 -o loop,ro $_iso_file /mnt/
_rc=$?
if [ $_rc -ne 0 ]; then
  echo "There was a problem mounting the existing ISO file, error code $_rc. Aborting..."
  exit 1
fi

# Ensure that if any errors occur the ISO is unmounted
trap error_cleanup EXIT

if [ -d $_new_iso_dir ]; then
  sudo rm -Rf $_new_iso_dir
fi
mkdir $_new_iso_dir
_rc=$?
if [ $_rc -ne 0 ]; then
  echo "There was a problem creating a temporary directory, error code $_rc. Aborting..."
  exit 1
fi

# Copy the contents of the existing ISO ensuring that permissions
# etc are preserved
cd /mnt; tar -cf - . | (cd $_new_iso_dir; tar xfp - )
cd
chmod +w $_new_iso_dir

# Write speakup script inside top-level directory of iso
cat <<_EOF_ >> $_new_iso_dir/$PREPARE_SCRIPT
#!/bin/sh

if [ -f /dev/vda ]; then
  root_device="/dev/vda"
else
  root_device="/dev/sda"
fi
root_partition="\${root_device}3"

# Create an answer file for the Alpine installer to use
cat <<-_ANSWER_ >> answer-file
	KEYMAPOPTS="$keyboard_language"
	HOSTNAMEOPTS="$hostname"
	DEVDOPTS="mdev"
	INTERFACESOPTS=" auto lo
	iface lo inet loopback
	
	auto eth0
	iface eth0 inet dhcp
	    hostname \$HOSTNAMEOPTS
	"
	TIMEZONEOPTS="$timezone"
	PROXYOPTS=none
	APKREPOSOPTS="-f"
	USEROPTS="$username"
	SSHDOPTS=openssh
	NTPOPTS=chrony
	DISKOPTS="-m sys \$root_device"
	LBUOPTS=none
	APKCACHEOPTS=none
	_ANSWER_

ERASE_DISKS="\$root_device" setup-alpine -e -f ./answer-file

mount \${root_partition} /mnt
cat <<-_ESPEAK_ >> /mnt/root/espeakup-setup
	#!/bin/sh
	
	cat <<_MODULE_ >> /etc/modules.d/speakup
	speakup_soft
	_MODULE_

	modprobe speakup_soft
	
	sed -i -E \\
	  -e 's|^#(http.*)$|\1|g' \\
	  -e 's|^(http.*3.16.*)$|#\1|g' \\
	  /etc/apk/repositories
	apk -Ua upgrade
	
	apk add espeakup
	rc-update add espeakup
	/etc/init.d/espeakup start
	
	exit
	_ESPEAK_
chmod +x /mnt/root/espeakup-setup

umount /mnt

exit
_EOF_
chmod +x $_new_iso_dir/$PREPARE_SCRIPT

# Create new ISO file
if [ -f $_new_iso_file ]; then
  rm -f $_new_iso_file
fi
cd $_new_iso_dir; sudo mkisofs \
  -q \
  -o $_new_iso_file \
  -b boot/syslinux/isolinux.bin \
  -c boot/syslinux/boot.cat \
  -no-emul-boot \
  -boot-load-size 4 \
  -boot-info-table \
  -J \
  -R \
  -V "Customised Alpine ISO" \
  .
_rc=$?
if [ $_rc -ne 0 ]; then
  echo "There was a problem creating the customised ISO, error code $_rc. Aborting..."
  exit 1
else
  echo "Customised ISO created"
fi

# Clear exit trap function
trap EXIT

# Delete the temporary directory
sudo rm -Rf $_new_iso_dir

# Unmount the existing ISO file
sudo umount /mnt

echo "Script finished"

exit
