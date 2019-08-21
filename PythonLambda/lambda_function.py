import boto3
import os
from datetime import datetime
from aws_xray_sdk.core import xray_recorder
from aws_xray_sdk.core import patch_all
import requests
# patch(['boto3'])
patch_all()

def handler(event, context):
    s3 = boto3.client('s3')
    subsegment = xray_recorder.begin_subsegment('S3Again')
    # seg = xray_recorder.current_subsegment()
    subsegment.put_annotation('TestKey', 'testValueNarUsed')
    res2 = s3.get_bucket_policy(Bucket='narenwebsitebalti')
    print res2
    print "-------------------------"
    xray_recorder.end_subsegment()
    getJoke()
    return "Finished getting the bucket policy..."

@xray_recorder.capture('TestName')
def getJoke():
    subSeg = xray_recorder.current_subsegment()
    subSeg.put_annotation('http', 'ChuckNorisRules')
    res = requests.get("http://api.icndb.com/jokes/random")
    print res.text
