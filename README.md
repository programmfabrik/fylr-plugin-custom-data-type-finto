> This Plugin / Repo is being maintained by a community of developers.
There is no warranty given or bug fixing guarantee; especially not by
Programmfabrik GmbH. Please use the github issue tracking to report bugs
and self organize bug fixing. Feel free to directly contact the committing
developers.

# fylr-custom-data-type-finto

This is a plugin for [fylr](https://documentation.fylr.cloud/docs) with Custom Data Type `CustomDataTypeFINTO` for references to entities of the [Finnish Thesaurus and Ontology Service FINTO (https://finto.fi/)](https://finto.fi/).

The Plugins uses <https://api.finto.fi> for the communication with FINTO. Inspect the Swagger-documentation here: <https://api.finto.fi/doc/>

The parameters of this plugin are based very closely on the parameters of the FINTO API. This makes it easier to interpret the results and in some places also explains features that are not possible or features that appear to be implemented in a complicated manner.

## requirements
- current fylr version
- nodejs-Version >= 18 OR nodejs-Version >= 12 with added "fetch"-Module

## installation

The latest version of this plugin can be found [here](https://github.com/programmfabrik/fylr-custom-data-type-finto/releases/latest/download/customDataTypeFinto.zip).

The ZIP can be downloaded and installed using the plugin manager, or used directly (recommended).

Github has an overview page to get a list of [all release](https://github.com/programmfabrik/fylr-custom-data-type-finto/releases/).

## configuration

As defined in `manifest.yml` this datatype can be configured:

### Schema options
The plugin appears as a separate data type in the data model of object types and can be selected as a data type for a column.

* vocabulary-notation:
  * which vocabulary-notation to use. List of Vocabularys [in FINTO](https://api.finto.fi/rest/v1/vocabularies?lang=en)
  * repeatable. Multiple vocabularies can be used simultaneously in pop-up mode (space-separated list, just as it is standard in the FINTO-API.)
  * e.g. "yso", "afo cer allars", "ysa koko"
  * mandatory parameter

* vocabulary-parent
  * from FINTO-API-Docu: *“limit search to concepts which have the given concept (specified by URI) as parent in their transitive broader hierarchy”*
  * Cannot be used in the tree view or has no effect there.
  * Mainly intended for limiting the number of hits for the selection in the dropdown (editor style "dropdown")
  * May not work as intended when using multiple vocabularies (due to possible API limitations)

* lang
  * language of labels to match
  * e.g. "en" or "fi" (ISO-639-1)
  * default: empty == * == all languages
  * optional parameter


### Mask options
Contains the feature options provided by easydb by default.

* Editor-style:
  * dropdown
  * popup
  * popup with treeview
* editor_display
    * display condensed in one line
    * default display
* use_dropdown_info_popup
    * show infopopup also for dropdown? 
* Allow label selection:
  * Allow manual selection from all available labels (preflabels + altlabels in all available languages. Has no effect in “Dropdown”-mode)
* display_multiple_languages_in_searchhits
    * a list of (ISO-639-1), seperated by comma ",". Then there will be multiple searchresult-display-labels in the configures languages separated with " / ". This is just display in search.


### baseconfiguration
The update mechanism for the plugin data can be configured here.
* default language
  * The default label language for updater requests (as fallback) (ISO 639-1)
  
Mapbox for map-display can be configured here
* mapbox
  * mapbox API token for map display
  * mapbox-style for the maps. Default is "satellite-streets-v12"

## saved data
* conceptName
    * Preferred label of the linked record
* conceptURI
    * URI to linked record
* conceptSource
    * Source of the related authority data. Needed for LIDO-XML-attribute
    * Example: http://www.yso.fi/onto/ysa/123
       * ConceptSource = ysa
* conceptAncestors
    * List of URI’s of the ancestors records plus the records URI itself
* conceptGeoJSON
    * geoJSON, if given
* frontendLanguage
  * Includes a language. Either the language configured in the field in the data model is used here, or the front-end language as a fallback. The label is preferred and if not set manually in this language. The updater needs this information.
* _fulltext
    * Label, URI, source and skos-notes are aggregated
* _standard
    * List of preferred labels in different languages
* _standard.geo
    * geoJSON, if given
* facetTerm
    * URI combined with preferred label in given frontend-language and in all other configured data-languages (as far as provided by the FINTO-API.)


## frontend
* editor & groupeditor
  * Depends on the configuration of the data model and mask settings
    * field as a dropdown
    * field with popup
    * Field with treeview in popup
  * If several vocabularies are configured, the first one is used with the "Dropdown" option. For the other styles, there is a choice in the popup. The search slot (popup & popup with treeview) allows a quick search.
* detail & print
  * In detailview and print the choosen label and the URI are displayed. In detailview the URI is clickable and has an infopopup-feature
* infopopup
  * When hovering a URI in detailview or editmode, an infopopup appears and displays additional information about the record. This information is pulled live from FINTO-API.
* search
  * The content can be found using the full-text search. The advanced search can also be used. The same options are available there as in the editor
* facets
  * The plugin fields can be enabled for faceting in the data model and used accordingly
* export
  * The values of the plugin fields can be exported from the frontend via the fylr exporter


## fylr-API
* The values of the plugin fields are output natively via the API in a JSON structure and can also be used accordingly for the entire spectrum of requests (as far as known and as far as implemented in comparable plugins).



## updater
* An automatic update mechanism is integrated. The updater iterates over each occurrence of the new data type and requests the FINTO API with the given URI. The result of this query is compared with the content in the fylr-database. If necessary, the value is updated.




## sources

The source code of this plugin is managed in a git repository at <https://github.com/programmfabrik/easydb-custom-data-type-finto>.
