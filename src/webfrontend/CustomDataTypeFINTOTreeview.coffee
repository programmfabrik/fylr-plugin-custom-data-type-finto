##################################################################################
#  1. Class for use of ListViewTree
#   - uses the FINTO-API as source for the treeview
#
#  2. extends CUI.ListViewTreeNode
#   - offers preview and selection of FINTO-records for treeview-nodes
##################################################################################

class FINTO_ListViewTree

    #############################################################################
    # construct
    #############################################################################
    constructor: (@popover = null, @editor_layout = null, @cdata = null, @cdata_form = null, @context = null, @finto_opts = {}, @vocParameter = 'yso') ->

        options =
          class: "fintoPlugin_Treeview"
          cols: ["maximize", "auto"]
          fixedRows: 0
          fixedCols: 0
          no_hierarchy : false

        that = @

        treeview = new CUI.ListViewTree(options)
        treeview.render()
        treeview.root.open()

        # append loader-row
        row = new CUI.ListViewRow()
        column = new CUI.ListViewColumn(
          colspan: 2
          element: new CUI.Label(icon: "spinner", appearance: "title",text: $$("custom.data.type.finto.modal.form.popup.loadingstringtreeview"))
        )
        row.addColumn(column)
        treeview.appendRow(row)
        treeview.root.open()

        @treeview = treeview
        @treeview

    #############################################################################
    # get top hierarchy
    #############################################################################
    getTopTreeView: (vocName) ->

        dfr = new CUI.Deferred()

        that = @
        topTree_xhr = { "xhr" : undefined }

        # start new request to FINTO-API
        url = location.protocol + '//api.finto.fi/rest/v1/' + vocName + '/topConcepts?lang=' + CustomDataTypeFINTO.prototype.getLanguageParameterForRequests()

        topTree_xhr.xhr = new (CUI.XHR)(url: url)
        topTree_xhr.xhr.start().done((data, status, statusText) ->
          # remove loading row (if there is one)
          if that.treeview.getRow(0)
            that.treeview.removeRow(0)

          # add lines from request
          for json, key in data.topconcepts
            prefLabel = json.label

            # narrower?
            if json.hasChildren == true
              hasNarrowers = true
            else
              hasNarrowers = false

            newNode = new FINTO_ListViewTreeNode
                selectable: false
                prefLabel: prefLabel
                uri: json.uri
                hasNarrowers: hasNarrowers
                popover: that.popover
                cdata: that.cdata
                cdata_form: that.cdata_form
                guideTerm: FINTO_ListViewTreeNode.prototype.isGuideTerm(json)
                context: that.context
                vocParameter: that.vocParameter
                finto_opts: that.finto_opts
                editor_layout: that.editor_layout

            that.treeview.addNode(newNode)
          # refresh popup, because its content has changed (new height etc)
          CUI.Events.trigger
            node: that.popover
            type: "content-resize"
          dfr.resolve()
          dfr.promise()
        )

        dfr


##############################################################################
# custom tree-view-node
##############################################################################
class FINTO_ListViewTreeNode extends CUI.ListViewTreeNode

    prefLabel = ''
    uri = ''

    initOpts: ->
       super()

       @addOpts
          prefLabel:
             check: String
          uri:
             check: String
          vocParameter:
             check: String
          children:
             check: Array
          guideTerm:
             check: Boolean
             default: false
          hasNarrowers:
             check: Boolean
             default: false
          popover:
             check: CUI.Popover
          cdata:
             check: "PlainObject"
             default: {}
          cdata_form:
             check: CUI.Form
          context:
             check: CustomDataTypeFINTO
          finto_opts:
             check: "PlainObject"
             default: {}
          editor_layout:
             check: CUI.HorizontalLayout

    readOpts: ->
       super()


    #########################################
    # function isGuideTerm (always false, but this is for future)
    isGuideTerm: (json) =>
      return false


    #########################################
    # function getChildren
    getChildren: =>
        that = @
        dfr = new CUI.Deferred()
        children = []

        # start new request to FINTO-API
        url = location.protocol + '//api.finto.fi/rest/v1/' + @_vocParameter + '/children?uri=' + @_uri + '&lang=' + CustomDataTypeFINTO.prototype.getLanguageParameterForRequests()
        getChildren_xhr ={ "xhr" : undefined }
        getChildren_xhr.xhr = new (CUI.XHR)(url: url)
        getChildren_xhr.xhr.start().done((data, status, statusText) ->
          data = data.narrower
          for json, key in data
            prefLabel = json.prefLabel

            # narrowers?
            if json.hasChildren == true
              hasNarrowers = true
            else
              hasNarrowers = false

            newNode = new FINTO_ListViewTreeNode
                selectable: false
                prefLabel: prefLabel
                uri: json.uri
                vocParameter: that._vocParameter
                hasNarrowers: hasNarrowers
                popover: that._popover
                cdata: that._cdata
                cdata_form: that._cdata_form
                guideTerm: that.isGuideTerm(json)
                context: that._context
                finto_opts: that._finto_opts
                editor_layout: that._editor_layout
            children.push(newNode)
          dfr.resolve(children)
        )

        dfr.promise()

    #########################################
    # function isLeaf
    isLeaf: =>
        if @opts.hasNarrowers == true
            return false
        else
          return true

    #########################################
    # function renderContent
    renderContent: =>
        that = @
        extendedInfo_xhr = { "xhr" : undefined }
        d = CUI.dom.div()

        buttons = []

        # '+'-Button
        icon = 'fa-plus-circle'
        tooltipText = $$('custom.data.type.finto.modal.form.popup.add_choose')
        if that._guideTerm
          icon = 'fa-sitemap'
          tooltipText = $$('custom.data.type.finto.modal.form.popup.add_sitemap')

        plusButton =  new CUI.Button
                            text: ""
                            icon_left: new CUI.Icon(class: icon)
                            active: false
                            group: "default"
                            tooltip:
                              text: tooltipText
                            onClick: =>
                              # load the record itself and also the hierarchie of the record
                              allDataAPIPath = location.protocol + '//api.finto.fi/rest/v1/data?uri=' + that._uri + '&format=application%2Fjson'

                              # XHR for basic information
                              dataEntry_xhr = new (CUI.XHR)(url: allDataAPIPath)
                              dataEntry_xhr.start().done((resultJSON, status, statusText) ->

                                # xhr for hierarchy-informations to fill "conceptAncestors"
                                allHierarchyAPIPath = location.protocol + '//api.finto.fi/rest/v1/' + FINTOUtilities.getVocNotationFromURI(that._uri) + '/hierarchy?uri=' + that._uri + '&lang=' + CustomDataTypeFINTO.prototype.getLanguageParameterForRequests() + '&format=application%2Fjson'
                                dataHierarchy_xhr = new (CUI.XHR)(url: allHierarchyAPIPath)
                                dataHierarchy_xhr.start().done((hierarchyJSON, status, statusText) ->

                                  hierarchyJSON = hierarchyJSON.broaderTransitive

                                  # read only the needed part
                                  for json in resultJSON.graph
                                    if json.uri == that._uri
                                      resultJSON = json

                                  # is user allowed to choose label manually from list and not in expert-search?!
                                  if that._context?.FieldSchema?.custom_settings?.allow_label_choice?.value == true && that._finto_opts?.mode == 'editor'
                                    CustomDataTypeFINTO.prototype.__chooseLabelManually(that._cdata, that._editor_layout, resultJSON, that._editor_layout, that._finto_opts)

                                  databaseLanguages = ez5.loca.getLanguageControl().getLanguages()

                                  databaseLanguages = ez5.loca.getLanguageControl().getLanguages()
                                  frontendLanguages = ez5.session.getConfigFrontendLanguages()
                                  desiredLanguage = CustomDataTypeFINTO.prototype.getLanguageParameterForRequests()

                                  # save conceptName
                                  that.conceptName = FINTOUtilities.getPrefLabelFromDataResult(resultJSON, desiredLanguage, frontendLanguages)
                                  # save conceptURI
                                  that._cdata.conceptURI = resultJSON.uri
                                  # save conceptSource
                                  that._cdata.conceptSource = FINTOUtilities.getVocNotationFromURI(resultJSON.uri)
                                  # save _fulltext
                                  that._cdata._fulltext = FINTOUtilities.getFullTextFromJSONObject(resultJSON, databaseLanguages)
                                  # save _standard
                                  that._cdata._standard = FINTOUtilities.getStandardFromJSONObject(resultJSON, databaseLanguages)
                                  # save facet
                                  that._cdata.facetTerm = FINTOUtilities.getFacetTermFromJSONObject(resultJSON, databaseLanguages)
                                  # save frontendlanguage
                                  that._cdata.frontendLanguage = CustomDataTypeFINTO.prototype.getLanguageParameterForRequests()

                                  # save ancestors if treeview, add ancestors
                                  that._cdata.conceptAncestors = []
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
                                              if not that._cdata.conceptAncestors.includes(hierarchyValue.uri)
                                                that._cdata.conceptAncestors.push hierarchyValue.uri
                                            else if that._cdata.conceptAncestors.includes narrower.uri
                                              if not that._cdata.conceptAncestors.includes(hierarchyValue.uri)
                                                that._cdata.conceptAncestors.push hierarchyValue.uri

                                  # add own uri to ancestor-uris
                                  that._cdata.conceptAncestors.push resultJSON.uri
                                  # merge ancestors to string
                                  that._cdata.conceptAncestors = that._cdata.conceptAncestors.join(' ')

                                  # is this from exact search and user has to choose exact-search-mode?!
                                  if that._finto_opts?.callFromExpertSearch == true
                                    CustomDataTypeFINTO.prototype.__chooseExpertHierarchicalSearchMode(that._cdata, that._editor_layout, resultJSON, that._editor_layout, that._finto_opts)

                                  # update form
                                  CustomDataTypeFINTO.prototype.__updateResult(that._cdata, that._editor_layout, that._finto_opts)
                                  # hide popover
                                  that._popover.hide()
                                )
                              )


        # add '+'-Button, if not guideterm
        plusButton.setEnabled(!that._guideTerm)

        buttons.push(plusButton)

        # infoIcon-Button
        infoButton = new CUI.Button
                        text: ""
                        icon_left: new CUI.Icon(class: "fa-info-circle")
                        active: false
                        group: "default"
                        tooltip:
                          markdown: true
                          placement: "e"
                          content: (tooltip) ->
                            # show infopopup
                            CustomDataTypeFINTO.prototype.__getAdditionalTooltipInfo(that._uri, tooltip, extendedInfo_xhr, that._context)
                            new CUI.Label(icon: "spinner", text: $$('custom.data.type.finto.modal.form.popup.loadingstring'))
        buttons.push(infoButton)

        # button-bar for each row
        buttonBar = new CUI.Buttonbar
                          buttons: buttons

        CUI.dom.append(d, CUI.dom.append(CUI.dom.div(), buttonBar.DOM))

        @addColumn(new CUI.ListViewColumn(element: d, colspan: 1))

        CUI.Events.trigger
          node: that._popover
          type: "content-resize"

        new CUI.Label(text: @_prefLabel)
