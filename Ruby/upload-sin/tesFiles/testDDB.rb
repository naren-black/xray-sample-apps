#!/usr/bin/env ruby
require 'aws-xray-sdk'
require 'aws-sdk-dynamodb'
require 'csv'
config = {
  name: 'NarApp',
  patch: %I[aws_sdk]
}
XRay.recorder.configure(config)
segment = XRay.recorder.begin_segment 'DynDB-Csv'
ddb = Aws::DynamoDB::Client.new
CSV.foreach("/Users/aranin/eyeFolder/AllServices/X-Ray/upload-sin/toUpload.csv") do |row|
  item = {
    firstName: row[0],
    lastName: row[1],
    email: row[2],
    description: row[3]
  }
  params = {
    table_name: "EmployeeRecords",
    item: item
  }
  begin
    res = ddb.put_item(params)
    p res
    puts "Added the item: #{item[:email]}"
  rescue Aws::DynamoDB::Errors::ServiceError => error
    puts "Unable to add item..."
    puts error.message
  end
end
XRay.recorder.end_segment