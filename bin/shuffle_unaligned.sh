#!/bin/bash

base_dir=$(dirname $(dirname $(readlink -f bin/get_gnos_donor.sh)))
unaligned_dir="$base_dir/data/unaligned_bams"
shuffled_dir="$unaligned_dir/shuffled"

mkdir -p $shuffled_dir

for bamfile in $(ls $unaligned_dir/CPCG_0098_Ly_R_PE_517*)
do
	echo "shuffling $bamfile"
	samtools collate -uOn 128 $bamfile tmp > $shuffled_dir/$(basename $bamfile)
done
