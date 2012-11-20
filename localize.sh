#!/bin/sh

find . -name '*.php' > locale/fichiersatraduire.txt

xgettext -f locale/fichiersatraduire.txt --from-code=UTF-8 -o ipolex.pot

msgmerge -U locale/fr_FR.UTF-8/LC_MESSAGES/default.po ipolex.pot
msgmerge -U locale/en_US.UTF-8/LC_MESSAGES/default.po ipolex.pot

msgfmt -c -v -o locale/fr_FR.UTF-8/LC_MESSAGES/default.mo  locale/fr_FR.UTF-8/LC_MESSAGES/default.po
msgfmt -c -v -o locale/en_US.UTF-8/LC_MESSAGES/default.mo  locale/en_US.UTF-8/LC_MESSAGES/default.po

open locale/fr_FR.UTF-8/LC_MESSAGES/default.po
open locale/en_US.UTF-8/LC_MESSAGES/default.po