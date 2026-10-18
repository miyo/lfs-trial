
```
sudo -s

export LFS=/mnt/lfs
export LFS_TARGET_DISK=<disk>

bash 02-preparing.sh 
bash chown-dirs.sh <username>
```

```
- 05-build-toolchain.sh
- 06-cross-compile-tools.sh
```

```
sudo -s
export LFS=/mnt/lfs
bash chown-dirs.sh root
mkdir -pv $LFS/scripts
cp *.sh $LFS/scripts/
bash chroot.sh
```

```
bash /scripts/07-chroot-setting.sh
exec bash
```

Creating backup (Optional):

```
exit # exit from chroot environment
export LFS=/mnt/lfs
export LFS_TARGET_DISK=<disk>
bash 07-backup-and-remount.sh
bash chroot.sh
```

```
bash restore-backup.sh /dev/sdb <backupfile>
```

```
bash 08-build-lfs-system.sh
```
