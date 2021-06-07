#!/usr/bin/env python

import re
import sys
import socket
import httplib
import json
import unittest


host = "localhost"
port = 8888
if len(sys.argv) > 1:
  host = sys.argv[1]
if len(sys.argv) > 2:
  port = int(sys.argv[2])
header = {'Content-type':'application/json'}


def TestCreatePair(host, port, conn):
	body = {
			"key" : "1",
			"value" : {
				"fruit" : "apple",
				"calories" : 52,
				"protein" : 0.3,
				"fat" : 0.2,
				"carbs" : 13.8,
			}
		}

	conn.request("POST", "/kv", body = json.dumps(body,indent=1), headers = header)
	my_request = conn.getresponse()
	data = my_request.read()
	assert int(my_request.status) == 200
	assert json.loads(data) == body

def TestWbadKey(host, port, conn):
	body = {
			"key" : 1,
			"value" : {
				"fruit" : "apple",
				"calories" : 52,
				"protein" : 0.3,
				"fat" : 0.2,
				"carbs" : 13.8,
			}
		}

	conn.request("POST", "/kv", body = json.dumps(body,indent=1), headers = header)
	my_request = conn.getresponse()
	assert int(my_request.status) == 400

def TestWbadValue(host, port, conn):
	body = {
			"key" : "1",
			"value" : "apple"
		}

	conn.request("POST", "/kv", body=json.dumps(body, indent=1), headers = header)
	my_request = conn.getresponse()
	assert int(my_request.status) == 400

def TestPairConflict(host, port, conn):
	body = {
			"key" : "2",
			"value" : {
				"fruit" : "apple",
				"calories" : 52,
				"protein" : 0.3,
				"fat" : 0.2,
				"carbs" : 13.8,
			}
		}

	conn.request("POST", "/kv", body=json.dumps(body,indent=1),headers=header)
	my_request = conn.getresponse()
	data = my_request.read()
	assert int(my_request.status) == 200
	assert json.loads(data) == body


def TestUpdate(host, port, conn):
	body = {
			"key" : "3",
			"value" : {
				"fruit" : "apple",
				"calories" : 52,
				"protein" : 0.3,
				"fat" : 0.2,
				"carbs" : 13.7,
			}
		}

	conn.request("POST", "/kv", body=json.dumps(body,indent=1),headers=header)
	my_request = conn.getresponse()
	data = my_request.read()
	assert int(my_request.status) == 200
	assert json.loads(data) == body

	updatedBody =  {
			"value" : {
				"fruit" : "apple",
				"calories" : 52,
				"protein" : 0.3,
				"fat" : 0.2,
				"carbs" : 13.8,
			}
		}

	conn.request("PUT", "/kv/3", body=json.dumps(updatedBody,indent=1),headers=header)
	my_request = conn.getresponse()
	data = my_request.read()
	assert int(my_request.status) == 200
	updatedBody["key"] = "3"
	assert json.loads(data) == updatedBody


conn = httplib.HTTPConnection(host, port, timeout=10)
TestCreatePair(host, port, conn)
conn.close()
print('OK!')

conn = httplib.HTTPConnection(host, port, timeout=10)
TestWbadKey(host, port, conn)
conn.close()
print('OK!')

conn = httplib.HTTPConnection(host, port, timeout=10)
TestWbadValue(host, port, conn)
conn.close()
print('OK!')

conn = httplib.HTTPConnection(host, port, timeout=10)
TestPairConflict(host, port, conn)
conn.close()
print('OK!')

conn = httplib.HTTPConnection(host, port, timeout=10)
TestUpdate(host, port, conn)
conn.close()
print('OK!')
