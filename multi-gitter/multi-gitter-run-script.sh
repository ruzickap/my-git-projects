#!/usr/bin/env bash

echo -e "\n***************************************************\n* ${REPOSITORY}\n***************************************************\n"

set -x

rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/my-defaults/" .

case "${REPOSITORY}" in
  ## action
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/action-my-broken-link-checker
  # ruzickap/action-my-markdown-link-checker
  # ruzickap/action-my-markdown-linter
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/action-*)
    echo -e "\n*** action | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/action/" .
    ;;&

  ## ansible
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/ansible-my_workstation
  # ruzickap/ansible-openwrt
  # ruzickap/ansible-raspberry-pi-os
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/ansible-*)
    echo -e "\n*** ansible | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/ansible/" .
    ;;&
  ruzickap/ansible-raspberry-pi-os)
    echo -e "\n*** ansible | ${REPOSITORY}\n"
    git checkout lychee.toml ansible/.ansible-lint
    ;;

  ## latex
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/cheatsheet-macos
  # ruzickap/cv
  # ruzickap/cheatsheet-systemd
  # ruzickap/cheatsheet-atom
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/cheatsheet-* | ruzickap/cv)
    echo -e "\n*** latex | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/latex/" .
    ;;&
  ruzickap/cv)
    echo -e "\n*** latex-ch | ${REPOSITORY}\n"
    git checkout run.sh
    rm .github/workflows/{codeql-actions.yml,scorecards.yml}
    ;;

  ## hugo
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/petr.ruzicka.dev
  # ruzickap/xvx.cz
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/petr.ruzicka.dev | ruzickap/xvx.cz)
    echo -e "\n*** hugo | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/hugo/" .
    ;;&
  ruzickap/petr.ruzicka.dev)
    echo -e "\n*** hugo-ch | ${REPOSITORY}\n"
    git checkout lychee.toml
    ;;

  ## default
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/gha-test
  # ruzickap/malware-cryptominer-container
  # ruzickap/my-git-projects
  # ruzickap/ruzickap
  # ruzickap/test_usb_stick_for_tv
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/malware-cryptominer-container)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .checkov.yml .github/workflows/release-please.yml .github/renovate.json5 lychee.toml
    ;;
  ruzickap/my-git-projects)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .github/renovate.json5
    ;;
  ruzickap/ruzickap.github.io)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout .github/renovate.json5 .github/workflows/mega-linter.yml lychee.toml .markdownlint.yml .mega-linter.yml
    ;;
  ruzickap/k8s-multicluster-gitops)
    echo -e "\n*** default-ch | ${REPOSITORY}\n"
    git checkout lychee.toml
    ;;
esac
