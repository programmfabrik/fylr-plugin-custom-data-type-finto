const fs = require('fs')

const https = require('https')

const fetch = (...args) => import('node-fetch').then(({
  default: fetch
}) => fetch(...args));

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
        URIList.push(payload.objects[i].data.conceptURI);
      }
      URIList = [...new Set(URIList)]

      let requestUrls = [];
      URIList.forEach((uri) => {
        let dataRequestUrl = 'https://api.finto.fi/rest/v1/data?uri=' + encodeURIComponent(uri) + '&format=application%2Fjson';
        let hierarchieRequestUrl = 'https://api.finto.fi/rest/v1/' + FINTOUtilities.getVocNotationFromURI(uri) + '/hierarchy?uri=' + encodeURIComponent(uri) + '&lang=fi&format=application%2Fjson'; //language does not matter here, it is abount the uri's
        requestUrls.push(fetch(dataRequestUrl));
        requestUrls.push(fetch(hierarchieRequestUrl));
      });

      Promise.all(requestUrls).then(function(responses) {
        // Get a JSON object from each of the responses
        console.error("responses");
        console.error(responses);
        return Promise.all(responses.map(function(response) {
          return response.json();
        }));
      }).then(function(data) {
        // process all the responses
        console.error("data");
        console.error(data);
      }).catch(function(error) {
        // if there's an error, log it
        console.error(error);
      });

      return;

      //console.error("data has length", data.length)
      //console.error(payload)

      for (var i = 0; i < payload.objects.length; i++) {

        // increment version. this is checked by apitest test/api/db/custom_data_type_updater
        //payload.objects[i].data.version++
        // console.error("data", i, payload.objects[i].data.numberfield)
      }
      outputData({
        "payload": payload.objects,
        "log": [payload.objects.length + " objects in payload"]
      })
      // send data back for update
      break
    case "end_update":
      outputData({
        "state": {
          "theend": 2,
          "log": ["done logging"]
        }
      })
      break
    default:
      outputErr("Unsupported action " + payload.action)
  }
}

outputData = (data) => {
  out = {
    "status_code": 200,
    "body": data
  }
  // await dv.send(out)
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
  // we exit with 0 as this is a "user space" error and
  // this error is sent back thru a regular body
  process.exit(0);
}

(() => {
  run_main = () => {
    try {
      let payload = JSON.parse(data)
      main(payload)
    } catch (error) {
      console.error("caught error", error)
      outputErr(error)
    }
  }

  let data = ""

  process.stdin.setEncoding('utf8');

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
          run_main()
        });
      } else {
        console.error('Error while interpreting data from api.finto.fi: ', err.message);
      }
    });
  }).on('error', err => {
    console.error('Error while receiving data from api.finto.fi: ', err.message);
  });
})();