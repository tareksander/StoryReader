#!/bin/bash

tar -c -a -f linux-bundle.tar.gz --owner=builder:1 --group=builder:1 io.github.tareksander.StoryReader.desktop io.github.tareksander.StoryReader.metainfo.xml icon.png -C build/linux/$1/release/bundle data lib story_reader

