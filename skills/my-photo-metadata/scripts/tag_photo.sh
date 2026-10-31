#!/usr/bin/env bash
# Write Title, Description and Keywords (plus author/license/credit) into photos.
# Usage: [ALT_TEXT=.. CITY=.. STATE=.. COUNTRY=.. COUNTRY_CODE=.. SUBLOCATION=..] \
#   tag_photo.sh "<title>" "<description>" "<kw1, kw2, ...>" FILE...
# Location env vars are optional; unset ones are left untouched.
set -euo pipefail

if [[ $# -lt 4 ]]; then
  echo "Usage: $0 \"<title>\" \"<description>\" \"<kw1, kw2>\" FILE..." >&2
  exit 1
fi

TITLE="$1"
DESCRIPTION="$2"
SUBJECT_KEYWORDS="$3"
shift 3

LICENSE_LINK="https://creativecommons.org/licenses/by-sa/4.0/"
AUTHOR_NAME="Petr Ruzicka"
AUTHOR_EMAIL="petr.ruzicka@gmail.com"
AUTHOR="${AUTHOR_NAME} <${AUTHOR_EMAIL}>"
AUTHOR_URL="https://petr.ruzicka.dev"
RIGHTS="This work is licensed to the public under the Creative Commons Attribution-ShareAlike (CC BY-SA) license ${LICENSE_LINK}"

LOCATION_ARGS=()
[[ -n "${CITY:-}" ]] && LOCATION_ARGS+=(-IPTC:City="${CITY}" -XMP-photoshop:City="${CITY}")
[[ -n "${STATE:-}" ]] && LOCATION_ARGS+=(-IPTC:Province-State="${STATE}" -XMP-photoshop:State="${STATE}")
[[ -n "${COUNTRY:-}" ]] && LOCATION_ARGS+=(-IPTC:Country-PrimaryLocationName="${COUNTRY}" -XMP-photoshop:Country="${COUNTRY}")
[[ -n "${COUNTRY_CODE:-}" ]] && LOCATION_ARGS+=(-IPTC:Country-PrimaryLocationCode="${COUNTRY_CODE}" -XMP-iptcCore:CountryCode="${COUNTRY_CODE}")
[[ -n "${ALT_TEXT:-}" ]] && LOCATION_ARGS+=(-XMP-iptcCore:AltTextAccessibility="${ALT_TEXT}")
[[ -n "${SUBLOCATION:-}" ]] && LOCATION_ARGS+=(-IPTC:Sub-location="${SUBLOCATION}" -XMP-iptcCore:Location="${SUBLOCATION}")

# -sep splits the keyword string into separate list items (XMP:Subject, IPTC:Keywords)
# CodedCharacterSet=UTF8 keeps diacritics intact in IPTC fields
exiftool -progress -overwrite_original -sep ", " "-filemodifydate<datetimeoriginal#" \
  -IPTC:CodedCharacterSet=UTF8 \
  -Artist="${AUTHOR}" -Copyright="${RIGHTS}" -CopyrightNotice="${AUTHOR}; ${LICENSE_LINK}" -rights="${RIGHTS}" \
  -Title="${TITLE}" -ImageDescription="${DESCRIPTION}" -ObjectName="${TITLE}" -Headline="${TITLE}" \
  -Description="${DESCRIPTION}" -UserComment="${DESCRIPTION}" -Caption-Abstract="${DESCRIPTION}" \
  -IPTC:By-line="${AUTHOR_NAME}" -IPTC:By-lineTitle="Photographer" \
  -IPTC:Credit="${AUTHOR_NAME}" -XMP-photoshop:Credit="${AUTHOR_NAME}" \
  -XMP-dc:Creator="${AUTHOR}" -XMP-xmpRights:Marked="True" -XMP-dc:Rights="${RIGHTS}" -xmp:UsageTerms="${RIGHTS}" \
  -XMP-xmpRights:WebStatement="${LICENSE_LINK}" \
  -XMP-iptcCore:CreatorWorkURL="${AUTHOR_URL}" -XMP-iptcCore:CreatorWorkEmail="${AUTHOR_EMAIL}" \
  -XMP-plus:LicensorName="${AUTHOR_NAME}" -XMP-plus:LicensorURL="${AUTHOR_URL}" \
  -XMP-cc:AttributionName="${AUTHOR}" -XMP-cc:License="${LICENSE_LINK}" -XMP-cc:AttributionURL="${AUTHOR_URL}" \
  -XMP:Description="${DESCRIPTION}" -XMP:Subject="${SUBJECT_KEYWORDS}" -XMP:Title="${TITLE}" \
  -XMP-xmp:Keywords="${SUBJECT_KEYWORDS}" -IPTC:Keywords="${SUBJECT_KEYWORDS}" \
  -XMP-exif:UserComment="${DESCRIPTION}" \
  -XMP-iptcExt:DigitalSourceType="http://cv.iptc.org/newscodes/digitalsourcetype/digitalCapture" \
  ${LOCATION_ARGS[@]+"${LOCATION_ARGS[@]}"} \
  "$@"

exiftool -s -Title -Description -Subject -IPTC:Keywords -Credit -WebStatement -LicensorURL \
  -AltTextAccessibility -DigitalSourceType -City -State -Country -CountryCode -Sub-location -GPSPosition "$@"
