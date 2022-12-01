#!/bin/bash

logfile='/var/log/yt/download.log'
if [[ ! -f ${logfile} ]]; then
  exit 0
fi
dir='/srv/yt/downloads'
if [[ ! -d ${dir} ]]; then
  exit 0
fi
youtube-dl --get-title $1 > /tmp/title
youtube-dl --get-filename $1 | cut -d'.' -f2 > /tmp/ext
title="$(cat /tmp/title)"
filename="${title}.$(cat /tmp/ext)"
mkdir /srv/yt/downloads/"${title}"
youtube-dl -o /srv/yt/downloads/"${title}"/'%(title)s.%(ext)s' $1 > /dev/null
youtube-dl --get-description $1 > /srv/yt/downloads/"${title}"/description
echo "Video $1 was downloaded."
echo File path : /srv/yt/downloads/"${title}"/"${filename}"
echo [$(date "+%D %T")] Video $1 was downloaded. File path : /srv/yt/downloads/"${title}"/"${filename}" >> ${logfile}
