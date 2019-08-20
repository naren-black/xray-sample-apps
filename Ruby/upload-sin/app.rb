#!/usr/bin/env ruby
require 'sinatra'
require "aws-sdk-s3"
require "aws-sdk-dynamodb"
require 'aws-xray-sdk'
require "csv"
AWS_XRAY_CONTEXT_MISSING = 'LOG_ERROR'
config = {
  name: 'UploadRubyApp',
  patch: %I[aws_sdk]
}
XRay.recorder.configure(config)

get '/' do
  erb :index
end

post '/upload' do
  segment = XRay.recorder.begin_segment 'SingleInputMainSegment'
  theAnnot = {inputType: "SingleItemInput"}
  segment.annotations.update theAnnot
  file       = params[:file][:tempfile]
  filename   = params[:file][:filename]
  # subsegment = XRay.recorder.begin_subsegment 'DynDB-Single-Item-Input'
  ddb = Aws::DynamoDB::Client.new
  CSV.foreach(file) do |row|
    item = {
      firstName: row[0],
      lastName: row[1],
      Email: row[2],
      description: row[3]
    }
    params = {
      table_name: ENV["TABLE_NAME"],
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
  # XRay.recorder.end_subsegment
  # subsegment = XRay.recorder.begin_subsegment 'uploadFile'
  s3 = Aws::S3::Resource.new
  nn = s3.bucket("narenuseast").object(filename)
  begin
    puts "The file #{filename} is beeeiiiinnnggg  uploaded......"
    File.open(file, "rb") { |fh|
      nn.put(body: fh)
    }
    # XRay.recorder.end_subsegment
    XRay.recorder.end_segment
    erb :show, :locals => {message: "Yey the file #{filename} got uploaded..."}
  rescue
    # XRay.recorder.end_subsegment
    XRay.recorder.end_segment
    erb :show, :locals => {message: "The file #{filename} did not get uploaded baabu!!"}
  end
end

post "/uploadformulti" do
  segment = XRay.recorder.begin_segment 'BatchItemWriteSegment'
  theAnnot = {inputType: "ThreadedItem"}
  segment.annotations.update theAnnot
  # subsegment = XRay.recorder.begin_subsegment 'uploadPage'
  file       = params[:file][:tempfile]
  filename   = params[:file][:filename]
  # subsegment = XRay.recorder.begin_subsegment 'DynDB-Csv'
  ddb = Aws::DynamoDB::Client.new
  itemsArr = []
  CSV.foreach(file) do |row|
    itemHash = {}
    itemHash["firstName"] = row[0]
    itemHash["lastName"] = row[1]
    itemHash["Email"] = row[2]
    itemHash["description"] = row[3]
    itemsArr << { put_request: { item: itemHash }}
  end
  res = ddb.batch_write_item({
    request_items: {
      ENV["TABLE_NAME"] => itemsArr
    }
  })
  puts res
  s3 = Aws::S3::Resource.new
  nn = s3.bucket("narenuseast").object(filename)
  begin
    puts "The file #{filename} is beeeiiiinnnggg  uploaded......"
    File.open(file, "rb") { |fh|
      nn.put(body: fh)
    }
    # XRay.recorder.end_subsegment
    XRay.recorder.end_segment
    erb :show, :locals => {message: "Yey the file #{filename} got uploaded..."}
  rescue
    # XRay.recorder.end_subsegment
    XRay.recorder.end_segment
    erb :show, :locals => {message: "The file #{filename} did not get uploaded baabu!!"}
  end
end

post "/multi-threaded" do
  segment = XRay.recorder.begin_segment 'ThreadedSegment'
  theAnnot = {inputType: "ThreadedItem"}
  segment.annotations.update theAnnot
  entity = XRay.recorder.current_entity
  file       = params[:file][:tempfile]
  filename   = params[:file][:filename]
  ddb = Aws::DynamoDB::Client.new
  s3 = Aws::S3::Resource.new
  nn = s3.bucket("narenuseast").object(filename)
  itemsArr = []
  CSV.foreach(file) do |row|
    itemHash = {}
    itemHash["firstName"] = row[0]
    itemHash["lastName"] = row[1]
    itemHash["Email"] = row[2]
    itemHash["description"] = row[3]
    itemsArr << { put_request: { item: itemHash }}
  end
  threads = []
  threads << Thread.new do
    begin
      XRay.recorder.inject_context(entity )do
        res = ddb.batch_write_item({
          request_items: {
            ENV["TABLE_NAME"] => itemsArr
          }
        })
        puts res
      end
    rescue
      puts "Could not write the records in dynamodb"
    end
  end
  theMes = ""
  threads << Thread.new do
    begin
      XRay.recorder.inject_context entity do
        puts "The file #{filename} is beeeiiiinnnggg  uploaded......"
        File.open(file, "rb") { |fh|
          nn.put(body: fh)
        }
        # XRay.recorder.end_subsegment
        # XRay.recorder.end_segment
        theMes = "Yey the file #{filename} got uploaded..."
      end
    rescue
      # XRay.recorder.end_subsegment
      theMes = "The file #{filename} did not get uploaded baabu!!"
    end
  end
  threads.each { |thr| thr.join }
  XRay.recorder.end_segment
  erb :show, :locals => {message: theMes}
end
