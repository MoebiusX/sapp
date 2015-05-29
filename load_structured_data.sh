#!/bin/sh

/Users/cmontero/mlcp/bin/mlcp.sh import -host localhost -port 58041 -username admin -password admin -input_file_path data/ -input_file_pattern '.*\.csv' -mode local -input_file_type delimited_text -delimited_root_name 'functional-location' -delimited_uri_id MI_FNCLOC00_FNC_LOC_C -output_uri_prefix '/functional-locations/'  -output_uri_suffix '.xml'
