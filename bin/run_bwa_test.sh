#!/bin/bash

donor=$1
type=$2

workflow="BWA-Mem"
base_dir=$(dirname $(dirname $(readlink -f bin/get_gnos_donor.sh)))
resource_dir="$base_dir/resources/"
data_dir="$base_dir/data/$donor/"

unaligned_dir="$base_dir/data/unaligned_bams"
orig_bam="$data_dir/${type}.bam"

directory="$base_dir/tests/$workflow/$donor/$type"
output_dir="$directory/output/"

picard="$base_dir/lib/picard/picard.jar"

orig_header_file="$data_dir/${type}_header.sam"
# java -Xmx32G -jar $picard ViewSam INPUT=$orig_bam HEADER_ONLY=true | sed -e '$a\' > $orig_header_file

unaligned_json=""
for id in $(cat $orig_header_file | grep "^@PG" | grep "bwa mem" | tr '\t' '\n' | grep "^CL" | tr '\\t' '\n' | grep "^PU" | cut -f 3 -d ":")
do
	echo $id
	file=$(find $unaligned_dir -name "*$id*")
	echo $file

	unaligned_single=$(cat <<-EOF
	{\\n  "path":"${file}",\\n  "class":"File"\\n  },\\n
	EOF
	)
	unaligned_json="${unaligned_json}${unaligned_single}"
done
unaligned_json=${unaligned_json%,\\n}

mkdir -p "$directory"
mkdir -p "$output_dir"

cat $base_dir/etc/$workflow.json.template | sed "s#\\[CONSENSUS-VCF\\]#$consensus_vcf#g;s#\\[DELLY-DIR\\]#$delly_dir#g;s#\\[RESOURCE-DIR\\]#$resource_dir#g;s#\\[OUTPUT-DIR\\]#$output_dir#g;s#\\[DONOR\\]#$donor#g;s#\\[TUMOR-BAM\\]#$tumor_bam#g;s#\\[NORMAL-BAM\\]#$normal_bam#g;s#\\[TYPE\\]#$type#g;s#\\[UNALIGNED\\]#$unaligned_json#g" > $directory/Dockstore.json

cwl="$(grep $workflow "$base_dir/etc/workflows" | cut -f 2)"

echo "Running BWA-Mem for $donor $type:"
echo "cd $directory && dockstore tool launch --script --entry "$cwl"  --json Dockstore.json"
(cd "$directory" && dockstore tool launch --script --entry $cwl --json Dockstore.json)
