---
name: my-photo-metadata
description: >-
  Propose a Title, Description, Keywords, alt text and location for a photo
  (RAW like ARW/NEF/ORF/DNG, JPEG, AVIF, HEIC, ...) optimized for uploading
  to Flickr, 500px, Pixabay, Unsplash, Google Images and social networks, by
  looking at the image, using hints from its metadata (GPS location, date,
  existing tags) and web lookups. Show the photo to the user, get approval,
  then write them with exiftool together with author/credit/CC BY-SA license
  tags, keeping all existing EXIF and GPS data, and print a ready-to-paste
  social caption with hashtags. Use whenever the user wants to tag, caption,
  describe, title, add keywords to or prepare photos/pictures for upload, even if they
  just say "describe this photo" or "add metadata to these pics".
license: Apache-2.0
---

# Photo metadata

Goal: accurate, user-approved metadata written into the photo file(s) so
that photo sites and search engines pick it up automatically on upload.

## 1. Read existing metadata

```bash
exiftool -s -G1 -Title -Description -Subject -Keywords -DateTimeOriginal \
  -Make -Model -LensModel -GPSPosition -GPSAltitude -City -Country "${FILE}"
```

Existing Title/Description/Keywords are a starting point - keep what is
correct. GPS coordinates are the best location hint: reverse-geocode them
(web search / fetch e.g.
`https://nominatim.openstreetmap.org/reverse?format=json&lat=LAT&lon=LON`)
to get the place, landmark, city and country.

## 2. Look at the photo

Models can't view RAW/AVIF/HEIC directly, so make a small JPEG preview in
the temp directory:

```bash
PREVIEW="$(mktemp -d)/photo-preview.jpg"
exiftool -b -JpgFromRaw "${FILE}" > "${PREVIEW}"
[[ -s "${PREVIEW}" ]] || exiftool -b -PreviewImage "${FILE}" > "${PREVIEW}"
# fallback (AVIF/HEIC/empty preview): magick "${FILE}" -resize 1600x1600 "${PREVIEW}"
# or: sips -s format jpeg -Z 1600 "${FILE}" --out "${PREVIEW}"
```

Read the preview with the file-read tool to see it, and open it for the user
with `open "${PREVIEW}"` so they can check it too. If the location or
subject is uncertain (a building, peak, species, event), use web search to
identify it - don't guess silently; say what is uncertain.

## 3. Propose the fields

The photos are uploaded to Flickr, 500px, Pixabay, Unsplash (they import
title, description and keywords as tags), Google Images (reads creator,
credit, license) and social networks (Facebook, Instagram, Threads, X,
Bluesky, Mastodon - they strip metadata, so only the caption/alt text you
paste matters). Write the fields so they work as-is on those sites:

- **Title** - short, specific, max ~70 chars: `Golden Gate Bridge, San
  Francisco, USA` (subject, place, country). Becomes the photo name on
  Flickr/500px/Pixabay.
- **Description** - one or two natural sentences a person would search for:
  what, where, when (season/time of day), notable detail. Avoid keyword
  stuffing; this is the text stock sites and Google index.
- **Keywords** - 10-25 lowercase, comma-separated, alphabetically sorted,
  English. Mix specific and broad terms so both stock-site search and
  Flickr tags work: landmark/proper names, place hierarchy (sub-location,
  city, region, country, continent), subject and object types, scene/genre
  (landscape, architecture, street, wildlife), season, weather, time of day,
  dominant colours, mood. Multi-word terms stay together
  (`golden gate bridge`). Pixabay uses only the first ~20, so put the most
  relevant ones in, not filler. No duplicates, no camera/lens names, no
  generic junk (`photo`, `image`, `nice`). Example:
  `bridge, california, golden gate bridge, san francisco, suspension bridge,
  sunset, usa`.
- **Alt text** - one literal sentence (max ~250 chars) describing what is
  visibly in the picture, for screen readers; reused as alt text on
  Mastodon/Bluesky/X/Instagram.
- **Location** (optional) - City, State/region, Country, ISO country code
  (e.g. `US`, `CZ`) and Sub-location (landmark/district), taken from the
  GPS reverse-geocode or from what you identified. Skip unknown parts.

Present them clearly, mention the sources (GPS, existing tags, web) and ask
the user to approve or edit (use the question tool if available). Do not
write anything until the user has approved all fields. Apply their
edits verbatim.

For several photos of the same scene, propose one shared set and ask if it
should apply to all; otherwise handle photos one at a time.

## 4. Write the metadata

```bash
SKILL_DIR="<path to this skill>"
ALT_TEXT="..." CITY="San Francisco" STATE="California" COUNTRY="USA" \
  COUNTRY_CODE="US" SUBLOCATION="Golden Gate Bridge" \
  "${SKILL_DIR}/scripts/tag_photo.sh" "${TITLE}" "${DESCRIPTION}" "${KEYWORDS}" FILE...
```

Alt text and location variables are optional; leave unknown ones out.

It writes Title/Description/Keywords into the matching EXIF/IPTC/XMP fields
(Title, ObjectName, Headline, ImageDescription, Caption-Abstract,
UserComment, XMP Subject/Keywords, IPTC Keywords, ...), alt text, the
location fields, plus author, credit, licensor and CC BY-SA license fields
that Google Images and photo sites (Flickr, 500px, ...) read, and marks the
photo as a camera capture (IPTC DigitalSourceType, so platforms don't flag
it as AI-generated). Only those tags
change - all other EXIF data (camera, exposure, date, GPS) is kept. Never
strip or rewrite GPS or other EXIF tags. It overwrites the file
in place (no `_original` backup), and prints the result. If a RAW file has a
sidecar `.xmp` next to it, tag that file as well. Show the printed result
to the user.

## 5. Social caption (no extra approval needed)

Social networks strip metadata, so finish by printing a ready-to-paste block
built from the approved fields - nothing new to invent:

```text
<Title>
<Description>
📍 <Sub-location, City, Country>
📷 Petr Ruzicka · CC BY-SA 4.0
#<top 5-10 keywords as CamelCase hashtags, e.g. #GoldenGateBridge>

Alt text: <alt text>
```

Remind the user that Facebook/Instagram/X/etc. need the alt text pasted
manually and that Instagram ignores more than ~30 hashtags.
