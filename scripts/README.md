# Building LFS with Scripts

## Prapare the Build Environment

Run the following commands as root:

```
sudo -s

export LFS=/mnt/lfs
export LFS_TARGET_DISK=<disk>

bash 02-preparing.sh 
bash chown-dirs.sh <username>

exit
```

## Build the Toolchain

Run the following scripts as a regular user:

```
- 05-build-toolchain.sh
- 06-cross-compile-tools.sh
```

## Set Up the LFS Chroot Environment

Run the following commands as root:

```
sudo -s
export LFS=/mnt/lfs
bash chown-dirs.sh root
mkdir -pv $LFS/scripts
cp *.sh $LFS/scripts/
bash chroot.sh
bash /scripts/07-chroot-setting.sh
exec bash
```

## Create a Backup (Optional)

```
exit # exit from chroot environment
export LFS=/mnt/lfs
export LFS_TARGET_DISK=<disk>
bash 07-backup-and-remount.sh
bash chroot.sh # back into chroot environment
```

To restore from the backup, run:

```
bash restore-backup.sh /dev/sdb <backupfile>
```

## Build the Base LFS System

Run the following commands inside the chroot environment:

```
bash /scripts/08-build-lfs-system.sh
passwd root
bash /scripts/09-system-config.sh 
bash /scripts/10-lfs-system-bootable.sh
bash /scripts/20-install-openssh.sh # additional
```

## Set Up the Standalone LFS System

After booting into the standalone LFS system, run:

```
bash /scripts/20-optional-apps.sh
bash /scripts/21-install-pkgsrc.sh
```


