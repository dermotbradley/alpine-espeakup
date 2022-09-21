
# Install Alpine with Speakup activated via espeakup

## Step 1

In the first few lines of the modify-iso.sh script are several variables
which define settings used for the installer: hostname, keyboard_language,
timezone, and username. Edit these if necessary.

Run the script to modify a standard Alpine ISO:

```
./modify-iso.sh < filename of alpine ISO >
```

The script creates a new file alpine-modified.iso in the current directory.

Boot a VM using this alpine-modified.iso file.

Once booted (takes approx 1 or 2 minutes) a login prompt appears.
Type "root" and hit Return to get to the command line.

## Step 2

Then type "/media/cdrom/alpine-prepare" to run the 2nd script.

This script may take approx. 5 minutes to run, it installs Alpine to the disk.

Then shutdown the Alpine VM by typing "poweroff" and hit Return.

You then need to remove the ISO from the VM or change the VM's devices boot
order to ensure it does not boot from the ISO again.

## Step 3

Now start up the VM again.

Once the VM boots from the installed Alpine system (which should take approx
1-2 minutes) a login prompt will appear, type "root" and hit Return to get to
the command line.

Then type "/espeakup-setup" and hit Return. This will update Alpine to Edge,
install the espeakup package, configure it to run on every boot, and also
start it immediately.

You should then have an active screenreader.
