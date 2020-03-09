#!/bin/bash

ROOT_UID=0   # Root has $UID 0.

if [ "$UID" -eq "$ROOT_UID" ]
then
   echo "OK"
else
    echo "Run with sudo!"
    echo "sudo ./install.sh"
    exit 0
fi

echo "Hurray, you are root! Let's do this.."
cat <<'EOF'

   _______       _____  _____ _   _          
  |__   __|/\   |  __ \|_   _| \ | |   /\    
     | |  /  \  | |__) | | | |  \| |  /  \   
     | | / /\ \ |  _  /  | | | . ` | / /\ \  
     | |/ ____ \| | \ \ _| |_| |\  |/ ____ \ 
     |_/_/    \_\_|  \_\_____|_| \_/_/    \_\

    +-+ +-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+-+-+-+-+
    |a| |r|e|t|a|k|e| |o|n| |f|i|l|m|m|a|k|i|n|g|
    +-+ +-+-+-+-+-+-+ +-+-+ +-+-+-+-+-+-+-+-+-+-+

EOF
sleep 2
echo "setting up system for filmmaking flow..."
sleep 2
echo "if something goes wrong please submit bug to https://github.com/rbckman/tarina"
sleep 2
version="$(lsb_release -c -s)"
if [ "$version" = "buster" ]
then
    echo "Debian Buster found"
else
    echo "Debian Stretch found"
fi
echo "Installing all dependencies..."
apt-get update
apt-get upgrade -y
if [ "$version" = "buster" ]
then
    apt-get -y install git python3-pip python-configparser libav-tools mediainfo gpac omxplayer sox cpufrequtils apache2 libapache2-mod-wsgi-py3 libdbus-glib-1-dev dbus libdbus-1-dev usbmount
else
    apt-get -y install git python3-pip python-configparser ffmpeg mediainfo gpac omxplayer sox cpufrequtils apache2 libapache2-mod-wsgi-py3 libdbus-glib-1-dev dbus libdbus-1-dev usbmount
fi
echo "installing python-omxplayer-wrapper..."
sudo pip3 install omxplayer-wrapper
echo "installing blessed..."
sudo pip3 install blessed
echo "installing rwb27s openflexure microscope fork of picamera with lens shading correction..."
sudo pip3 --no-cache-dir install https://github.com/rbckman/picamera/archive/master.zip --upgrade
echo "installing web.py for the tarina webserver..."
sudo pip3 install web.py==0.40-dev1

if grep -q -F '#tarina-rpi-configuration-1.0' /boot/config.txt
then
echo "Tarina configuration seems to be in order in /boot/config.txt"
else
echo "Adding to /boot/config.txt"
cat <<'EOF' >> /boot/config.txt
#-----Tarina configuration starts here-------
#tarina-rpi-configuration-1.0
#Rpi-hd-tft
dtoverlay=dpi18
overscan_left=0
overscan_right=0
overscan_top=0
overscan_bottom=0
framebuffer_width=800
framebuffer_height=480
enable_dpi_lcd=1
display_default_lcd=1
dpi_group=2
dpi_mode=87
dpi_output_format=0x6f015
hdmi_timings=480 0 16 16 24 800 0 4 2 2 0 0 0 60 0 32000000 6
display_rotate=3 
start_x=1
gpu_mem=256
dtoverlay=pi3-disable-bt-overlay
dtoverlay=i2c-gpio,i2c_gpio_scl=24,i2c_gpio_sda=23framebuffer_height=480
disable_splash=1
force_turbo=1
boot_delay=1
# dtparam=sd_overclock=90
# Disable the ACT LED.
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off
# Disable the PWR LED.
dtparam=pwr_led_trigger=none
dtparam=pwr_led_activelow=off
#--------Tarina configuration end here---------
EOF
fi

echo "Change hostname to tarina"
cat <<'EOF' > /etc/hostname
tarina
EOF

cat <<'EOF' > /etc/hosts
127.0.0.1	localhost
::1		localhost ip6-localhost ip6-loopback
ff02::1		ip6-allnodes
ff02::2		ip6-allrouters

127.0.1.1	tarina
EOF

echo "consoleblank=0 logo.nologo loglevel=0"
echo "may be put at the end of line in this file /boot/cmdline.txt"
sleep 4

echo "Make USB soundcard default"
echo "writing to /etc/modprobe.d/alsa-base.conf"
if [ "$version" = "buster" ]
then
echo "Debian Buster Alsa config"
cat <<'EOF' > /etc/modprobe.d/alsa-base.conf
#set index value
options snd-usb-audio index=-2
EOF
else
echo "Debian Stretch Alsa config"
cat <<'EOF' > /etc/modprobe.d/alsa-base.conf
#set index value
options snd_usb_audio index=0
options snd_bcm2835 index=1
#reorder
options snd slots=snd_usb_audio, snd_bcm2835
EOF
fi

echo "Automatically boot to Tarina"
echo "creating a tarina.service file"
cat <<'EOF' > /etc/systemd/system/tarina.service
[Unit]
Description=tarina
After=getty.target
Conflicts=getty@tty1.service
#DefaultDependencies=false

[Service]
Type=simple
RemainAfterExit=yes
ExecStart=/usr/bin/python3 /home/pi/tarina/tarina.py
User=pi
Restart=on-failure
StandardInput=tty-force
StandardOutput=inherit
StandardError=inherit
TTYPath=/dev/tty1
TTYReset=yes
TTYVHangup=yes
Nice=-20
CPUSchedulingPolicy=rr
CPUSchedulingPriority=99

[Install]
WantedBy=local-fs.target
EOF

chmod +x /home/pi/tarina/tarina.py
systemctl enable tarina.service
systemctl daemon-reload
echo "systemd configuration done!"

echo "Installing tarina apache server configuration"
cp extras/tarina.conf /etc/apache2/sites-available/
ln -s -t /var/www/ /home/pi/tarina/srv/
a2dissite 000-default.conf
a2ensite tarina.conf
systemctl reload apache2

echo 'Dont do sync while copying to usb drives, does increase speed alöt!'
sed -i '/MOUNTOPTIONS=/c\MOUNTOPTIONS="noexec,nodev,noatime,nodiratime"' /etc/usbmount/usbmount.conf

echo "Adding harddrive tools..."
cat <<'EOF'
All this hard work to figure out how to keep NTFS mounted was done by F. Untermoser
https://raspberrypi.stackexchange.com/questions/41959/automount-various-usb-stick-file-systems-on-jessie-lite
Thanks alot!

while we are at it :)
To all the amazing FOSS people out there big big props and
  _____  ______  _____ _____  ______ _____ _______ _ 
 |  __ \|  ____|/ ____|  __ \|  ____/ ____|__   __| |
 | |__) | |__  | (___ | |__) | |__ | |       | |  | |
 |  _  /|  __|  \___ \|  ___/|  __|| |       | |  | |
 | | \ \| |____ ____) | |    | |___| |____   | |  |_|
 |_|  \_\______|_____/|_|    |______\_____|  |_|  (_)

EOF
apt-get -y install ntfs-3g exfat-fuse
sed -i -e 's/MountFlags=slave/MountFlags=shared/g' /lib/systemd/system/systemd-udevd.service
sed -i '/FS_MOUNTOPTIONS=/c\FS_MOUNTOPTIONS="-fstype=ntfs-3g,nls=utf8,umask=007,gid=46 -fstype=fuseblk,nls=utf8,umask=007,gid=46 -fstype=vfat,gid=1000,uid=1000,umask=007"' /etc/usbmount/usbmount.conf
sed -i '/FILESYSTEMS=/c\FILESYSTEMS="vfat ext2 ext3 ext4 hfsplus ntfs fuseblk vfat"' /etc/usbmount/usbmount.conf

cat <<'EOF' > /etc/udev/rules.d/usbmount.rules
KERNEL=="sd*", DRIVERS=="sbp2",         ACTION=="add",  PROGRAM="/bin/systemd-escape -p --template=usbmount@.service $env{DEVNAME}", ENV{SYSTEMD_WANTS}+="%c"
KERNEL=="sd*", SUBSYSTEMS=="usb",       ACTION=="add",  PROGRAM="/bin/systemd-escape -p --template=usbmount@.service $env{DEVNAME}", ENV{SYSTEMD_WANTS}+="%c"
KERNEL=="ub*", SUBSYSTEMS=="usb",       ACTION=="add",  PROGRAM="/bin/systemd-escape -p --template=usbmount@.service $env{DEVNAME}", ENV{SYSTEMD_WANTS}+="%c"
KERNEL=="sd*",                          ACTION=="remove",       RUN+="/usr/share/usbmount/usbmount remove"
KERNEL=="ub*",                          ACTION=="remove",       RUN+="/usr/share/usbmount/usbmount remove"
EOF

cat <<'EOF' > /etc/systemd/system/usbmount@.service
[Unit]
BindTo=%i.device
After=%i.device

[Service]
Type=oneshot
TimeoutStartSec=0
Environment=DEVNAME=%I
ExecStart=/usr/share/usbmount/usbmount add
RemainAfterExit=yes
EOF

echo "Adding hacking tools..."
apt-get -y install vim htop screen nmap
cp extras/.vimrc /root/.vimrc
cp extras/.vimrc /home/pi/.vimrc

echo "Installing youtube upload mod..."
cd mods
./install-youtube-upload.sh
cd ..

echo "Setting up network configuration to use wicd program..."
echo "it works nicer from the terminal than raspberry pi default"
apt-get -y purge dhcpcd5 plymouth
apt-get -y install wicd wicd-curses

echo "Removing unnecessary programs from startup..."
systemctl disable lightdm.service --force
systemctl disable graphical.target --force
systemctl disable plymouth.service --force
systemctl disable bluetooth.service 
systemctl disable hciuart.service 

echo "Configure wifi region settings to FI, finland"
echo "You can change settings in extras/wifiset.sh file"
cp extras/wifiset.service /etc/systemd/system/
systemctl daemon-reload
systemctl enable wifiset.service

echo "HURRAY! WE ARE"
cat <<'EOF'
  _____   ____  _   _ ______ _ 
 |  __ \ / __ \| \ | |  ____| |
 | |  | | |  | |  \| | |__  | |
 | |  | | |  | | . ` |  __| | |
 | |__| | |__| | |\  | |____|_|
 |_____/ \____/|_| \_|______(_)
                               
EOF
sleep 2
echo "Rebooting into up-to-date Tarina..."
sleep 2
reboot
