#!/usr/bin/env sh

set -e
set -x

http_proxy=${APTCACHER} DEBIAN_FRONTEND=noninteractive apt-get update
http_proxy=${APTCACHER} DEBIAN_FRONTEND=noninteractive apt-get install tzdata ca-certificates jq sysbench git rsync --no-install-recommends -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold"
sysbench cpu run
sysbench memory run
http_proxy=${APTCACHER} DEBIAN_FRONTEND=noninteractive apt-get install uidmap containers-storage fuse-overlayfs fuse3 iptables netavark aardvark-dns buildah podman skopeo --no-install-recommends -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold"
cp -f /usr/share/containers/storage.conf /etc/containers/storage.conf
sed -i -e 's|^#mount_program|mount_program|g' /etc/containers/storage.conf
sed -i -e 's|^driver = ""|driver = "overlay2"|g' /etc/containers/storage.conf
cat /etc/containers/storage.conf
buildah -v
podman -v
skopeo -v
http_proxy=${APTCACHER} DEBIAN_FRONTEND=noninteractive apt-get install git --no-install-recommends -y -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold"
