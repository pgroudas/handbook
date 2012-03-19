# Mortar Hawk REST API v1

This is a preview of the upcoming REST API for Mortar Hawk.  Comments encouraged!

# Getting Started

(Coming soon)


# Basics

All API access is over HTTPS, accessed from the `api.mortardata.com` domain.  All POSTed data is sent and received as JSON.

# Authentication

All API access is over HTTPS, accessed from the `api.mortardata.com` domain.  Every API call requires authentication against your Mortar Hawk account.  Authentication is done via basic authentication over SSL.

For example, to authenticate in curl as `myusername@mydomain.com` with a password of `my_api_password`:

	curl --user 'myusername@mydomain.com:my_api_password' https://api.mortardata.com/


# Jobs

This section of the API allows you to run and monitor jobs.

## Run a Job


Run a script on a freshly provisioned hadoop cluster:

	POST /v1/jobs

### Parameters

* **num_instances**: Size of hadoop cluster to launch
* **script_name**: Which script to run
* **parameters**: Pig parameters to pass to your script


		{
		  "cluster_size": 10,
		  "script_name": "my_metric_rollup",
		  "parameters": { "MY_INPUT_PARAMETER": "my_input_parameter_value",
		  				  "MY_INPUT_PARAMETER_2": "my other value" }
		}

### Response

	200 OK
	{
	  "job_id": "4f4c4afb916eb10526000000"
	}


## Get Job Status

Get the status of a job.

	GET /v1/jobs/:job_id

### Response

	200 OK
	{
	  "job_id": "4f4c4afb916eb10526000000",
	  "name": "NYSE Rollup",
	  "cluster_size": "5",
	  "status": "success",
	  "progress": 100,
	  "outputs": [
	    {
	      "alias": "aggregates_by_stock",
	      "name": "aggregates_by_stock",
	      "records": 2853,
	      "location": "s3n://my-output-bucket/2012-03-01/aggregates_by_stock",
	      "output_blobs" [ 
	        {
	          "bucket": "my-output-bucket",
	          "key": "my-output-bucket/2012-03-01/aggregates_by_stock/part-r-00000",
	          "output_blob_id": "4f6749d1744ea111151399b4"
	        }
	      ]
	    },
	    {
	      "alias": "aggregates_by_year",
	      "records": 2853,
	      "location": "s3n://my-output-bucket/2012-03-01/aggregates_by_year",
	      "output_blobs" [ 
	        {
	          "bucket": "my-output-bucket",
	          "key": "my-output-bucket/2012-03-01/aggregates_by_stock/part-r-00000",
	          "output_blob_id": "4f6749d1744ea111151399b4"
	        }
	    }
	  ],
	  "start_timestamp": "2012-02-28T03:35:42.831000+00:00",
	  "stop_timestamp": "2012-02-28T03:41:52.613000+00:00",
	  "duration": "6 mins",
	  "num_hadoop_jobs": 2,
	  "num_hadoop_jobs_succeeded": 2,
	  "script_parameters" : {
	    "MY_INPUT_PARAMETER": "my_input_parameter_value",
	    "MY_INPUT_PARAMETER_2": "my other value"
	  }
	}

The "main success scenario" for a job passes through status codes:

* **validating_script**: Checking the script for syntax and S3 data storage errors
* **starting_cluster**: Starting up the hadoop cluster
* **running**: Running the job (percent of job completed can be found completeprogress )
* **success**: Job completed successfully.  Outputs are available from the "outputs" field

Error states include the following (error message will be found in the "error" field):

* **script_error**, **plan_error**: An error was detected in the script before launching a hadoop cluster.
* **execution_error**: An error occurred during the run on the hadoop cluster.
* **service_error**: An internal error occurred.

Additionally, jobs stopped by a user have the states:

* **stopping**:  User has requested that the job be stopped
* **stopped**: Job is stopped

Since Hadoop may write the output of the job to multiple files the output_blobs list contains one element for each output of the job.  


## Store Script (Coming Soon)

Store a script into Hawk.

	POST /v1/scripts/:script_name


* **script_name**: Unique name for this script.  If a script with the same name exists, it will be overwritten.  Note that spaces are allowed in script names, but they should be URL-encoded.

### Parameters

* **pig_contents**: Your pig script
* **python_contents**: Your python script

Since the POST is encoded as JSON, newlines and quotes will be escaped:
	
	{
	  "pig_contents": "REGISTER s3n://mhc-example-data/tutorial/tutorial.jar;\\n\\nraw = LOAD \'s3n://mhc-example-data/tutorial/excite.log.bz2\' AS (user, time, query);",
	  
	  "python_contents": "import datetime\\n\\n@outputSchema(\'v: chararray\')\\ndef round_to_hour(tm):\\n"
	}

### Response

	200 OK


## Validate Script (Coming Soon)

TBD.