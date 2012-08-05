#!/bin/sh

TOC="FindIt/FindIt.toc"
VERSIONTAG="## Version: "
VERSION=$(grep "$VERSIONTAG" $TOC | sed "s/$VERSIONTAG//")
OUTFILE="findit-$VERSION.zip"

git archive --format=zip origin FindIt/ > $OUTFILE &&
echo $OUTFILE
