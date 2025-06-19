#!/usr/bin/env bash

# A set of small tools that I find useful when working on HPC clusters, made
# accessible by subcommande like 'pinfo'

set -e

#
# === Help/usage ===
#

help() {
cat << EOF
usage: eagle-tools.sh [-h] SUBCOMMAND ...

Subcommands:
pinfo		Get information about available partitions (name, nodes, cpus,
		memory/node). Takes no arguments.

cbf		"Compare Big File", computes a md5sum of N initial lines
		(default is 1000, can be specified by -s N). Run with -h for
		help. Gzipped files MUST be passed with -g option

sampler		Used to generate smaller versions from large fasta/fastq files
		for pipeline testing. [under construction, can't be invoked yet]

sfa		"Split FASTA", splits a multi header fasta into separate files.
		Might be useful for disassembling genomes into chromosomes. Use
		-g for gzipped files

eln		"Executable ln", creates a link to specified file in my \$PATH

ttmd		"table to Markdown", takes a table with arbitrary separator
		(specified by -s if other than whitespace) and outputs a
		Markdown formated table. First row is treated as header.
EOF
}

#
# === Subcommand functions ===
#

pinfo() {
	#
	# Partition info
	# Print info about accessible partitions as a nice table
	#
	sinfo -o "%P %D %c %m" | \
		awk '{printf("%-16s\t%5s\t%10s\t%12s\n", $1, $2, $3, $4)}'
}

cbf() {
	#
	# Compare Big File
	# prints md5sum of head -n N lines from files. Used to get an idea if
	# two or more files are likely identical
	#
	cbf_help() {
cat << EOF
usage: eagle-tools.sh cbf [-s SIZE] [-g] FILE

-s	Size (number of lines) that are fed into md5sum. Default is
	1000.

-g	Use for gzipped files to feed the text content into md5sum.
EOF
	}

	size=1000; g_zip=0

	while getopts 's:gh' opt; do
		case $opt in
			s) size=${OPTARG} ;;
			g) g_zip=1 ;;
			h) cbf_help >&2; exit 0 ;;
			*) echo 'Something is not right...' >&2; exit 1 ;;
		esac
	done

	# handle 0 arguments scenario
	[[ ! $opt_provided ]] && cbf_help; exit 1

	shift $((OPTIND - 1)); name=$(basename $1)

	[[ g_zip -eq 1 ]] && \
		md5sum <(zcat $1 | head -n $size) | \
		awk -v name=$name '{printf("%s\t%s\n", $1, name)}' \
		|| \
		md5sum <(head -n $size $1) | \
		awk -v name=$name '{printf("%s\t%s\n", $1, name)}'
}
sampler() {
	#
	# Sample reads from fasta/fastq
	# prints md5sum of head -n N lines from files. Used to get an idea if
	# two or more files are likely identical
	#
	sampler_help() {
cat << EOF
usage: eagle-tools.sh sampler [-s SIZE] [-g] FILE

-s	Size (number of lines) that are coppied. Default is 1000.

-g	Use for gzipped files to feed the text content into md5sum.
EOF
	}

	size=1000; g_zip=0

	while getopts 's:gh' opt; do
		case $opt in
			s) size=${OPTARG} ;;
			g) g_zip=1 ;;
			h) sampler_help >&2; exit 0 ;;
			*) echo 'Something is not right...' >&2; exit 1 ;;
		esac
	done
}
sfa() {
	#
	# Splits a multi header fasta into separate files.
	#
	g_zip=0
	while getopts 'g' opt; do
		case $opt in
			g) g_zip=1 ;;
			*) echo 'Something is not right...' >&2; exit 1 ;;
		esac
	done

	shift $((OPTIND - 1))

	[[ $g_zip -eq 1 ]] && \
		csplit -f chr <(zcat $1) '/^>/' '{*}' || \
		csplit -f chr $1 '/^>/' '{*}'
}
eln() {
	eln_help() {
cat << EOF
usage: eagle-tools.sh eln [-p PATH] [-n NAME] FILE

-p	Symlink destination, default is set in DEFAULT_PATH variable.

-n	Name of the link, default is the executable name
EOF
	}
	DEFAULT_PATH="$HOME/pl0217-01/project_data/4_MHryc/software/bin/"
	path=$DEFAULT_PATH

	while getopts 'p:n:h' opt; do
		case $opt in
			p) path=${OPTARG} ;;
			n) name=${OPTARG} ;;
			h) eln_help; exit 0 ;;
			*) echo 'Something is not right...' >&2; exit 1 ;;
		esac
	done

	# exit if no arguments provided
	#[[ ! $opt_provided ]] && eln_help; exit 1

	shift $((OPTIND - 1))

	# add x permission just in case
	chmod +x $1
	[[ -z $name ]] && \
		ln -s $(pwd)/$1 ${path}$1 || \
		ln -s $(pwd)/$1 ${path}${name}
}
ttmd() {
	SEP='\t'
	while getopts 's:' opt; do
		case $opt in
			s) SEP="$OPTARG" ;;
			*) echo 'Something is not right...' >&2; exit 1 ;;
		esac
	done

	shift $((OPTIND - 1))

	awk -F "${SEP}" -v SEP="${SEP}" '
	function format() {
		split($0, arr, SEP, seps); 
		for (i = 1; i <= NF; i++) {
			printf("| %s ", arr[i])
		}
		printf("|\n")
	};
	function make_line() {
		for (i = 1; i <= NF; i++) {
			printf("%s", "| --- ")
		}
		printf("%s", "|\n")
	}; FNR == 1 {
		format();
		make_line()
	}; FNR != 1 {format()}' $1
}

#
# === Evaluate subcommands ===
# 

subcmd=$1

case $subcmd in
	pinfo) shift; pinfo ;;

	cbf) shift; cbf $@ ;;

	sfa) shift; sfa $@ ;;

	eln) shift; eln $@ ;;

	ttmd) shift; ttmd $@ ;;

	*) help >&2; exit 1 ;;
esac
