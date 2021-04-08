# using the DSpace 6.x  REST API
# retrieve item infor based on a collection UUID
# docs:  
#  https://wiki.lyrasis.org/display/DSDOC6x/REST+API#RESTAPI-Items
#  test coll_uuid


import requests
import json
import dateutil.parser as dateparser
#import pytz

from sys import argv, exit
from uuid import UUID
from datetime import datetime, date


base_url = "https://dome.mit.edu/rest/"
#est = pytz.timezone('EST')


def verify_uuid(uuid):
    try:
        return  UUID(uuid).version
    except ValueError:
        return None


def main(argv):

    coll_uuid = argv[0]
    #coll_uuid = "6f486c8e-583d-443f-b98c-570753098d14"
    uuid_version = verify_uuid(coll_uuid)
    if uuid_version is None:
      print(f"invalid collection uuid {coll_uuid}; exiting program")
      exit(1)

    print(f"collection uuid has version {uuid_version}")

    coll_url = base_url + "collections/" + coll_uuid + "/items"
    print(coll_url)

    try:
        start_date = dateparser.parse(argv[1])
        print(f"start date: {start_date}")
    except:
        print(f"invalid start date {argv[1]}")
        print("use date format YYYY-MM-DD")
        exit(1)

    # query RESTful service
    response = requests.get(coll_url)

    # a list of dicts
    items_array = json.loads(response.text)

    print(f"count of items in collection: {len(items_array)}")

    print("============")

    image_count = 0

    for it in items_array:

        item_uuid = it['uuid']

        # print(item_uuid)

        item_metadata_url = base_url + "items/" + item_uuid + "/metadata"
        response = requests.get(item_metadata_url)
        item_metadata = json.loads(response.text)

        row = ""
        item_dict = {}

        for element in item_metadata:
            if element["key"] == "dc.identifier":
                item_dict["identifier"] =  element["value"]
            if element["key"] == "dc.identifier.uri":
                item_dict["identifier.uri"] = element["value"]
            if element["key"] == "dc.date.accessioned":
                item_dict["date.acc"] = element["value"]
            if element["key"] == "dc.type":
                item_dict["asset.type"] = element["value"]

        try:
           acc_date = dateparser.parse(item_dict["date.acc"][:10])
        except:
           print(f"invalid accession date {item_dict['date.acc']}")
           exit(1)

        if item_dict["asset.type"] == "Image" and start_date < acc_date:
            # in_range(item_dict["date.acc"]):
            image_count += 1
            row += item_dict["identifier.uri"] + ", " + \
                   item_dict["identifier"] + ", digital image"
                   #item_dict["date.acc"]

            print(row)

    print(f"\nCount of image items: {image_count}\n")

main((argv[1:]))
