#!/bin/bash

flutter build linux
flatpak run org.flatpak.Builder --user --install-deps-from=flathub --force-clean --repo=flatpak-repo flatpak flatpak.yaml
flatpak build-bundle flatpak-repo story_reader.flatpak io.github.tareksander.story_reader --runtime-repo=https://flathub.org/repo/flathub.flatpakrepo
