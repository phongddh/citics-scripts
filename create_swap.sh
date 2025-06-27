#!/bin/bash

set -e

# Lay dung luong RAM vat ly (don vi MB)
ram_kb=$(grep MemTotal /proc/meminfo | awk '{print $2}')
ram_mb=$((ram_kb / 1024))

# Tinh kich thuoc swap (don vi MB) dua tren RAM
if [ "$ram_mb" -le 2048 ]; then
    swap_mb=$((ram_mb * 2))
elif [ "$ram_mb" -le 8192 ]; then
    swap_mb=$ram_mb
else
    swap_mb=$((ram_mb / 2))
fi

swap_file="/swapfile"

echo "RAM hien tai: ${ram_mb}MB"
echo "Kich thuoc swap se tao: ${swap_mb}MB"

# Kiem tra neu swap da ton tai
if swapon --show | grep -q "$swap_file"; then
    echo "Swap da ton tai tai $swap_file. Dung tao moi."
    exit 0
fi

# Tao file swap
sudo fallocate -l "${swap_mb}M" $swap_file || sudo dd if=/dev/zero of=$swap_file bs=1M count=$swap_mb

# Thiet lap quyen
sudo chmod 600 $swap_file

# Thiet lap swap
sudo mkswap $swap_file
sudo swapon $swap_file

# Them vao /etc/fstab neu chua co
if ! grep -q "$swap_file" /etc/fstab; then
    echo "$swap_file none swap sw 0 0" | sudo tee -a /etc/fstab
fi

# Thiet lap vm.swappiness va vm.vfs_cache_pressure
sudo sysctl vm.swappiness=10
sudo sysctl vm.vfs_cache_pressure=50

echo "Da tao swap thanh cong voi kich thuoc ${swap_mb}MB"
