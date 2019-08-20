#!/usr/bin/env ruby
require 'aws-sdk-dynamodb'
require 'csv'

ddb = Aws::DynamoDB::Client.new
itemsArr = []
CSV.foreach("/Users/aranin/Desktop/XRayMaterial/upload-sin/toUpload.csv") do |row|
  itemHash = {}
  itemHash["firstName"] = row[0]
  itemHash["lastName"] = row[1]
  itemHash["email"] = row[2]
  itemHash["description"] = row[3]
  itemsArr << { put_request: { item: itemHash }}
end

res = ddb.batch_write_item({
  request_items: {
    "EmployeeRecords" => itemsArr
  }
})
p res
