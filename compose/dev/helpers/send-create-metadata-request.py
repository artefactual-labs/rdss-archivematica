#!/usr/bin/env python3

import argparse
import json

import boto3


METADATA_CREATE_MESSAGE = {
  "messageHeader": {
    "messageId": "9e8f3cfc-29c2-11e7-93ae-92361f002671",
    "messageType": "MetadataCreate",
    "messageClass": "Command"
  },
  "messageBody": {
    "datasetUuid": "a7e83002-29c1-11e7-93ae-92361f002671",
    "datasetTitle": "Research about birds in the UK.",
    "files": [
      {
        "id": "ec2d4928-29c1-11e7-93ae-92361f002671",
        "path": "s3://rdss-prod-figshare-0132/bird-sounds.mp3"
      },
      {
        "id": "0dc88052-29c2-11e7-93ae-92361f002671",
        "path": "s3://rdss-prod-figshare-0132/woodpigeon-pic.jpg"
      }
    ]
  }
}


def parse_endpoint_url(url):
    try:
        port = int(url)
        return 'http://127.0.0.1:%d' % port
    except ValueError:
        return url


def send_message(endpoint_url):
    client = boto3.client('kinesis', region_name='eu-west-2', endpoint_url=parse_endpoint_url(endpoint_url))
    response = client.put_record(
        StreamName='main',
        Data=json.dumps(METADATA_CREATE_MESSAGE),
        PartitionKey='1',
    )
    print(response)


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('endpoint', help='Kinesis endpoint, e.g.: http://127.0.0.1:32784')
    args = parser.parse_args()

    send_message(args.endpoint)
