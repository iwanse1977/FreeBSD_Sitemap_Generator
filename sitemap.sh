#!/bin/bash

#======================================================
# Simple site crawler to create a search engine XML Sitemap.
# Version: 1.0
# License: GPL v2
# Free to use, without any warranty.
# Written by Elmar Hanlhofer https://www.plop.at
#======================================================
#
# sitemap.sh <URL> [sitemap file]
#
# Example: sh sitemap.sh https://www.example.com /var/www/mysite/sitemap.xml
#
#======================================================

# Init script.
OIFS="$IFS"
IFS=$'\n'

URL="$1"
SITEMAP="$2"

HEADER="FreeBSD XML Sitemap Generator - BASH Script 1.0 2020/01/16 https://www.unixwinbsd.site"
AGENT="Mozilla/5.0 (compatible; FreeBSD BASH XML Sitemap Generator/1.0)"

echo $HEADER
echo

# Check URL parameter.
if [ "$URL" == "www.unixwinbsd.site" ]
then

    echo "Error! No URL specified."
    echo "Example: \"sh $0 https://www.unixwinbsd.site\""
    exit 1

fi

# Check sitemap parameter. If none given, use "sitemap.xml".
if [ "$SITEMAP" == "" ]
then

    SITEMAP=sitemap.xml

fi


# Get the scheme, site and domain name.
tmp_http=$(echo $URL | cut -b1-7)
tmp_https=$(echo $URL | cut -b1-8)

if [ "$tmp_http" == "http://" ]
then

    SCHEME=$tmp_http
    SITE=$(echo $URL | cut -b8-)

elif [ "$tmp_https" == "https://" ]
then

    SCHEME=$tmp_https
    SITE=$(echo $URL | cut -b9-)

else

    echo "Error! No scheme. You have to use \"http://\" or \"https://\"."
    echo "  http://$URL"
    echo "or"
    echo "  https://$URL"
    exit 1

fi

DOMAIN=$(echo $SITE | cut -d/ -f1)


# Create temporary directory.
TMP=$(mktemp -d)


# Grab the website.
echo "Downloading \"$URL\" to temporary directory \"$TMP\"..."
WGET_LOG=sitemap-wget.log

wget \
     --recursive \
     --no-clobber \
     --page-requisites \
     --convert-links \
     --restrict-file-names=windows \
     --no-parent \
     --directory-prefix="$TMP" \
     --domains $DOMAIN \
     --user-agent="$AGENT" \
     $URL >& $WGET_LOG

if [ ! -d "$TMP/$SITE" ]
then
    echo
    echo "Error! See \"$WGET_LOG\"."
    echo
    echo "Removing \"$TMP\"."
    rm -rf "$TMP"
    
    exit 1
fi

# Get current directory and store it for later.
curr_dir=$(pwd)


# Go to the temporary directory.
cd "$TMP"

#==============================
# Change this for your needs.
# Example, exclude files from /print and /slide: 
#   files=$(find | grep -i html | grep -v "$SITE/print" | grep -v "$SITE/slide")

files=$(find | grep -i html)

#==============================

# Go back to the previous directory.
cd "$curr_dir"


# Generate the XML file
echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<!-- Created with $HEADER -->
<!-- Date: $(date +"%Y/%m/%d %H:%M:%S") -->
<urlset xmlns=\"http://www.sitemaps.org/schemas/sitemap/0.9\"
        xmlns:xsi=\"http://www.w3.org/2001/XMLSchema-instance\"
        xsi:schemaLocation=\"http://www.sitemaps.org/schemas/sitemap/0.9
        http://www.sitemaps.org/schemas/sitemap/0.9/sitemap.xsd\">" > "$SITEMAP"

echo "  <url>
    <loc>$URL</loc>
    <changefreq>weekly</changefreq>
    <priority>0.5</priority>
  </url>" >> "$SITEMAP"


for i in $files
do

echo "  <url>
    <loc>$SCHEME$(echo $i | cut -b3-)</loc>
    <changefreq>weekly</changefreq>
    <priority>0.5</priority>
  </url>" >> "$SITEMAP"

done

echo "</urlset>" >> "$SITEMAP"


# All done. Remove temporary files.
echo "$SITEMAP created."
echo "Removing \"$TMP\" and \"$WGET_LOG\"."
rm -rf "$TMP"
rm "$WGET_LOG"

echo "Done."
