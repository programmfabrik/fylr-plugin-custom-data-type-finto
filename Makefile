PLUGIN_NAME = custom-data-type-finto
PLUGIN_PATH = easydb-custom-data-type-finto

L10N_FILES = easydb-library/src/commons.l10n.csv \
             l10n/$(PLUGIN_NAME).csv

INSTALL_FILES = \
	$(WEB)/l10n/cultures.json \
	$(WEB)/l10n/de-DE.json \
	$(WEB)/l10n/en-US.json \
	$(WEB)/l10n/fi-FI.json \
	$(WEB)/l10n/sv-SE.json \
	$(JS) \
	$(CSS) \
	build/updater/finto-update.js \
	manifest.yml

COFFEE_FILES = easydb-library/src/commons.coffee \
	src/webfrontend/FINTOUtilities.coffee \
	src/webfrontend/CustomDataTypeFINTO.coffee \
	src/webfrontend/CustomDataTypeFINTOFacet.coffee \
  src/webfrontend/CustomDataTypeFINTOTreeview.coffee


CSS_FILE = src/webfrontend/css/main.css

UPDATER_SCRIPT_COFFEE_FILES = \
	src/webfrontend/FINTOUtilities.coffee

UPDATER_SCRIPT = \
	src/updater/FINTOUpdater.js

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

all: build

include easydb-library/tools/base-plugins.make

build: code buildupdater buildinfojson

code: $(subst .coffee,.coffee.js,${COFFEE_FILES}) $(L10N)
	mkdir -p build
	mkdir -p build/webfrontend
	cat $^ > build/webfrontend/custom-data-type-finto.js
	cat $(CSS_FILE) >> build/webfrontend/custom-data-type-finto.css

buildupdater: $(subst .coffee,.coffee.js,${UPDATER_SCRIPT_COFFEE_FILES})
	mkdir -p build/updater
	cat $^ > build/updater/finto-update.js
	cat $(UPDATER_SCRIPT) >> build/updater/finto-update.js

clean: clean-base
