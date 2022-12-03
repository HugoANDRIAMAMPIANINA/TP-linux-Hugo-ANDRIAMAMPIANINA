#!/bin/bash 

logfile='/var/log/yt/download.log'
if [[ ! -f ${logfile} ]]; then
  exit 0
fi
dir='/srv/yt/downloads'
if [[ ! -d ${dir} ]]; then
  exit 0
fi
while true
do
  if [[ -s /srv/yt/url_list ]]
  then
    urls=$(cat /srv/yt/url_list)
    while read -r line
    do
      youtube-dl --get-title ${line} > /tmp/title
      youtube-dl --get-filename ${line} | cut -d'.' -f2 > /tmp/ext
      title="$(cat /tmp/title)"
      filename="${title}.$(cat /tmp/ext)"
      mkdir /srv/yt/downloads/"${title}"
      youtube-dl -o /srv/yt/downloads/"${title}"/'%(title)s.%(ext)s' ${line} > /dev/null
      youtube-dl --get-description ${line} > /srv/yt/downloads/"${title}"/description
      echo "Video ${line} was downloaded."
      echo File path : /srv/yt/downloads/"${title}"/"${filename}"
      cat /dev/null > /tmp/title
      cat /dev/null > /tmp/ext
    done <<< $urls
    cat /dev/null > /srv/yt/url_list
  else
    sleep 5
  fi
done
