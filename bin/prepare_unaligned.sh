#!/bin/bash

donor=$1
type=$2

base_dir=$(dirname $(dirname $(readlink -f bin/get_gnos_donor.sh)))
resource_dir="$base_dir/resources/"
data_dir="$base_dir/data/$donor/"
tmp_dir="$base_dir/tmp/$donor"
orig_header_file="$tmp_dir/${type}_header.sam"
new_header_file="$tmp_dir/new_header.sam"
aligned_bam="$data_dir/$type.bam"
tmp_unaligned="$tmp_dir/$type/unaligned/"
picard="$base_dir/lib/picard/picard.jar"

mkdir -p $tmp_unaligned

if [ $type = "normal" ]
then
	specimen_type="Normal"
elif [ $type = "tumor" ]
then
	specimen_type="Primary tumour - solid tissue"
else
	echo "Please define type of bam: normal/tumor"
fi

java -Xmx32G -jar $picard RevertSam \
		I=$aligned_bam \
		O=$tmp_unaligned \
		OUTPUT_BY_READGROUP=true \
		OUTPUT_BY_READGROUP_FILE_FORMAT=bam \
		ATTRIBUTE_TO_CLEAR=XS \
		SORT_ORDER=queryname \
		RESTORE_ORIGINAL_QUALITIES=true \
		REMOVE_DUPLICATE_INFORMATION=true \
		REMOVE_ALIGNMENT_INFORMATION=true \
		TMP_DIR=$tmp_dir

java -Xmx32G -jar $picard ViewSam INPUT=$aligned_bam HEADER_ONLY=true | sed -e '$a\' > $orig_header_file

while read -r line
do
	RG=$(echo "$line" | cut -f 2 | sed -r 's/^ID://g')
	# order_processed=$(grep "bwa mem" $orig_header_file | grep -n "${RG}" | cut -f 1 -d ":")

	cat > $new_header_file <<-EOF
	@HD	VN:1.4
	${line}
	@CO	dcc_project_code:DOCKER-TEST
	@CO	submitter_donor_id:${1}
	@CO	submitter_specimen_id:${1}.specimen
	@CO	submitter_sample_id:${1}.sample
	@CO	dcc_specimen_type:${specimen_type}
	@CO	use_cntl:85098796-a2c1-11e3-a743-6c6c38d06053
	EOF

	java -Xmx32G -jar $picard ReplaceSamHeader \
		I=${tmp_unaligned}${RG}.bam \
		HEADER=$new_header_file \
		O=${data_dir}${RG}.bam
		# O=${data_dir}${type}.unaligned.$(printf "%03d" $order_processed).bam

	rm ${tmp_unaligned}${RG}.bam
done < <( grep "^@RG" $orig_header_file )
