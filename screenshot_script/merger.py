#!/usr/bin/env python3

import json
import argparse


parser = argparse.ArgumentParser(description='Merge multiple JSON check files into one.')
parser.add_argument('input_files', nargs='+', help='List of input JSON files to merge')
parser.add_argument('output_file', help='Output JSON file to write the merged results to')
args = parser.parse_args()

merged_data = {
	"files": set(),
	"time": 0.,
	"checks": []
}

for input_file in args.input_files:
	with open(input_file, 'r') as f:
		data = json.load(f)
		merged_data["files"].update(set(data["files"]))
		merged_data["time"] += data["time"]
		merged_data["checks"] += data["checks"]
  
merged_data["files"] = list(merged_data["files"])
with open(args.output_file, 'w') as f:
	json.dump(merged_data, f, indent=4)