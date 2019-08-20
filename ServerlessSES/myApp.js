var AWSXRay = require('aws-xray-sdk');
var AWS = AWSXRay.captureAWS(require('aws-sdk'));
// var AWS = require('aws-sdk');
var ses = new AWS.SES();

var RECEIVER = 'naren_black@yahoo.co.in';
var SENDER = 'naren.nath7@gmail.com';
var headHtml = '<h1>The email has been'
var tailHtml = '</h1>'


exports.handler = function (event, context, callback) {
    console.log('Received event:', event);
    sendEmail(event, function (err, data) {
        if (err) {
          var theMess = headHtml + ' not sent to ' + RECEIVER + " because of " + err + tailHtml
          console.log("Unable to send email to: " + RECEIVER + " because of " + err);
          var response = {
           "isBase64Encoded": false,
           "headers": { 'Content-Type': 'text/html', 'Access-Control-Allow-Origin': '*'},
           "statusCode": 200,
           "body": theMess
           };
          callback(err, response.body)
        } else {
          theMess = headHtml + " successfully sent to: " + RECEIVER + tailHtml
          var response = {
           "isBase64Encoded": false,
           "headers": { 'Content-Type': 'text/html', 'Access-Control-Allow-Origin': '*'},
           "statusCode": 200,
           "body": theMess
           };
          console.log("Successfully sent email to: " + RECEIVER)
          callback(null, response.body)
        }
    });
};

function sendEmail (event, done) {
    var params = {
        Destination: {
            ToAddresses: [
                RECEIVER
            ]
        },
        Message: {
            Body: {
                Text: {
                    Data: 'name: ' + event.name + '\nphone: ' + event.phone + '\nemail: ' + event.email + '\ndesc: ' + event.desc,
                    Charset: 'UTF-8'
                }
            },
            Subject: {
                Data: 'Website Referral Form: ' + event.name,
                Charset: 'UTF-8'
            }
        },
        Source: SENDER
    };
    ses.sendEmail(params, done);
}
