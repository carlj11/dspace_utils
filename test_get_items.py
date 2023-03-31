
# Dome DSpace REST API 

# test_get_items.py 2>&1 | tee run.log

import requests
import json
import logging
import csv

import dateutil.parser as dateparser

from datetime import datetime, date

image_count = 0
limit_count = 0
limit = 0
offset = 0

base_url = "https://dome.mit.edu/rest/"

# https://demo.dspace.org/rest/collections/UUID/items?offset=100&limit=100
# https://demo.dspace.org/rest/collections/UUID/items/?offset=200&limit=100
# https://dome.mit.edu/rest/collections/20681207-3f1c-45cd-9efb-0640afb2ecc5/items?limit=227

# Sample REST API items URL:
# https://dome.mit.edu/rest/items/03e36dcc-6c5b-48e5-ad88-cb037c9467ce?expand=metadata,bitstreams,parentCollectionList
#
# https://dome.mit.edu/rest/items/00f095dd-96af-4b8f-a0ca-ca5635445aed/metadata
# 
# https://dome.mit.edu/rest/items/17a75090-78c4-4f91-9a51-a29c2cdcdb3e
#
# logging.basicConfig(filename='example.log', encoding='utf-8', level=logging.DEBUG)

#  logging levels DEBUG, INFO, WARNING

logging.basicConfig(level=logging.NOTSET)


def get_collection_info(handle_url):
    
    # rest
    # https://dome.mit.edu/rest/handle/1721.3/172401
    
    coll_metadata_url = base_url + "handle/" + handle_url
    
    # using UUID instead
    # coll_metadata_url = base_url + "collections/1d4d49c5-667c-45c0-9898-a0701eb37863"
    
    response = requests.get(coll_metadata_url)
    
    coll_metadata = json.loads(response.text)   
    
    logging.info(f"coll_metadata type: {type(coll_metadata)}")
        
    logging.info(f"collection UUID: {coll_metadata['uuid']}")
    logging.info(f"collection Number of Items: {coll_metadata['numberItems']}")
    logging.info(f"collection Name: {coll_metadata['name']}")
      
    return coll_metadata
     

# get collection items in batches of 'limit' items 
# the REST API is slow, the default is 100 items at-a-time, but 200 is also fairly quick; things slow down considerably if you try, say, 500 item chunks
# For example, coll_url = base_url + "collections/" + coll_uuid + "/items" + "?limit=500"
def test_get_collection_items(coll_uuid, number_items, offset, limit):
    
    coll_url = base_url + "collections/" + coll_uuid + "/items?offset=" + str(offset) + "&limit=" + str(limit)  
    
    response = requests.get(coll_url)
    items_array = json.loads(response.text)   
    
    return items_array
    
    

def test_get_item_metadata(items_array, urlwriter):
    
    # base_url = "https://dome.mit.edu/rest/"
    # items_array is a list [of json objects]   
    
    logging.debug("Entering. method test_get_item_metadata()....")
    logging.info(f"Will get chunk of new items")
                      
    for it in items_array:
        
        item_uuid = it['uuid']     
        logging.debug("Item UUID = {}".format(item_uuid))
                 
        # metadata endpoint to see detailed item (metadata as json key/value pairs)
        item_metadata_url = base_url + "items/" + item_uuid + "/metadata"
        response = requests.get(item_metadata_url)
        
        # get array of item metadata elements, item_metadata is a list object
        # structure is: metadataEntries > metadataentry > key > value 
        # item_metadata = json.loads(response.text)
        metadataEntries = json.loads(response.text)
                  
        logging.debug(f"MetadataEntries object type is: {type(metadataEntries)}")
        
        item_dict = {}
        
        for metadataentry in metadataEntries:
            if metadataentry["key"] == "dc.identifier":
                item_dict["identifier"] = metadataentry["value"]
                logging.debug("dc.identifier: " + item_dict["identifier"])
                
            # test, errors below
            # print("item type: {}".format(element["dc.type"]))               
            if metadataentry["key"] == "dc.identifier.uri":
                item_dict["identifier_uri"] = metadataentry["value"]                
                logging.debug(f"dc.identifier.uri: {item_dict['identifier_uri']}")
                
            if metadataentry["key"] == "dc.date.accessioned":
                item_dict["date_acc"] = metadataentry["value"]
                logging.debug(f"dc.date.accessioned: {item_dict['date_acc']}")
            
            if metadataentry["key"] == "dc.type":
                item_dict["asset_type"] = metadataentry["value"]
              
        logging.info("Make sure we have the correct date format")
        try:
            accession_date = dateparser.parse(item_dict["date_acc"][:10])
        except:
            print(f"invalid accession date {item_dict['accession_date']}")
            exit(1)
                           
        # TODO: parse for date range match

        # hardwire date for now, find anything after this date
        start_date = dateparser.parse('2019-01-01')
        # start_date = dateparser.parse(argv[1])
        
        if item_dict["asset_type"] == "Image" and start_date < accession_date:
                       
            row = ""
          
            row += item_dict["identifier_uri"] + ", " + \
                   item_dict["identifier"] + ", " + item_dict["date_acc"] + ", " + item_dict["date_acc"] + ", digital image"
                   #item_dict["date.acc"]      
     
            logging.info(f"Write each row to csv file: {row}")     
            urlwriter.writerow([item_uuid, item_dict["identifier"], item_dict["identifier_uri"], item_dict["date_acc"]])
                       
        
def main():
     
    # TODO: get collection handle and start_date from command line; parse collection UUID from response
    
    # Question: what about really big collections with tens of thousands of items?
    
    #
    time = datetime.now()
    csv_file_creation_time = time.strftime("%Y-%m-%d_%H%M%S")
    logging.info(f"todays date and time is {csv_file_creation_time}")
    
    # write to .csv file (hardwired for testing)
    with open('/Users/carlj/Developer/GitHub/dspace_utils-main/langendorf-dome_handles_4_iris_' + csv_file_creation_time + '.csv', 'w', newline='') as csvfile:
        urlwriter = csv.writer(csvfile)
        logging.debug("Print csv file header row")
        urlwriter.writerow(["dspace_uuid", "dc_identifier", "handle_url", "accession_date"])
    
        # US China Peoples Friendship Association Planners Tour (227 items)
        # coll_uuid = "20681207-3f1c-45cd-9efb-0640afb2ecc5"
        # 1721.3/189002   
        # handle_url = "1721.3/189002"
        
        # Richard Langendorf collection
        handle_url = "1721.3/172401"
        
        coll_info = {}
        
        coll_info = get_collection_info(handle_url)
        logging.info(f"In main(), coll_info name = {coll_info['name']}")

        coll_uuid = coll_info['uuid']
        number_items = coll_info['numberItems']
        
        offset = 0

        logging.debug("Begin main(), image_count %d: ", number_items)
        logging.debug(f"Collection UUID: {coll_uuid}")
        
        if number_items >= 100:
            # divide by 100?
            repeat_count = number_items // 100
        
            logging.info(f"Number of times we'll need to grab collection items in increments of 100 (settable REST API 'limit' parameter): {repeat_count}")
        
            i = 0
            # default for number of items to retrieve at one time through the REST API 
            limit = 100
            while i <= repeat_count:
            
                logging.info(f"Number of Times through reqest loop = {i}")
                logging.info(f"offset = {offset}")
                logging.info(f"limit = {limit}")
            
                # does this make sense?
                items_fetched = number_items - offset  
                logging.info(f"items_fetched = {items_fetched}")
            
                logging.info(f"Bottom of while loop BEFORE incrementing offset count, offset = {offset}")          
        
                # when does limit need to be recalculated?
                logging.info("In main 'if image count()' loop, image count %d: ", number_items)
            
                items_array = test_get_collection_items(coll_uuid, number_items, offset, limit)   
            
                # list of 100 collection items        
                test_get_item_metadata(items_array, urlwriter)           
            
                offset += 100            
                logging.info(f"Bottom of while loop AFTER incrementing offset count, offset = {offset}")
                        
                i += 1
     
            print(f"Repeat count {repeat_count}")   
            print("Done")
            # exit(0)
    
        else:
            print("Less than 100 items, we're done")
            # coll_url that gets 0 - 100 items
            exit(0)
    
    csvfile.close()   
    exit(0) 
        
if __name__ == '__main__':
    main()