#!/usr/bin/env bash

set -eu

GITHUB_PROJECT="$*"

# shellcheck disable=SC2086
cat << EOF

[![GitHub release](https://img.shields.io/github/v/release/ruzickap/${GITHUB_PROJECT}.svg)](https://github.com/ruzickap/${GITHUB_PROJECT}/releases/latest)
[![GitHub license](https://img.shields.io/github/license/ruzickap/${GITHUB_PROJECT}.svg)](https://github.com/ruzickap/${GITHUB_PROJECT}/blob/master/LICENSE)
[![GitHub stars](https://img.shields.io/github/stars/ruzickap/${GITHUB_PROJECT}.svg?style=social)](https://github.com/ruzickap/${GITHUB_PROJECT}/stargazers)
[![GitHub forks](https://img.shields.io/github/forks/ruzickap/${GITHUB_PROJECT}.svg?style=social)](https://github.com/ruzickap/${GITHUB_PROJECT}/network/members)
[![GitHub watchers](https://img.shields.io/github/watchers/ruzickap/${GITHUB_PROJECT}.svg?style=social)](https://github.com/ruzickap/${GITHUB_PROJECT})

* CI/CD status:

$(curl -s https://api.github.com/repos/ruzickap/${GITHUB_PROJECT}/actions/workflows | jq -r '.workflows[] | "  [![GitHub Actions status - " + .name + "](" + .badge_url + ")](" + ( .badge_url | sub("/workflows/.*"; "") ) + "/actions?query=workflow%3A\"" + ( .name | gsub(" "; "+") ) + "\")"' | sort | uniq | grep -v 'update-semver')

* Issue tracking:

  [![GitHub issues](https://img.shields.io/github/issues/ruzickap/${GITHUB_PROJECT}.svg)](https://github.com/ruzickap/${GITHUB_PROJECT}/issues)
  [![GitHub pull requests](https://img.shields.io/github/issues-pr/ruzickap/${GITHUB_PROJECT}.svg)](https://github.com/ruzickap/${GITHUB_PROJECT}/pulls)

* Repository:

  [![GitHub release date](https://img.shields.io/github/release-date/ruzickap/${GITHUB_PROJECT}.svg)](https://github.com/ruzickap/${GITHUB_PROJECT}/releases)
  [![GitHub last commit](https://img.shields.io/github/last-commit/ruzickap/${GITHUB_PROJECT}.svg)](https://github.com/ruzickap/${GITHUB_PROJECT}/commits/)
  [![GitHub commits since latest release](https://img.shields.io/github/commits-since/ruzickap/${GITHUB_PROJECT}/latest)](https://github.com/ruzickap/${GITHUB_PROJECT}/commits/)
  [![GitHub commit activity](https://img.shields.io/github/commit-activity/y/ruzickap/${GITHUB_PROJECT}.svg)](https://github.com/ruzickap/${GITHUB_PROJECT}/commits/)
  [![GitHub repo size](https://img.shields.io/github/repo-size/ruzickap/${GITHUB_PROJECT}.svg)](https://github.com/ruzickap/${GITHUB_PROJECT})
  [![GitHub download latest release](https://img.shields.io/github/downloads/ruzickap/${GITHUB_PROJECT}/total.svg)](https://github.com/ruzickap/${GITHUB_PROJECT}/releases/latest)
EOF
