
```
sudo -s

export LFS=/mnt/lfs
export LFS_TARGET_DISK=/mnt/lfs

bash 02-preparing.sh /dev/sdb
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
bash umount-all.sh
mount /dev
cd $LFS
tar -cJpf $HOME/lfs-temp-tools-13.1-systemd.tar.xz .
bash mount-all.sh
bash chroot.sh
```
