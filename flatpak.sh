#!/bin/bash

flutter build linux
flatpak run org.flatpak.Builder --user --install-deps-from=flathub --force-clean --repo=flatpak-repo flatpak flatpak.yaml

