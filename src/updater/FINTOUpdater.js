const fs = require('fs')
const https = require('https')
const fetch = (...args) => import('node-fetch').then(({
  default: fetch
}) => fetch(...args));

let databaseLanguages = [];
let frontendLanguages = [];
let defaultLanguage = 'fi';

let info = {}

let access_token = '';

if (process.argv.length >= 3) {
    info = JSON.parse(process.argv[2])
}

function hasChanges(objectOne, objectTwo) {
  var len;
  const ref = ["conceptName", "conceptURI", "conceptSource", "_standard", "_fulltext", "conceptAncestors", "frontendLanguage", "conceptNameChosenByHand"];
  for (let i = 0, len = ref.length; i < len; i++) {
    let key = ref[i];
    if (!FINTOUtilities.isEqual(objectOne[key], objectTwo[key])) {
      return true;
    }
  }
  return false;
}

function getConfigFromAPI() {
  return new Promise((resolve, reject) => {
          var url = 'http://fylr.localhost:8081/api/v1/config?access_token=' + access_token
          fetch(url, {
                          headers: {
                                  'Accept': 'application/json'
                          },
                  })
                  .then(response => {
                          if (response.ok) {
                                  resolve(response.json());
                          } else {
                                  console.error("FINTO-Updater: Fehler bei der Anfrage an /config ");
                          }
                  })
                  .catch(error => {
                          console.error(error);
                          console.error("FINTO-Updater: Fehler bei der Anfrage an /config");
                  });
  });
}

main = (payload) => {
  switch (payload.action) {
    case "start_update":
      outputData({
        "state": {
          "personal": 2
        },
        "log": ["started logging"]
      })
      break
    case "update":

      ////////////////////////////////////////////////////////////////////////////
      // run finto-api-call for every given uri
      ////////////////////////////////////////////////////////////////////////////

      // collect URIs
      let URIList = [];
      for (var i = 0; i < payload.objects.length; i++) {
        if(payload.objects[i].data.conceptURI && payload.objects[i].data.conceptSource) {
          URIList.push(payload.objects[i].data.conceptURI + '@@@' + payload.objects[i].data.conceptSource);
        }
      }
      // unique urilist
      URIList = [...new Set(URIList)]

      let requestUrls = [];
      let requests = [];

      URIList.forEach((info) => {
        let parts = info.split('@@@');
        const uri = parts[0];
        const vocNotation = parts[1];
        let dataRequestUrl = 'https://api.finto.fi/rest/v1/data?uri=' + encodeURIComponent(uri) + '&format=application%2Fjson';
        let hierarchieRequestUrl = 'https://api.finto.fi/rest/v1/' + vocNotation + '/hierarchy?uri=' + encodeURIComponent(uri) + '&lang=fi&format=application%2Fjson';
        let dataRequest = fetch(dataRequestUrl);
        let hierarchieRequest = fetch(hierarchieRequestUrl);
        requests.push({
          url: dataRequestUrl,
          uri: uri,
          request: dataRequest
        });
        requests.push({
          url: hierarchieRequestUrl,
          uri: uri,
          request: hierarchieRequest
        });
        requestUrls.push(dataRequest);
        requestUrls.push(hierarchieRequest);
      });

      Promise.all(requestUrls).then(function(responses) {
        let results = [];
        // Get a JSON object from each of the responses
        responses.forEach((response, index) => {
          let url = requests[index].url;
          let uri = requests[index].uri;
          let requestType = (url.includes('hierarchy?uri')) ? 'broader' : 'data';
          let result = {
            url: url,
            requestType: requestType,
            uri: uri,
            data: null,
            error: null
          };
          if (response.ok) {
            result.data = response.json();
          } else {
            result.error = "Error fetching data from " + url + ": " + response.status + " " + response.statusText;
          }
          results.push(result);
        });
        return Promise.all(results.map(result => result.data));
      }).then(function(data) {
        let results = [];
        data.forEach((data, index) => {
          let url = requests[index].url;
          let uri = requests[index].uri;
          let requestType = (url.includes('hierarchy?uri')) ? 'broader' : 'data';
          let result = {
            url: url,
            requestType: requestType,
            uri: uri,
            data: data,
            error: null
          };
          if (data instanceof Error) {
            result.error = "Error parsing data from " + url + ": " + data.message;
          }
          results.push(result);
        });

        // build cdata from all api-request-results
        let cdataList = [];
        payload.objects.forEach((result, index) => {
          let originalCdata = payload.objects[index].data;
          let newCdata = {};
          let originalURI = originalCdata.conceptURI;

          const matchingRecordData = results.find(record => record.uri === originalURI && record.requestType === 'data');
          const matchingRecordHierarchy = results.find(record => record.uri === originalURI && record.requestType === 'broader');

          if (matchingRecordData) {
            // rematch uri, because maybe uri changed / rewrites ..
            let uri = matchingRecordData.uri;

            ///////////////////////////////////////////////////////
            // conceptName, conceptURI, _standard, _fulltext, facet, frontendLanguage
            if (matchingRecordData.requestType == 'data') {
              resultJSON = false;
              // read only the needed part
              matchingRecordData.data.graph.forEach(function(json) {
                if (json.uri == uri) {
                  resultJSON = json;
                }
              });
              if (resultJSON) {
                // get desired language for conceptName. This is frontendlanguage from original data or fallback
                let frontendLanguage = defaultLanguage;
                if (originalCdata.frontendLanguage) {
                    if (originalCdata.frontendLanguage.length == 2) {
                      frontendLanguage = originalCdata.frontendLanguage;
                    }
                }
                // save conceptName
                newCdata.conceptName = FINTOUtilities.getPrefLabelFromDataResult(resultJSON, databaseLanguages, frontendLanguage)
                // save conceptURI
                newCdata.conceptURI = uri;
                // save conceptSource
                newCdata.conceptSource = originalCdata.conceptSource;
                // save _fulltext
                newCdata._fulltext = FINTOUtilities.getFullTextFromJSONObject(resultJSON, databaseLanguages);
                // save _standard
                newCdata._standard = FINTOUtilities.getStandardFromJSONObject(resultJSON, databaseLanguages);
                // save geo (alsonin _standard)
                geoJSON = FINTOUtilities.getGeoJSONFromFINTOJSON(resultJSON);
                if(geoJSON) {
                  newCdata.conceptGeoJSON = geoJSON;
                }
                // save facet
                newCdata.facetTerm = FINTOUtilities.getFacetTermFromJSONObject(resultJSON, databaseLanguages);
                // save frontend language (same as given)
                newCdata.frontendLanguage = originalCdata.frontendLanguage;
              }
            }

            ///////////////////////////////////////////////////////
            // ancestors
            newCdata.conceptAncestors = [];
            if(originalCdata.conceptAncestors) {
              newCdata.conceptAncestors = originalCdata.conceptAncestors;
            }
            if (matchingRecordHierarchy.requestType == 'broader') {
              if(matchingRecordHierarchy.data != null) {
                if(matchingRecordHierarchy.data.broaderTransitive) {
                  newCdata.conceptAncestors = [];
                  let hierarchyJSON = matchingRecordHierarchy.data.broaderTransitive
                  // save ancestors if treeview, add ancestors
                  
                  for (let i = 1; i < Object.keys(hierarchyJSON).length; i++) {
                    for (let [hierarchyKey, hierarchyValue] of Object.entries(hierarchyJSON)) {
                      if (hierarchyKey !== uri) {
                        // check if hierarchy-entry contains the actual record in narrowers
                        // or if the narrower of the hierarchy-entry contains one of the already set ancestors
                        let isnarrower = false;
                        if (hierarchyValue.narrower) {
                          if (!Array.isArray(hierarchyValue.narrower)) {
                            hierarchyValue.narrower = [hierarchyValue.narrower];
                          }
                          for (let narrower of hierarchyValue.narrower) {
                            if (narrower.uri === uri) {
                              if (!newCdata.conceptAncestors.includes(hierarchyValue.uri)) {
                                newCdata.conceptAncestors.push(hierarchyValue.uri);
                              }
                            } else if (newCdata.conceptAncestors.includes(narrower.uri)) {
                              if (!newCdata.conceptAncestors.includes(hierarchyValue.uri)) {
                                newCdata.conceptAncestors.push(hierarchyValue.uri);
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
                // add own uri to ancestor-uris
                newCdata.conceptAncestors.push(uri);
                // merge ancestors to string
                newCdata.conceptAncestors = newCdata.conceptAncestors.join(' ');
              }
            }
            if (hasChanges(payload.objects[index].data, newCdata)) {
              payload.objects[index].data = newCdata;
            } else {}
            
          } else {
            console.error('No matching record found');
          }
        });
        outputData({
          "payload": payload.objects,
          "log": [payload.objects.length + " objects in payload"]
        });
      });
      // send data back for update
      break;
    case "end_update":
      outputData({
        "state": {
          "theend": 2,
          "log": ["done logging"]
        }
      });
      break;
    default:
      outputErr("Unsupported action " + payload.action);
  }
}

outputData = (data) => {
  out = {
    "status_code": 200,
    "body": data
  }
  process.stdout.write(JSON.stringify(out))
  process.exit(0);
}

outputErr = (err2) => {
  let err = {
    "status_code": 400,
    "body": {
      "error": err2.toString()
    }
  }
  console.error(JSON.stringify(err))
  process.stdout.write(JSON.stringify(err))
  process.exit(0);
}

(() => {

  let data = ""

  process.stdin.setEncoding('utf8');

  access_token = info && info.plugin_user_access_token;
    
  if(access_token) {

    ////////////////////////////////////////////////////////////////////////////
    // get config and read the languages
    ////////////////////////////////////////////////////////////////////////////

    getConfigFromAPI().then(config => {
      databaseLanguages = config.system.config.languages.database;
      databaseLanguages = databaseLanguages.map((value, key, array) => {
          return value.value;
      });

      frontendLanguages = config.system.config.languages.frontend;

      const testDefaultLanguageConfig = config.plugin['custom-data-type-finto'].config.update_interval_finto.default_language;
      if (testDefaultLanguageConfig) {
          if (testDefaultLanguageConfig.length == 2) {
              defaultLanguage = testDefaultLanguageConfig;
          }
      }

      ////////////////////////////////////////////////////////////////////////////
      // availabilityCheck for finto-api
      ////////////////////////////////////////////////////////////////////////////
      https.get('https://api.finto.fi/rest/v1/vocabularies?lang=fi', res => {
        let testData = [];
        res.on('data', chunk => {
          testData.push(chunk);
        });
        res.on('end', () => {
          const vocabs = JSON.parse(Buffer.concat(testData).toString());
          if (vocabs.vocabularies) {
            ////////////////////////////////////////////////////////////////////////////
            // test successfull --> continue with custom-data-type-update
            ////////////////////////////////////////////////////////////////////////////
            process.stdin.on('readable', () => {
              let chunk;
              while ((chunk = process.stdin.read()) !== null) {
                data = data + chunk
              }
            });
            process.stdin.on('end', () => {
              ///////////////////////////////////////
              // continue with update-routine
              ///////////////////////////////////////
              try {
                let payload = JSON.parse(data)
                main(payload)
              } catch (error) {
                console.error("caught error", error)
                outputErr(error)
              }
            });
          } else {
            console.error('Error while interpreting data from api.finto.fi: ', err.message);
          }
        });
      }).on('error', err => {
        console.error('Error while receiving data from api.finto.fi: ', err.message);
      });
    }).catch(error => {
      console.error('Es gab einen Fehler beim Laden der Konfiguration:', error);
    }); 
  }
  else {
    console.error("kein Accesstoken gefunden");
  }
})();