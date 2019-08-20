var AWSXray = require('aws-xray-sdk');
// AWSXray.setDaemonAddress('127.0.0.1:2000');
AWSXray.captureHTTPsGlobal(require('http'));
AWSXray.capturePromise();
const axios = require('axios');
var mysql = AWSXray.captureMySQL(require('mysql'));
var express = require("express");
var app = express();
var bodyParser = require("body-parser");
// AWSXRay.setDaemonAddress(process.env.);
// AWSXRay.middleware.setSamplingRules(rules);
app.use(AWSXray.express.openSegment('CurrencyConvertTrace'));
app.use(bodyParser.urlencoded({extended: true}));
app.set("view engine", "ejs");
var conn = mysql.createConnection({
  host: process.env.RDS_ENDPOINT,
  user: "root",
  password: "judaspriest",
  database: "currconv"
});

app.get("/", (req, res) => {
  res.render("index")
});
// CREATE TABLE currtable ( fromCurr varchar(20), toCurr varchar(20), value float );
// curl -L https://api.exchangeratesapi.io/latest?symbols=USD,GBP
// {"rates":{"USD":1.1194,"GBP":0.92615},"base":"EUR","date":"2019-08-12"

app.post("/conv-rate", (req, res) => {
  var querStr = req.body.fromCurr + ',' + req.body.toCurr
  // var uRL = 'http://free.currencyconverterapi.com/api/v5/convert?q=' + querStr + '&compact=y';
  var uRL = 'https://api.exchangeratesapi.io/latest?symbols=' + querStr;
  axios.get(uRL)
  .then(response => {
    var seg = AWSXray.getSegment();
    seg.addAnnotation("queryMade", "INSERT");
    var nn = response.data;
    console.log(nn);
    var ressy = {};
    // ressy.theValue = parseFloat(nn[querStr].val);
    ressy.fromCurr = querStr.split(",")[0];
    ressy.toCurr = querStr.split(",")[1];
    // ressy.toCurr = Object.keys(nn)[0].split("_")[1];
    // ressy.theDate = new Date().toISOString();
    ressy.theDate = nn.date
    ressy.theValue = parseFloat(nn.rates[querStr.split(",")[1]]/nn.rates[querStr.split(",")[0]])

    console.log(ressy);
    conn.query('INSERT INTO currtable SET ?', ressy, (err, resul, fields) => {
      if(err) console.log(err);
      else console.log(resul);
    });
    // conn.end();
    res.render("show", {theResult: ressy});
  })
  .catch(error => {
    console.log(error);
  });
});
app.listen(8000, "0.0.0.0", function() {
  console.log("Listening on port 8000 .....");
});
