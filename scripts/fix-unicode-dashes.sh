#!/usr/bin/env bash
# Normalize Unicode dash characters (em dash, en dash, minus sign, etc.) to a
# single ASCII hyphen ("-"). Used as a pre-commit fixer; pre-commit fails the
# hook when a file is modified.
set -euo pipefail

perl -CSD -i -pe '
  s/[\x{2010}\x{2011}\x{2012}\x{2013}\x{2014}\x{2015}\x{2043}\x{2212}\x{fe58}\x{fe63}\x{ff0d}]/-/g
' "$@"
