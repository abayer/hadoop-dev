#!/usr/bin/env bash

#
# Create n software raid volumes from loopback mounted images,
# create a file system on each and mount them.
#
function create_mounts () {
    local count=$(($1-1))
    for i in $(seq 0 $count); do
        echo Create image $i    
        j=$((i/2))
        # XX Fix MR specific
        dir=/faulty/dir-s${j}/mapred/local$((i%2+1))
        img=flty-image$i
        md=/dev/md$i
        dd if=/dev/zero of=$img bs=1M count=1000
        sudo losetup -f $img
        sudo mdadm --create $md --level=faulty --raid-devices=1 /dev/loop$i
        sudo mkfs.ext3 $md
        sudo rm -rf $dir
        sudo mkdir -p $dir
        sudo mount $md $dir
        #sudo chown eli:eli -R /faulty
        sudo chown -R mapred:hadoop $dir
    done
}


function list_mounts () {
    sudo losetup -a
    #sudo mdadm -E -s
    ls /dev/md*
}


function remove_mounts () {
    local count=$(($1-1))
    for i in $(seq 0 $count); do
        sudo umount /faulty/dir$i
        sudo mdadm --remove /dev/md$i
        sudo losetup -d /dev/loop$i
    done
}

# Make the given volumen faulty. E.g.
# wt{n} transient write failures (after n writes) 
# rt{n} transient read failures
# rp{n} persistent (for particular access) read failures 
function fail_vol () {
    local index=$1
    local mode=$2
    sudo mdadm --grow /dev/md$index -l faulty -p $mode
}

function fail_all_vols () {
    local count=$(($1-1))
    local mode=$2
    for i in $(seq 0 $count); do
        fail_vol $i $mode
    done
}

# Clear all active volume failures
function clear_failures () {
    local count=$(($1-1))
    for i in $(seq 0 $count); do
        sudo mdadm --grow /dev/md$i -l faulty -p clear
        sudo mdadm --grow /dev/md$i -l faulty -p flush
    done
}


#create_mounts 4
# fail_vol 0 wt3
# fail_all_vols 4 rt3
#clear_failures 4
#remove_mounts 4

list_mounts

