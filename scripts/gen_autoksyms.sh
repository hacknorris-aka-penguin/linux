#!/usr/bin/env bash 
# SPDX-License-Identifier: GPL-2.0-only

# Create an autoksyms.h header file from the list of all module's needed symbols
# as recorded on the second line of *.mod files and the user-provided symbol
# whitelist.

set -e

output_file="$1"

# Use "make V=1" to debug this script.
case "$KBUILD_VERBOSE" in
*1*)
	set -x
	;;
esac

needed_symbols=

# Special case for modversions (see modpost.c)
if grep -q "^CONFIG_MODVERSIONS=y$" include/config/auto.conf; then
	needed_symbols="$needed_symbols module_layout"
fi

ksym_wl=$(sed -n 's/^CONFIG_UNUSED_KSYMS_WHITELIST=\(.*\)$/\1/p' include/config/auto.conf)
if [ -n "$ksym_wl" ]; then
	[ "${ksym_wl}" != "${ksym_wl#/}" ] || ksym_wl="$abs_srctree/$ksym_wl"
	if [ ! -f "$ksym_wl" ] || [ ! -r "$ksym_wl" ]; then
		echo "ERROR: '$ksym_wl' whitelist file not found" >&2
		exit 1
	fi
fi

# Generate a new ksym list file with symbols needed by the current
# set of modules.
cat > "$output_file" << EOT
/*
 * Automatically generated file; DO NOT EDIT.
 */

EOT

[ -f modules.order ] && modlist=modules.order || modlist=/dev/null

{
	sed 's/ko$/mod/' $modlist | xargs -n1 sed -n -e '2p'
	echo "$needed_symbols"
	[ -n "$ksym_wl" ] && cat "$ksym_wl"
} | sed -e 's/ /\n/g' | sed -n -e '/^$/!p' |
# Remove the dot prefix for ppc64; symbol names with a dot (.) hold entry
# point addresses.
sed -e 's/^\.//' |
sort -u |
sed -e 's/\(.*\)/#define __KSYM_\1 1/' >> "$output_file"
