ZIP_NAME ?= "customDataTypeFinto.zip"

PLUGIN_NAME = custom-data-type-finto
PLUGIN_PATH = easydb-custom-data-type-finto

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

code: $(subst .coffee,.coffee.js,${COFFEE_FILES})
	mkdir -p build
	mkdir -p build/custom-data-type-finto
	mkdir -p build/custom-data-type-finto/webfrontend
	cp -r l10n build/custom-data-type-finto
	cat $^ > build/custom-data-type-finto/webfrontend/customDataTypeFinto.js
	cat $(CSS_FILE) >> build/custom-data-type-finto/webfrontend/customDataTypeFinto.css
	cp manifest.yml build/custom-data-type-finto/manifest.yml
	cp build-info.json build/custom-data-type-finto/build-info.json

buildupdater: $(subst .coffee,.coffee.js,${UPDATER_SCRIPT_COFFEE_FILES})
	mkdir -p build/custom-data-type-finto/updater
	cat $^ > build/custom-data-type-finto/updater/customDataTypeFintoUpdater.js
	cat $(UPDATER_SCRIPT) >> build/custom-data-type-finto/updater/customDataTypeFintoUpdater.js

clean: clean-base

zip: build ## build zip file
	cd build && zip ${ZIP_NAME} -r custom-data-type-finto/
