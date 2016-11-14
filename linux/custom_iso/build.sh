#!/bin/bash

# Ubuntu Custom DVD Generator Script v1.00 (2016-09-17)
# -----------------------------------------------------
# Created by djb77 from various sources
# Tested on a clean Ubuntu 16.04.1 LTS x64 ISO image

# Input ISO File: ~/custom-iso/ubuntu-16.04.1-desktop-amd64.iso
# Output ISO File: ~/custom-iso/ubuntu-16.04.1-desktop-amd64-CUSTOM.iso

# HOW TO USE:
# Create a new folder called custom-iso in your home directory, and copy the ubuntu-16.04.1-desktop-amd64.iso and this file into that folder.
# Right-click the custom-iso directory and open a new terminal window.
# Execute the .sh file

# INITIAL SETUP
#--------------
sudo apt-get -y install squashfs-tools genisoimage

mkdir mnt
sudo mount -o loop ubuntu-16.04.1-desktop-amd64.iso mnt
mkdir extract
sudo rsync --exclude=/casper/filesystem.squashfs -a mnt/ extract
sudo unsquashfs mnt/casper/filesystem.squashfs
sudo mv squashfs-root edit
sudo umount mnt
sudo cp /etc/resolv.conf edit/etc/
sudo mount --bind /dev/ edit/dev
sudo chroot edit
mount -t proc none /proc
mount -t sysfs none /sys
mount -t devpts none /dev/pts
export HOME=/root
export LC_ALL=C
dbus-uuidgen > /var/lib/dbus/machine-id
dpkg-divert --local --rename --add /sbin/initctl
ln -s /bin/true /sbin/initctl

# MAKE CHANGES / ADD PACKAGES
#----------------------------
# Add i386 Architecture and Extra Repositories (Needed to slipstream certain packages into ISO)
dpkg --add-architecture i386
add-apt-repository "deb http://archive.ubuntu.com/ubuntu $(lsb_release -sc) universe multiverse"
apt-get update

# Remove All Bloat
# apt-get -y remove aisleriot cheese firefox firefox-locale-en libreoffice-avmedia-backend-gstreamer libreoffice-base-core libreoffice-calc libreoffice-common libreoffice-core libreoffice-draw libreoffice-gnome libreoffice-gtk libreoffice-help-en-us libreoffice-impress libreoffice-math libreoffice-ogltrans libreoffice-pdfimport libreoffice-style-breeze libreoffice-style-galaxy libreoffice-writer gnome-mahjongg gnome-sudoku gnome-mines thunderbird thunderbird-gnome-support thunderbird-locale-en thunderbird-locale-en-us transmission-common transmission-gtk

# Remove AisleRiot Patience
# apt get -y remove aisleriot

# Remove Cheese
# apt get -y remove cheese

# Remove Firefox
# apt get -y remove firefox firefox-locale-en

# Remove LibreOffice
# apt get -y remove libreoffice-avmedia-backend-gstreamer libreoffice-base-core libreoffice-calc libreoffice-common libreoffice-core libreoffice-draw libreoffice-gnome libreoffice-gtk libreoffice-help-en-us libreoffice-impress libreoffice-math libreoffice-ogltrans libreoffice-pdfimport libreoffice-style-breeze libreoffice-style-galaxy libreoffice-writer 

# Remove Mahkongg
# apt get -y remove gnome-mahjongg

# Remove Sudoku
# apt get -y remove gnome-sudoku 

# Remove Mines
# apt get -y remove gnome-mines

# Remove Thunderbird 
# apt get -y remove thunderbird thunderbird-gnome-support thunderbird-locale-en thunderbird-locale-en-us

# Remove Transmission
# apt get -y remove transmission-common transmission-gtk

# Remove Amazon Icon from Unity Menu
# rm -rf /usr/share/applications/ubuntu-amazon-default.desktop

# Install Git
apt-get -y install git

# Install p7zip
apt-get -y install p7zip-full p7zip-rar

# Install Packages for SuperR's Kitchen
apt-get -y install gawk lzop liblz4-tool bison gperf build-essential zlib1g-dev zlib1g-dev:i386 g++-multilib libxml2-utils bzip2 libbz2-dev libbz2-1.0 libghc-bzlib-dev libsepol1-dev dpkg-dev make ccache automake squashfs-tools schedtool

# Install Packaged for Android Studio
apt-get -y install libc6:i386 libncurses5:i386 libstdc++6:i386 lib32z1

# Install Java
apt-get -y install default-jdk

# Install Tweak Tools
apt-get -y install unity-tweak-tool gnome-tweak-tool

# Install Google Chrome
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
apt-get update
apt-get -y install google-chrome-stable

# Update Packages in the ISO 
apt-get -y upgrade

# Perform after installing eztra packages and Log out of Filesystem
apt-get -y autoremove
apt-get -y autoclean
apt-get -y clean
rm -rf /tmp/* ~/.bash_history
rm /var/lib/dbus/machine-id
rm /sbin/initctl
dpkg-divert --rename --remove /sbin/initctl
umount /proc || umount -lf /proc
umount /sys
umount /dev/pts
exit

# PREPARE FILES
# -------------
sudo umount edit/dev

sudo chmod +w extract/casper/filesystem.manifest
sudo chroot edit dpkg-query -W --showformat='${Package} ${Version}n' | sudo tee extract/casper/filesystem.manifest
sudo cp extract/casper/filesystem.manifest extract/casper/filesystem.manifest-desktop
sudo sed -i '/ubiquity/d' extract/casper/filesystem.manifest-desktop
sudo sed -i '/casper/d' extract/casper/filesystem.manifest-desktop
sudo mksquashfs edit extract/casper/filesystem.squashfs -comp xz -e edit/boot

sudo printf $(sudo du -sx --block-size=1 edit | cut -f1) | sudo tee extract/casper/filesystem.size

cd extract
sudo rm md5sum.txt
find -type f -print0 | sudo xargs -0 md5sum | grep -v isolinux/boot.cat | sudo tee md5sum.txt

# CREATE ISO IMAGE
# ----------------
build_date=`date +%Y%m%d`
sudo genisoimage -D -r -V "Ubuntu 16.04-djb77_$build_date" -cache-inodes -J -l -b isolinux/isolinux.bin -c isolinux/boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -o ../ubuntu-16.04.1-desktop-amd64-CUSTOM.iso .

