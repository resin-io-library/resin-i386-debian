#!/bin/bash

set -o errexit

SUITES='wheezy jessie'
MIRROR='http://ftp.uk.debian.org/debian/'
REPO='resin/i386-debian'
LATEST='jessie'

for suite in $SUITES; do
	dir=$(mktemp --tmpdir=/var/tmp -d)
	date=$(date +'%F')
	
	./mkimage.sh -t $REPO:$suite --dir=$dir debootstrap --variant=minbase --arch=i386 --include=sudo $suite $MIRROR
	rm -rf $dir

	docker run --rm $REPO:$suite bash -c 'dpkg-query -l' > $suite
	cp $suite $suite_$date

	# Upload to S3 (using AWS CLI)
	printf "$ACCESS_KEY\n$SECRET_KEY\n$REGION_NAME\n\n" | aws configure
	aws s3 cp $suite s3://$BUCKET_NAME/image_info/i386-debian/$suite/
	aws s3 cp $suite_$date s3://$BUCKET_NAME/image_info/i386-debian/$suite/
	rm -f $suite $suite_$date
	
	docker tag -f $REPO:$suite $REPO:$suite-$date
	if [ $LATEST == $suite ]; then
		docker tag -f $REPO:$suite $REPO:latest
	fi
done
