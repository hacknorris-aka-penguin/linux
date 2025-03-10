#!/usr/bin/env bash 
# SPDX-License-Identifier: GPL-2.0
#
# Check if atomic headers are up-to-date

ATOMICDIR=$(dirname $0)
ATOMICTBL=${ATOMICDIR}/atomics.tbl
LINUXDIR=${ATOMICDIR}/../..

echo '' | sha1sum - > /dev/null 2>&1
if [ $? -ne 0 ]; then
	printf "sha1sum not available, skipping atomic header checks.\n"
	exit 0
fi

cat <<EOF |
linux/atomic/atomic-instrumented.h
linux/atomic/atomic-long.h
linux/atomic/atomic-arch-fallback.h
EOF
while read header; do
	OLDSUM="$(tail -n 1 ${LINUXDIR}/include/${header})"
	OLDSUM="${OLDSUM#// }"

	NEWSUM="$(sed '$d' ${LINUXDIR}/include/${header} | sha1sum)"
	NEWSUM="${NEWSUM%% *}"

	if [ "${OLDSUM}" != "${NEWSUM}" ]; then
		printf "warning: generated include/${header} has been modified.\n"
	fi
done

exit 0
