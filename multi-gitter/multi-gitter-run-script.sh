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
  # ruzickap/packer-templates
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/packer-templates | ruzickap/ansible-*)
    echo -e "\n*** ansible | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/ansible/" .
    ;;&
  ruzickap/ansible-raspberry-pi-os)
    echo -e "\n*** ansible | ${REPOSITORY}\n"
    git checkout lychee.toml ansible/.ansible-lint
    ;;
  ruzickap/packer-templates)
    echo -e "\n*** ansible-ch | ${REPOSITORY}\n"
    git checkout .gitignore
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
    rm .github/workflows/codeql-actions.yml
    ;;

  ## hugo
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/petr.ruzicka.dev
  # ruzickap/xvx.cz
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/petr.ruzicka.dev | ruzickap/xvx.cz)
    echo -e "\n*** hugo | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/hugo/" .
    ;;

  ## ansible-role
  ## ---------------------------------------------------------------------------------------------------------------------
  # ruzickap/ansible-role-my_common_defaults
  # ruzickap/ansible-role-proxy_settings
  # ruzickap/ansible-role-virtio-win
  ## ---------------------------------------------------------------------------------------------------------------------
  ruzickap/ansible-role-my_common_defaults | ruzickap/ansible-role-proxy_settings | ruzickap/ansible-role-virtio-win)
    echo -e "\n*** ansible-role | ${REPOSITORY}\n"
    rclone copyto --verbose --stats 0 "${HOME}/git/my-git-projects/gh-repo-defaults/ansible-role/" .
    ;;&
  ruzickap/ansible-role-my_common_defaults)
    echo -e "\n*** ansible-role-ch | ${REPOSITORY}\n"
    rm .github/workflows/release-ansible-galaxy.yml
    git checkout .github/workflows/molecule.yml
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
