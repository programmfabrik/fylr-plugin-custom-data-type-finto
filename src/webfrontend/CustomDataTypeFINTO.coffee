class CustomDataTypeFINTO extends CustomDataTypeWithCommons

  #######################################################################
  # configure used facet
  getFacet: (opts) ->
      opts.field = @
      new CustomDataTypeFINTOFacet(opts)

  #######################################################################
  # return name of plugin
  getCustomDataTypeName: ->
    "custom:base.custom-data-type-finto.finto"

  #######################################################################
  # overwrite getCustomMaskSettings
  getCustomMaskSettings: ->
    if @ColumnSchema
      return @FieldSchema.custom_settings || {};
    else
      return {}

  #######################################################################
  # overwrite getCustomSchemaSettings
  getCustomSchemaSettings: ->
    if @ColumnSchema
      return @ColumnSchema.custom_settings || {};
    else
      return {}

  #######################################################################
  # overwrite getCustomSchemaSettings
  name: (opts = {}) ->
    if ! @ColumnSchema
      return "noNameSet"
    else
      return @ColumnSchema?.name

  #######################################################################
  # return name (l10n) of plugin
  getCustomDataTypeNameLocalized: ->
    $$("custom.data.type.finto.name")

  #######################################################################
  # returns name of the given vocabulary from datamodel
  getVocabularyNameFromDatamodel: (opts = {}) ->
    vocNotation = @getCustomSchemaSettings().vocabulary_notation?.value
    return vocNotation

  #######################################################################
  # returns name of the needed or configures language for the labels of api-requests
  getLanguageParameterForRequests: () ->
    # best case: "lang" is configured in db-modell
    language = @getCustomSchemaSettings()?.lang?.value
    # if not configures in db-modell, use frontendlanguage
    if !language
      desiredLanguage = ez5.loca.getLanguage()
      desiredLanguage = desiredLanguage.split('-')
      language = desiredLanguage[0]

    if language == '*'
      language = ''

    return language


  #######################################################################
  # get active frontend language
  getActiveFrontendLanguage: () ->
    frontendLanguage = ez5.loca.getLanguage()
    frontendLanguage = frontendLanguage.split('-')
    frontendLanguage = frontendLanguage[0]

    return frontendLanguage
  
  #######################################################################
  # returns the databaseLanguages
  getDatabaseLanguages: () ->
    databaseLanguages = ez5.loca.getLanguageControl().getLanguages().slice()

    return databaseLanguages

  #######################################################################
  # returns the frontendLanguages
  getFrontendLanguages: () ->
    frontendLanguages = ez5.session.getConfigFrontendLanguages().slice()

    return frontendLanguages

  #######################################################################
  # render popup as treeview?
  renderPopupAsTreeview: ->
    result = false
    if @.getCustomMaskSettings().editor_style?.value == 'popover_treeview'
      result = true
    result


  #######################################################################
  # get the active vocabular
  #   a) from vocabulary-dropdown (POPOVER)
  #   b) return all given vocs (inline)
  getActiveVocabularyName: (cdata) ->
    that = @
    # is the voc set in dropdown?
    if cdata.finto_PopoverVocabularySelect && that.popover?.isShown()
      vocParameter = cdata.finto_PopoverVocabularySelect
    else
      # else all given vocs
      vocParameter = that.getVocabularyNameFromDatamodel();
    vocParameter

  #######################################################################
  # returns markup to display in expert search
  #######################################################################
  renderSearchInput: (data, opts) ->
      that = @
      if not data[@name()]
          data[@name()] = {}

      that.callFromExpertSearch = true

      form = @renderEditorInput(data, '', {})

      CUI.Events.listen
            type: "data-changed"
            node: form
            call: =>
                CUI.Events.trigger
                    type: "search-input-change"
                    node: form
                CUI.Events.trigger
                    type: "editor-changed"
                    node: form
                CUI.Events.trigger
                    type: "change"
                    node: form
                CUI.Events.trigger
                    type: "input"
                    node: form

      form.DOM

  needsDirectRender: ->
    return true

  #######################################################################
  # make searchfilter for expert-search
  #######################################################################
  getSearchFilter: (data, key=@name()) ->
      that = @

      objecttype = @path()
      objecttype = objecttype.split('.')
      objecttype = objecttype[0]

      # search for empty values
      if data[key+":unset"]
          filter =
              type: "in"
              fields: [ @fullName()+".conceptName" ]
              in: [ null ]
          filter._unnest = true
          filter._unset_filter = true
          return filter

      # dropdown or popup without tree or use of searchbar: use sameas
      if ! that.renderPopupAsTreeview() || ! data[key]?.experthierarchicalsearchmode
        filter =
            type: "complex"
            search: [
                type: "in"
                mode: "fulltext"
                bool: "must"
                phrase: false
                fields: [ @path() + '.' + @name() + ".conceptURI" ]
            ]
        if ! data[@name()]
            filter.search[0].in = [ null ]
        else if data[@name()]?.conceptURI
            filter.search[0].in = [data[@name()].conceptURI]
        else
            filter = null

      # popup with tree: 3 Modes
      if that.renderPopupAsTreeview()
        # 1. find all records which have the given uri in their ancestors
        if data[key].experthierarchicalsearchmode == 'include_children'
          filter =
              type: "complex"
              search: [
                  type: "match"
                  mode: "token"
                  bool: "must",
                  phrase: true
                  fields: [ @path() + '.' + @name() + ".conceptAncestors" ]
              ]
          if ! data[@name()]
              filter.search[0].string = null
          else if data[@name()]?.conceptURI
              filter.search[0].string = data[@name()].conceptURI
          else
              filter = null
        # 2. find all records which have exact that match
        if data[key].experthierarchicalsearchmode == 'exact'
          filter =
              type: "complex"
              search: [
                  type: "in"
                  mode: "fulltext"
                  bool: "must"
                  phrase: true
                  fields: [ @path() + '.' + @name() + ".conceptURI" ]
              ]
          if ! data[@name()]
              filter.search[0].in = [ null ]
          else if data[@name()]?.conceptURI
              filter.search[0].in = [data[@name()].conceptURI]
          else
              filter = null

      filter


  #######################################################################
  # make tag for expert-search
  #######################################################################
  getQueryFieldBadge: (data) ->
      if ! data[@name()]
          value = $$("field.search.badge.without")
      else if ! data[@name()]?.conceptURI
          value = $$("field.search.badge.without")
      else
          value = data[@name()].conceptName

      if data[@name()]?.experthierarchicalsearchmode == 'exact' || data[@name()]?.experthierarchicalsearchmode == 'include_children'
        searchModeAddition = $$("custom.data.type.finto.modal.form.popup.choose_expertsearchmode_." + data[@name()].experthierarchicalsearchmode + "_short")
        value = searchModeAddition + ': ' + value


      name: @nameLocalized()
      value: value

  #######################################################################
  # choose label manually from popup
  #######################################################################
  __chooseLabelManually: (cdata,  layout, resultJSON, anchor, opts) ->
      that = @
      choiceLabels = []
      #preflabels
      if Array.isArray(resultJSON.prefLabel)
        for key, value of resultJSON.prefLabel
          if value.value not in choiceLabels
            choiceLabels.push value.value
      else if resultJSON.prefLabel instanceof Object
        if resultJSON.prefLabel.value not in choiceLabels
          choiceLabels.push resultJSON.prefLabel.value
      # altlabels
      if Array.isArray(resultJSON.altLabel)
        for key, value of resultJSON.altLabel
          if value.value not in choiceLabels
            choiceLabels.push value.value
      else if resultJSON.altLabel instanceof Object
        if resultJSON.altLabel.value not in choiceLabels
          choiceLabels.push resultJSON.altLabel.value

      prefLabelButtons = []
      for key, value of choiceLabels
        button = new CUI.Button
          text: value
          appearance: "flat"
          icon_left: new CUI.Icon(class: "fa-arrow-circle-o-right")
          class: 'fintoPlugin_SearchButton'
          onClick: (evt,button) =>
            # lock choosen conceptName in savedata
            cdata.conceptName = button.opts.text
            # mark as choosen by hand
            cdata.conceptNameChosenByHand = true
            # update the layout in form
            that.__updateResult(cdata, layout, opts)
            # close popovers
            if that.popover
              that.popover.hide()
            if chooseLabelPopover
              chooseLabelPopover.hide()
            @
        prefLabelButtons.push button

      # init popover
      chooseLabelPopover = new CUI.Popover
          element: anchor
          placement: "wn"
          class: "commonPlugin_Popover"
          pane:
            padded: true
            header_left: new CUI.Label(text: $$('custom.data.type.finto.modal.form.popup.choose_manual_label'))
      chooseLabelContent = new  CUI.VerticalLayout
          class: "cui-pane"
          center:
            content: [
              prefLabelButtons
            ]
          bottom: null
      chooseLabelPopover.setContent(chooseLabelContent)
      chooseLabelPopover.show()

  #######################################################################
  # choose search mode for the hierarchical expert search
  #   ("exact" or "with children")
  #######################################################################
  __chooseExpertHierarchicalSearchMode: (cdata,  layout, resultJSON, anchor, opts) ->
      that = @

      ConfirmationDialog = new CUI.ConfirmationDialog
        text: $$('custom.data.type.finto.modal.form.popup.choose_expertsearchmode_label2') + '\n\n' +  $$('custom.data.type.finto.modal.form.popup.choose_expertsearchmode_label3') + ': ' + cdata.conceptURI +  '\n'
        title: $$('custom.data.type.finto.modal.form.popup.choose_expertsearchmode_label')
        icon: "question"
        cancel: false
        buttons: [
          text: $$('custom.data.type.finto.modal.form.popup.choose_expertsearchmode_.exact')
          onClick: =>
            # lock choosen searchmode in savedata
            cdata.experthierarchicalsearchmode = 'exact'
            # update the layout in form
            that.__updateResult(cdata, layout, opts)
            ConfirmationDialog.destroy()
        ,
          text: $$('custom.data.type.finto.modal.form.popup.choose_expertsearchmode_.include_children')
          primary: true
          onClick: =>
            # lock choosen searchmode in savedata
            cdata.experthierarchicalsearchmode = 'include_children'
            # update the layout in form
            that.__updateResult(cdata, layout, opts)
            ConfirmationDialog.destroy()
        ]
      ConfirmationDialog.show()

  #######################################################################
  # handle suggestions-menu  (POPOVER)
  #######################################################################
  __updateSuggestionsMenu: (cdata, cdata_form, finto_searchstring, input, suggest_Menu, searchsuggest_xhr, layout, opts) ->
    that = @

    delayMillisseconds = 50

    # show loader
    menu_items = [
        text: $$('custom.data.type.finto.modal.form.loadingSuggestions')
        icon_left: new CUI.Icon(class: "fa-spinner fa-spin")
        disabled: true
    ]
    itemList =
      items: menu_items
    suggest_Menu.setItemList(itemList)

    setTimeout ( ->

        finto_searchstring = finto_searchstring.replace /^\s+|\s+$/g, ""
        if finto_searchstring.length == 0
          return

        suggest_Menu.show()

        # maxhits-Parameter
        if cdata_form
          finto_countSuggestions = cdata_form.getFieldsByName("finto_countSuggestions")[0].getValue()
        else
          finto_countSuggestions = 10

        # run autocomplete-search via xhr
        if searchsuggest_xhr.xhr != undefined
            # abort eventually running request
            searchsuggest_xhr.xhr.abort()

        # voc parameter
        vocParameter = that.getActiveVocabularyName(cdata)

        # start request
        searchsuggest_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//api.finto.fi/rest/v1/search?query=' + finto_searchstring + '*&vocab=' + vocParameter + '&lang=' + that.getLanguageParameterForRequests() + '&unique=true&maxhits=' + finto_countSuggestions)
        searchsuggest_xhr.xhr.start().done((data, status, statusText) ->

            extendedInfo_xhr = { "xhr" : undefined }

            if data.results
              data = data.results
            else
              data = []

            # show voc-headlines in selectmenu? default: no headlines
            showHeadlines = false;

            # are there multible vocs in datamodel?
            multibleVocs = false
            vocTest = that.getVocabularyNameFromDatamodel()
            vocTestArr = vocTest.split(' ')

            if vocTestArr.length > 1
              multibleVocs = true

            # conditions for headings in searchslot (for documentation reasons very detailed)

            #A. If only search slot (inlineform, popup invisible)
            if ! that.popover?.isShown()
              # A.1. If only 1 vocabulary, then no subheadings
              if multibleVocs == false
                showHeadlines = false
              else
              # A.2. If several vocabularies, then necessarily and always subheadings
              if multibleVocs == true
                showHeadlines = true
            #B. When popover (popup visible)
            else if that.popover?.isShown()
              # B.1. If several vocabularies
              if multibleVocs == true
                # B.1.1 If vocabulary selected from dropdown, then no subheadings
                if cdata?.finto_PopoverVocabularySelect != '' && cdata?.finto_PopoverVocabularySelect != vocTest
                  showHeadlines = false
                else
                # B.2.2 If "All vocabularies" in dropdown, then necessarily and always subheadings
                if cdata?.finto_PopoverVocabularySelect == vocTest
                  showHeadlines = true
              else
                # B.2. If only one vocabulary
                if multibleVocs == false
                  # B.2.1 Don't show subheadings
                  showHeadlines = false

            # the actual vocab (if multible, add headline + divider)
            actualVocab = ''
            # sort by voc/uri-part in tmp-array
            tmp_items = []
            # a list of the unique text suggestions for treeview-suggest
            unique_text_suggestions = []
            unique_text_items = []
            
            uriOrderedRecords = []
            for recordKey, record of data
              if ! uriOrderedRecords[record.uri]
                uriOrderedRecords[record.uri] = []
              uriOrderedRecords[record.uri].push record

            for recordsURI, records of uriOrderedRecords
              vocab = 'default'
              if showHeadlines
                vocab = records[0].vocab
              if ! Array.isArray tmp_items[vocab]
                tmp_items[vocab] = []
              do(records) ->
                # check and get if record exists in frontendlanguage in results
                prefLabel = records[0].prefLabel;
                for recordKey, record of records
                  if record.lang == that.getActiveFrontendLanguage()
                    prefLabel = record.prefLabel
                    continue
                # if labels are wanted it multiple languages (test with "joe")
                langLabels = []
                if that.getCustomMaskSettings()?.display_multiple_languages_in_searchhits?.value
                  langEntries = that.getCustomMaskSettings().display_multiple_languages_in_searchhits.value.split(',')
                  for recordKey, record of records
                    if langEntries.includes record.lang
                      langLabels.push record.prefLabel
                  langLabels = Array.from new Set langLabels
                  if langLabels.length > 0
                    prefLabel = langLabels.join(' / ')
                # new item
                item =
                  text: prefLabel
                  value: records[0].uri + '@' + records[0].vocab
                  tooltip:
                    markdown: true
                    placement: "ne"
                    content: (tooltip) ->
                      # show infopopup
                      encodedURI = encodeURIComponent(records[0].uri)
                      that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                      new CUI.Label(icon: "spinner", text: $$('custom.data.type.finto.modal.form.popup.loadingstring'))
                tmp_items[vocab].push item
                # unique item for treeview
                if suggestion not in unique_text_suggestions
                  unique_text_suggestions.push suggestion
                  item =
                    text: suggestion
                    value: suggestion
                  unique_text_items.push item
            # create new menu with suggestions
            menu_items = []
            actualVocab = ''
            for vocab, part of tmp_items
              if showHeadlines
                if ((actualVocab == '' || actualVocab != vocab) && vocab != 'default')
                     actualVocab = vocab
                     item =
                          divider: true
                     menu_items.push item
                     item =
                          label: actualVocab
                     menu_items.push item
                     item =
                          divider: true
                     menu_items.push item
              for suggestion,key2 in part
                menu_items.push suggestion
            # set new items to menu
            itemList =
              onClick: (ev2, btn) ->
                # if inline or treeview without popup
                if ! that.renderPopupAsTreeview() || ! that.popover?.isShown()
                  valueParts = btn.getOpt("value")
                  valueParts = valueParts.split '@'
                  searchUri = valueParts[0]
                  recordsOriginalVocab = valueParts[1]

                  if that.popover
                    # put a loader to popover
                    newLoaderPanel = new CUI.Pane
                        class: "cui-pane"
                        center:
                            content: [
                                new CUI.HorizontalLayout
                                  maximize: true
                                  left: null
                                  center:
                                    content:
                                      new CUI.Label
                                        centered: true
                                        size: "big"
                                        icon: "spinner"
                                        text: $$('custom.data.type.finto.modal.form.popup.loadingstring')
                                  right: null
                            ]
                    that.popover.setContent(newLoaderPanel)

                  # get full record to get correct preflabel in desired language
                  # load the record itself and also the hierarchie of the record
                  allDataAPIPath = location.protocol + '//api.finto.fi/rest/v1/data?uri=' + encodeURIComponent(searchUri) + '&format=application%2Fjson'
                  # XHR for basic information
                  dataEntry_xhr = new (CUI.XHR)(url: allDataAPIPath)
                  dataEntry_xhr.start().done((resultJSON, status, statusText) ->

                    # xhr for hierarchy-informations to fill "conceptAncestors"
                    allHierarchyAPIPath = location.protocol + '//api.finto.fi/rest/v1/' + recordsOriginalVocab + '/hierarchy?uri=' + encodeURIComponent(searchUri) + '&lang=' + that.getLanguageParameterForRequests() + '&format=application%2Fjson'

                    dataHierarchy_xhr = new (CUI.XHR)(url: allHierarchyAPIPath)
                    dataHierarchy_xhr.start().done((hierarchyJSON, status, statusText) ->

                      hierarchyJSON = hierarchyJSON.broaderTransitive
                      # read only the needed part
                      for json in resultJSON.graph
                        if json.uri == searchUri
                          resultJSON = json

                      databaseLanguages = that.getDatabaseLanguages()
                      frontendLanguage = that.getActiveFrontendLanguage()
                      desiredLanguage = that.getLanguageParameterForRequests()

                      # save conceptName
                      cdata.conceptName = FINTOUtilities.getPrefLabelFromDataResult(resultJSON, databaseLanguages, frontendLanguage)
                      # save conceptURI
                      cdata.conceptURI = resultJSON.uri
                      # save conceptSource
                      cdata.conceptSource = recordsOriginalVocab
                      # save _fulltext
                      cdata._fulltext = FINTOUtilities.getFullTextFromJSONObject(resultJSON, databaseLanguages)
                      # save _standard
                      cdata._standard = FINTOUtilities.getStandardFromJSONObject(resultJSON, databaseLanguages)
                      # save facet
                      cdata.facetTerm = FINTOUtilities.getFacetTermFromJSONObject(resultJSON, databaseLanguages)
                      # save geo (also in _standard)
                      geoJSON = FINTOUtilities.getGeoJSONFromFINTOJSON(resultJSON) 
                      if geoJSON
                        cdata.conceptGeoJSON = geoJSON

                      # save frontendlanguage
                      cdata.frontendLanguage = that.getActiveFrontendLanguage()

                      # save ancestors if treeview, add ancestors
                      cdata.conceptAncestors = []
                      for i in [1...Object.keys(hierarchyJSON).length]
                        for hierarchyKey, hierarchyValue of hierarchyJSON
                          if hierarchyKey != resultJSON.uri
                            # check if hierarchy-entry contains the actual record in narrowers
                            #   or if the narrower of the hierarchy-entry contains one of the already set ancestors
                            isnarrower = false
                            if hierarchyValue.narrower
                              if ! Array.isArray(hierarchyValue.narrower)
                                hierarchyValue.narrower = [hierarchyValue.narrower]
                              for narrower in hierarchyValue.narrower
                                if narrower.uri == resultJSON.uri
                                  if not cdata.conceptAncestors.includes(hierarchyValue.uri)
                                    cdata.conceptAncestors.push hierarchyValue.uri
                                else if cdata.conceptAncestors.includes narrower.uri
                                  if not cdata.conceptAncestors.includes(hierarchyValue.uri)
                                    cdata.conceptAncestors.push hierarchyValue.uri

                      # add own uri to ancestor-uris
                      cdata.conceptAncestors.push resultJSON.uri
                      # merge ancestors to string
                      cdata.conceptAncestors = cdata.conceptAncestors.join(' ')

                      # is user allowed to choose label manually from list and not in expert-search?!
                      if that.getCustomMaskSettings().allow_label_choice?.value && opts?.mode == 'editor'
                        if newLoaderPanel
                          anchor = newLoaderPanel
                        else
                          anchor = input
                        that.__chooseLabelManually(cdata, layout, resultJSON, anchor, opts)
                        # update the layout in form
                        that.__updateResult(cdata, layout, opts)
                        # close popover
                        if that.popover
                          that.popover.hide()
                        @

                      # is this from exact search and user has to choose exact-search-mode?!
                      if that._finto_opts?.callFromExpertSearch == true
                        CustomDataTypeFINTO.prototype.__chooseExpertHierarchicalSearchMode(that._cdata, that._editor_layout, resultJSON, that._editor_layout, that._finto_opts)

                      if opts?.data
                          opts.data[that.name(opts)] = CUI.util.copyObject(cdata)
                    
                      CUI.Events.trigger
                          node: layout
                          type: "editor-changed"
                      CUI.Events.trigger
                          node: layout
                          type: "data-changed"

                      # update the layout in form
                      that.__updateResult(cdata, layout, opts)
                      # close popover
                      if that.popover
                        that.popover.hide()
                      @

                    )
                  )

                # if treeview: set choosen suggest-entry to searchbar
                if that.renderPopupAsTreeview() && that.popover
                  if cdata_form
                    cdata_form.getFieldsByName("searchbarInput")[0].setValue(btn.getText())

              items: menu_items

            # if treeview in popup: use unique suggestlist (only one voc and text-search)
            if that.renderPopupAsTreeview() && that.popover?.isShown()
              itemList.items = unique_text_items

            # if no suggestions: set "empty" message to menu
            if itemList.items.length == 0
              itemList =
                items: [
                  text: $$('custom.data.type.finto.modal.form.popup.suggest.nohit')
                  value: undefined
                ]
            suggest_Menu.setItemList(itemList)
            suggest_Menu.show()
        )
    ), delayMillisseconds


  #######################################################################
  # render editorinputform
  renderEditorInput: (data, top_level_data, opts) ->
    that = @

    if not data[@name()]
        cdata = {
            conceptName : ''
            conceptURI : ''
        }
        data[@name()] = cdata
    else
        cdata = data[@name()]

    # inline or popover?
    dropdown = false
    if opts?.editorstyle
      editorStyle = opts.editorstyle
    else
      if @getCustomMaskSettings().editor_style?.value == 'dropdown'
        editorStyle = 'dropdown'
      else
        editorStyle = 'popup'

    if editorStyle == 'dropdown'
        @__renderEditorInputInline(data, cdata, opts)
    else
        @__renderEditorInputPopover(data, cdata, opts)


  #######################################################################
  # render form as DROPDOWN
  __renderEditorInputInline: (data, cdata, opts = {}) ->
        that = @

        extendedInfo_xhr = { "xhr" : undefined }

        # if multible vocabularys are given, show only the first one in dropdown
        voc = 'yso'
        vocTest = @getVocabularyNameFromDatamodel(opts)
        vocTest = vocTest.split('|')
        if(vocTest.length > 1)
          voc = vocTest[0]
        else
          voc = @getVocabularyNameFromDatamodel(opts)

        fields = []
        select = {
            type: CUI.Select
            undo_and_changed_support: false
            empty_text: $$('custom.data.type.finto.modal.form.dropdown.loadingentries')
            # read select-items from finto-api
            options: (thisSelect) =>
                  dfr = new CUI.Deferred()
                  values = []

                  # parent-parameter?
                  parentParameter = '123'
                  if that.getCustomSchemaSettings()?.vocabulary_parent?.value
                    parentParameter = that.getCustomSchemaSettings().vocabulary_parent.value

                  # start new request
                  searchsuggest_xhr = new (CUI.XHR)(url: location.protocol + '//api.finto.fi/rest/v1/' + voc + '/narrowerTransitive?uri=' + parentParameter + '&lang=' + that.getLanguageParameterForRequests())
                  searchsuggest_xhr.start().done((data, status, statusText) ->
                      # read options for select
                      select_items = []
                      item = (
                        text: $$('custom.data.type.finto.modal.form.dropdown.choose')
                        value: null
                      )
                      select_items.push item

                      data = data.narrowerTransitive

                      for key, suggestion of data
                        do(key) ->
                          label = suggestion.prefLabel
                          if ! label
                            label = $$('custom.data.type.finto.modal.form.dropdown.nolabelinlanguagefound')
                          if suggestion.uri != parentParameter
                            item = (
                              text: label
                              value: suggestion.uri
                            )
                            # only show tooltip, if configures in datamodel
                            if that.getCustomMaskSettings()?.use_dropdown_info_popup?.value
                              item.tooltip =
                                markdown: true
                                placement: 'nw'
                                content: (tooltip) ->
                                  # get jskos-details-data
                                  that.__getAdditionalTooltipInfo(data[key].uri, tooltip, extendedInfo_xhr)
                                  # loader, until details are xhred
                                  new CUI.Label(icon: "spinner", text: $$('custom.data.type.finto.modal.form.popup.loadingstring'))
                            select_items.push item

                      # if cdata is already set, choose correspondending option from select
                      if cdata?.conceptURI != ''
                        for givenOpt in select_items
                          if givenOpt.value != null
                            if givenOpt.value == cdata?.conceptURI
                              thisSelect.setValue(givenOpt.value)
                              thisSelect.setText(givenOpt.text)
                      thisSelect.enable()
                      dfr.resolve(select_items)
                  )
                  dfr.promise()
            name: 'finto_InlineSelect'
        }

        fields.push select
        if cdata.length == 0
          cdata = {}
        cdata_form = new CUI.Form
                data: cdata
                # dropdown changed!?
                onDataChanged: =>
                      element = cdata_form.getFieldsByName("finto_InlineSelect")[0]
                      cdata.conceptURI = element.getValue()
                      element.displayValue()
                      cdata.conceptName = element.getText()
                      cdata.conceptAncestors = null
                      if cdata.conceptURI != null
                        # download data from finto for fulltext etc.
                        allDataAPIPath = location.protocol + '//api.finto.fi/rest/v1/data?uri=' + encodeURIComponent(cdata.conceptURI) + '&format=application%2Fjson'

                        # XHR for basic information
                        dataEntry_xhr = new (CUI.XHR)(url: allDataAPIPath)
                        dataEntry_xhr.start().done((resultJSON, status, statusText) ->

                            # read only the needed part
                            for json in resultJSON.graph
                              if json.uri == cdata.conceptURI
                                resultJSON = json

                            databaseLanguages = that.getDatabaseLanguages()
                            frontendLanguages = that.getFrontendLanguages()
                            desiredLanguage = that.getLanguageParameterForRequests()

                            # save conceptName
                            cdata.conceptName = FINTOUtilities.getPrefLabelFromDataResult(resultJSON, desiredLanguage, frontendLanguages)
                            # save conceptURI
                            cdata.conceptURI = resultJSON.uri
                            # save conceptSource
                            cdata.conceptSource = voc
                            # save _fulltext
                            cdata._fulltext = FINTOUtilities.getFullTextFromJSONObject(resultJSON, databaseLanguages)
                            # save _standard
                            cdata._standard = FINTOUtilities.getStandardFromJSONObject(resultJSON, databaseLanguages)
                            # save geo (also in _standard)
                            geoJSON = FINTOUtilities.getGeoJSONFromFINTOJSON(resultJSON) 
                            if geoJSON
                              cdata.conceptGeoJSON = geoJSON
                            # save facet
                            cdata.facetTerm = FINTOUtilities.getFacetTermFromJSONObject(resultJSON, databaseLanguages)
                            # save frontendlanguage
                            cdata.frontendLanguage = that.getLanguageParameterForRequests()

                            if ! cdata?.conceptURI
                              cdata = {}
                            data[that.name(opts)] = cdata
                            data.lastsaved = Date.now()
                            CUI.Events.trigger
                                node: element
                                type: "editor-changed"
                        )

                fields: fields
        .start()
        cdata_form.getFieldsByName("finto_InlineSelect")[0].disable()

        cdata_form

  #######################################################################
  # show tooltip with loader and then additional info (for extended mode)
  __getAdditionalTooltipInfo: (uri, tooltip, extendedInfo_xhr, context = null) ->
    that = @

    if context
      that = context

    # abort eventually running request
    if extendedInfo_xhr.xhr != undefined
      extendedInfo_xhr.xhr.abort()

    # start new request to FINTO-API
    extendedInfo_xhr.xhr = new (CUI.XHR)(url: location.protocol + '//api.finto.fi/rest/v1/data?uri=' + uri + '&format=application%2Fjson')
    extendedInfo_xhr.xhr.start()
    .done((data, status, statusText) ->
      htmlContent = FINTOUtilities.getJSONPreview(that, data, decodeURIComponent(uri), that.getLanguageParameterForRequests(), that.getDatabaseLanguages(), that.getFrontendLanguages())
      tooltip.DOM.innerHTML = htmlContent
      tooltip.autoSize()
    )

    return

  #######################################################################
  # build treeview-Layout with treeview
  buildAndSetTreeviewLayout: (popover, layout, cdata, cdata_form, that, returnDfr = false, opts) ->
    # is this a call from expert-search? --> save in opts..
    if @?.callFromExpertSearch
      opts.callFromExpertSearch = @.callFromExpertSearch
    else
      opts.callFromExpertSearch = false

    # get vocparameter from dropdown, if available...
    popoverVocabularySelectTest = cdata_form.getFieldsByName("finto_PopoverVocabularySelect")[0]
    if popoverVocabularySelectTest?.getValue()
      vocParameter = popoverVocabularySelectTest.getValue()
    else
      # else get first voc from given voclist
      vocParameter = that.getActiveVocabularyName(cdata)
      vocParameter = vocParameter.replace /,/g, " "
      vocParameter = vocParameter.replace /\|/g, " "
      vocParameter = vocParameter.split(' ')
      vocParameter = vocParameter[0]

    treeview = new FINTO_ListViewTree(popover, layout, cdata, cdata_form, that, opts, vocParameter)

    # maybe deferred is wanted?
    if returnDfr == false
      treeview.getTopTreeView(vocParameter, 1)
    else
      treeviewDfr = treeview.getTopTreeView(vocParameter, 1)

    treeviewPane = new CUI.Pane
        class: "cui-pane finto_treeviewPane"
        center:
            content: [
                treeview.treeview
              ,
                cdata_form
            ]

    @popover.setContent(treeviewPane)

    # maybe deferred is wanted?
    if returnDfr == false
      return treeview
    else
      return treeviewDfr

  #######################################################################
  # show popover and fill it with the form-elements
  showEditPopover: (btn, data, cdata, layout, opts) ->
    that = @

    suggest_Menu
    cdata_form

    # init popover
    @popover = new CUI.Popover
      element: btn
      placement: "wn"
      class: "commonPlugin_Popover"
      pane:
        padded: true
        header_left: new CUI.Label(text: $$('custom.data.type.finto.modal.form.popup.choose'))
        header_right: new CUI.EmptyLabel
                        text: that.getVocabularyNameFromDatamodel(opts)
      onHide: =>
        # reset voc-dropdown
        delete cdata.finto_PopoverVocabularySelect
        vocDropdown = cdata_form.getFieldsByName("finto_PopoverVocabularySelect")[0]
        if vocDropdown
          vocDropdown.reload()
        # reset searchbar
        searchbar = cdata_form.getFieldsByName("searchbarInput")[0]
        if searchbar
          searchbar.reset()
          searchbar.setValue('')

    # init xhr-object to abort running xhrs
    searchsuggest_xhr = { "xhr" : undefined }
    cdata_form = new CUI.Form
      class: "fintoFormWithPadding"
      data: cdata
      fields: that.__getEditorFields(cdata)
      onDataChanged: (data, elem) =>
        that.__updateResult(cdata, layout, opts)
        # update tree, if voc changed
        if elem.opts.name == 'finto_PopoverVocabularySelect' && that.renderPopupAsTreeview()
          @buildAndSetTreeviewLayout(@popover, layout, cdata, cdata_form, that, false, opts)
        that.__setEditorFieldStatus(cdata, layout)
        if (elem.opts.name == 'searchbarInput' || elem.opts.name == 'finto_PopoverVocabularySelect'  || elem.opts.name == 'finto_countSuggestions') && ! that.renderPopupAsTreeview()
          that.__updateSuggestionsMenu(cdata, cdata_form, data.searchbarInput, elem, suggest_Menu, searchsuggest_xhr, layout, opts)
    .start()

    # init suggestmenu
    suggest_Menu = cdata_form.getFieldsByName("searchbarInput")[0]
    if suggest_Menu
      suggest_Menu= new CUI.Menu
          element : cdata_form.getFieldsByName("searchbarInput")[0]
          use_element_width_as_min_width: true

    # treeview?
    if that.renderPopupAsTreeview()
      # do search-request for all the top-entrys of vocabulary
      @buildAndSetTreeviewLayout(@popover, layout, cdata, cdata_form, that, false, opts)
    # else not treeview, but default search-popup
    else
      defaultPane = new CUI.Pane
          class: "cui-pane"
          center:
              content: [
                  cdata_form
              ]

      @popover.setContent(defaultPane)

    @popover.show()

  #######################################################################
  # create form (POPOVER)
  #######################################################################
  __getEditorFields: (cdata) ->
    that = @
    fields = []
    # dropdown for vocabulary-selection if more then 1 voc
    splittedVocs = that.getVocabularyNameFromDatamodel()
    splittedVocs = splittedVocs.split(' ')
    if splittedVocs.length > 1 or splittedVocs == '*'
      select =  {
          type: CUI.Select
          undo_and_changed_support: false
          name: 'finto_PopoverVocabularySelect'
          form:
            label: $$("custom.data.type.finto.modal.form.dropdown.selectvocabularyLabel")
          # read select-items from finto-api
          options: (thisSelect) =>
            dfr = new CUI.Deferred()
            values = []
            # start new request and download all vocabulary-informations
            searchsuggest_xhr = new (CUI.XHR)(url: location.protocol + '//api.finto.fi/rest/v1/vocabularies?lang=' + that.getLanguageParameterForRequests())
            searchsuggest_xhr.start().done((data, status, statusText) ->
                # enter the vocs to select in same order as in given in datamodell, because result from api is more or less random
                select_items = []
                # allow to choose all vocs only, if not treeview
                if ! that.renderPopupAsTreeview()
                  item = (
                    text: $$('custom.data.type.finto.modal.form.dropdown.choosefromvocall')
                    value: that.getVocabularyNameFromDatamodel()
                  )
                  select_items.push item
                for splittedVoc, splittedVocKey in splittedVocs
                  for entry, key in data.vocabularies
                    # add vocs to select
                    if splittedVoc == entry.id
                      item = (
                        text: entry.title
                        value: entry.id
                      )
                      select_items.push item

                thisSelect.enable()
                dfr.resolve(select_items)
            )
            dfr.promise()
      }
      fields.push select

    # maxhits
    maxhits = {
        type: CUI.Select
        class: "commonPlugin_Select"
        name: 'finto_countSuggestions'
        undo_and_changed_support: false
        form:
            label: $$('custom.data.type.finto.modal.form.text.count')
        options: [
          (
              value: 10
              text: '10 ' + $$('custom.data.type.finto.modal.form.text.count_short')
          )
          (
              value: 20
              text: '20 ' + $$('custom.data.type.finto.modal.form.text.count_short')
          )
          (
              value: 50
              text: '50 ' + $$('custom.data.type.finto.modal.form.text.count_short')
          )
          (
              value: 100
              text: '100 ' + $$('custom.data.type.finto.modal.form.text.count_short')
          )
        ]
      }

    # not in popover-mode
    if ! that.renderPopupAsTreeview()
      fields.push maxhits

    # searchfield (autocomplete)
    option =  {
          type: CUI.Input
          class: "commonPlugin_Input"
          undo_and_changed_support: false
          form:
              label: $$("custom.data.type.finto.modal.form.text.searchbar")
          placeholder: $$("custom.data.type.finto.modal.form.text.searchbar.placeholder")
          name: "searchbarInput"
        }
    # not in popover-mode
    if ! that.renderPopupAsTreeview()
      fields.push option

    fields


  #######################################################################
  # renders the "resultmask" (outside popover)
  __renderButtonByData: (cdata) ->
    that = @
    # when status is empty or invalid --> message

    switch @getDataStatus(cdata)
      when "empty"
        return new CUI.EmptyLabel(text: $$("custom.data.type.finto.edit.no_finto")).DOM
      when "invalid"
        return new CUI.EmptyLabel(text: $$("custom.data.type.finto.edit.no_valid_finto")).DOM

    extendedInfo_xhr = { "xhr" : undefined }

    # show label of button in active frontendlanguage, if possible, else fallback to conceptName
    label = cdata.conceptName
    if cdata?._standard?.l10ntext
      if cdata._standard?.l10ntext[ez5.loca.getLanguage()]
        label = cdata._standard?.l10ntext[ez5.loca.getLanguage()]

    # output Button with Name of picked finto-Entry and URI
    encodedURI = encodeURIComponent(cdata.conceptURI)
    new CUI.HorizontalLayout
      maximize: true
      left:
        content:
          new CUI.Label
            centered: false
            text: label
      center:
        content:
          new CUI.ButtonHref
            name: "outputButtonHref"
            class: "pluginResultButton"
            appearance: "link"
            size: "normal"
            href: cdata.conceptURI
            target: "_blank"
            class: "cdt_finto_smallMarginTop"
            tooltip:
              markdown: true
              placement: 'nw'
              content: (tooltip) ->
                # get details-data
                that.__getAdditionalTooltipInfo(encodedURI, tooltip, extendedInfo_xhr)
                # loader, until details are xhred
                new CUI.Label(icon: "spinner", text: $$('custom.data.type.finto.modal.form.popup.loadingstring'))
      right: null
    .DOM


  #######################################################################
  # zeige die gewählten Optionen im Datenmodell unter dem Button an
  getCustomDataOptionsInDatamodelInfo: (custom_settings) ->
    tags = []

    if custom_settings.vocabulary_notation?.value
      tags.push $$("custom.data.type.finto.name") + ': ' + custom_settings.vocabulary_notation.value
    else
      tags.push $$("custom.data.type.finto.setting.schema.no_vocabulary_notation")

    if custom_settings.vocabulary_parent?.value
      tags.push $$("custom.data.type.finto.parent.name") + ': ' + custom_settings.vocabulary_parent.value
    else
      tags.push $$("custom.data.type.finto.setting.schema.vocabulary_parent")

    if custom_settings.lang?.value
      tags.push $$("custom.data.type.finto.language.name") + ': ' + custom_settings.lang.value
    else
      tags.push $$("custom.data.type.finto.setting.schema.lang")

    tags


CustomDataType.register(CustomDataTypeFINTO)
