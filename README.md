![Mortar Logo](https://github.com/mortardata/handbook/raw/master/assets/mortar_logo_type.png)

# The Mortar Handbook

A simple, work-in-progress guide to using Mortar.  


# Table of Contents

* [Quick-Start](#quick-start)
 * [Demo Script](#demo-script)
 * [Script from Scratch](#script-from-scratch) 
* [Adding Parameters to Your Script](#parameters)
* [Using Pig Macros](#macros)
* [Using Python from S3](#s3_python)
* [Keeping a Cluster Running for Development](#keep_cluster_running)

<a name='quick-start'></a>
# Quick-Start
## Overview
Mortar should have you up and running with Hadoop in under an hour. We'd love to hear how much time you spent getting started. If it took more than an hour, what parts were tricky? If it took less, that's great, please tell us!

## Log in
Log in at [hawk.mortardata.com](https://hawk.mortardata.com)

### Jobs Page
You'll begin on the Jobs page. This page shows you jobs you have run in the past, successful, unsuccessful, and in progress. If this is your first time logging in, you won't have run any jobs yet. Go to the Code page by clicking the Code tab at the top of the page.

### Code Page
Initially the Code page will display a demo script called "1MM song dataset".

This page is divided into two areas: Pig and Python. 

**Pig**

The Pig code drives execution. Pig is a data flow language that is similar to SQL, but it is executed in steps—it does joins, filters, aggregates, sorts etc. 

**Python**

Python user-defined functions (UDFs) are applied to rows or groups of rows by Pig. Python UDFs enable rich computation (for example: lingustic analysis, sophisticated parsing, advanced math, sound analysis, etc.) 

<a name='demo-script'></a>
## Run a demo script
### Open
If "1MM song dataset" is not open, select it from the menu option Scripts=>Open.

Scroll through the Pig code, each statement builds on the statement before. If you're familiar with SQL, it should read easily: Load the data from s3, filter it, apply a Python calculation to each row, order the rows, retain the top 50 rows, store the top 50 rows to s3.

### Illustrate
Highlight one of the Pig variables, `top_density` for example. Click the Illustrate button at the top right. ![Illustrate button](https://github.com/mortardata/handbook/raw/master/assets/demo-script/button-illustrate.png)

Illustrate will check that your code will run, and will show you the data flowing through each step of your script (load, filter, etc.) until it reaches `top_density`. Illustrate will take less than a minute to do sophisticated sampling; much faster than manually curating the subset of the data yourself.

### Run
To make the run finish faster, switch the 'songs' alias to load one file `s3n://tbmmsd/A.tsv.a` instead of the full dataset.

Click the Run button. ![Run button](https://github.com/mortardata/handbook/raw/master/assets/demo-script/button-run.png)

Select the number of nodes (machines) you want to parallelize work on. Five nodes should be sufficient for completion of the entire million song dataset in an hour; if you're running on just one file, three nodes will complete in a few minutes.

### Jobs Summary
Once you start your cluster, you'll be taken to the Jobs page. A new private cluster is created to run the job, and you can watch job progress from here.

### Job Detail
Click on the job name to see details: the code you ran, links to the results in s3, logs, and runtime errors (if any). Runtime [parameters](#parameters) (described later) are also displayed here.

### Results
When the job completes, go to the detail page, and in the Results section there are links to download directly, and through the s3 console.



<a name='script-from-scratch'></a>
## Create a script from scratch
### Overview
In this example we'll process the Austin Daily Weather dataset stored in your own private S3 bucket. (It's a small dataset that you can download quickly; useful for this example, but smaller than something you'd normally use Hadoop for.)

### Enable access
Click "Account & Settings" in the upper right of the Mortar screen. Provide the AWS Access Key ID and AWS Secret Access Key necessary to access your s3 bucket.

You can find your AWS keys on the [Amazon Security Credentials](https://aws-portal.amazon.com/gp/aws/securityCredentials) page in the Access Credentials section.

![AWS Key Console](https://github.com/mortardata/handbook/raw/master/assets/scratch-script/aws-access-keys.png)

### Set up S3
Download the  [Austin Daily Weather](http://dl.dropbox.com/u/155396/central_texas_daily_weather.tsv.bz2) dataset and then upload it into your s3 bucket. [s3cmd](http://s3tools.org/s3cmd) and [Transmit](https://panic.com/transmit/) (recommended) work well to upload directly to s3.

**Transmit**

Download and install [Transmit](https://panic.com/transmit/). Launch it, and provide the same Access Key and Secret Access Key you used in the prior step. You can leave the Initial Path field empty.

![Transmit AWS Key Entry](https://github.com/mortardata/handbook/raw/master/assets/scratch-script/transmit-keys.png)

Drop the Austin Daily Weather file you just downloaded `central_texas_daily_weather.tsv.bz2` into an S3 bucket, for example `weather-example`.


### New script
Go to the Code page, then choose from the menu: Script=>New=>Blank Script. Give your new script a name, "Hot in Austin".

### Load data
From the "Pig Statements" menu at the bottom-left of the Pig code area, select Pig Statements=>Load/Store Data=>LOAD

For this script we will use columns 4 and 5, so my load statement looks like this ([dataset doc](http://www.infochimps.com/datasets/austin-daily-weather-extracted-from-national-climate-data-center)):

    daily_weather = LOAD 's3n://<my-bucket>/central_texas_daily_weather.tsv.bz2' USING PigStorage('\t') as (name, station, wban, date, temp:float);

Replace \<my-bucket\> with the real name of your bucket. If you right-click the S3 file in Transmit, select Copy Path, and then paste, your Path will look like:

`http://<my-bucket>.s3.amazonaws.com/central_texas_daily_weather.tsv.bz2`.

Turn this into an S3 url by replacing `http://` with `s3n://` and removing `.s3.amazonaws.com`

Add a STORE statement in the same way: Statements=>Load/Store Data=>STORE.

*Replace \<my-bucket\> with the real name of your bucket*    

    STORE hottest INTO 's3n://<my-bucket>/output-hot-in-austin' USING PigStorage('\t');

Now confirm that the data is being loaded correctly. Highlight `daily_weather` and click the ILLUSTRATE button. You should now see one row of data being being loaded into `daily_weather`.

### Write the script
If you want to see the hottest days in Austin, try this script:

*Replace \<my-bucket\> with the real name of your bucket; it is used 3 times*

    daily_weather = LOAD 's3n://<my-bucket>/central_texas_daily_weather.tsv.bz2' USING PigStorage('\t') as (unused_1, unused_2, unused_3, date, temp:float);

    -- group the readings from different stations from the same day
    day_group = GROUP daily_weather BY (date);
    -- get the average tempure for the date
    daily_avg = FOREACH day_group GENERATE group as date, AVG(daily_weather.temp) as temp;
    -- sort the days by average tempurature
    daily_avg_hot = ORDER daily_avg BY temp DESC;
    -- keep the hottest 20 days
    hottest = LIMIT daily_avg_hot 20;

    -- Remove any pre-existing data in folder
    rmf s3n://<my-bucket>/output-hot-in-austin;
    STORE hottest INTO 's3n://<my-bucket>/output-hot-in-austin' USING PigStorage('\t');

### Illustrate
Click Illustrate again, observe what the script does.

### Run
If you are satisfied, click the Run button. Select just 2 nodes, which is sufficient since the dataset is rather small. Check the box to "Keep cluster running after job finishes". The cluster will shut itself off when it has been idle for an hour. Press the Run button. When the run completes, download the results from the Job detail page. Notice that most of the hottest days are not in in the last decade!

![Download Results](https://github.com/mortardata/handbook/raw/master/assets/scratch-script/hottest-download-results.png)

### Python
What if we want to see the average tempurature for the year? We need to parse the date string. In the Python window, put 

    @outputSchema('year:chararray')
    def year(date):
      return (date[0:4])
which tells Pig that the return type is a chararray (string), and the parses the date string to keep the first four characters, so a date "20110214" would become "2011".

And update the Pig code to use the Python and average an entire year of temperature measurements:

    daily_weather = LOAD 's3n://hawk-example-data/weather/central_texas_daily_weather.tsv.bz2' USING PigStorage('\t') as (unused_1, unused_2, unused_3, date:chararray, temp:float);

    -- group the readings from different stations from the same day
    day_group = GROUP daily_weather BY (date);
    -- get the average temperature for the date
    daily_avg = FOREACH day_group GENERATE group as date, AVG(daily_weather.temp) as temp;

    -- keep just the year of each temperature, using Python
    year_with_temp = FOREACH daily_avg GENERATE year(date), temp;
    -- group the temperatures by year
    year_group = GROUP year_with_temp BY year;
    -- get the average temperature for the year
    yearly_avg = FOREACH year_group GENERATE group as year, AVG(year_with_temp.temp) as temp;

    -- sort the years by average tempurature
    yearly_avg_hot = ORDER yearly_avg BY temp DESC;
    -- keep the hottest 20 years
    hottest_years = LIMIT yearly_avg_hot 20;

    -- Remove any pre-existing data in folder
    rmf s3n://kyoung-development/output-hot-years-in-austin;
    STORE hottest_years INTO 's3n://kyoung-development/output-hot-years-in-austin' USING PigStorage('\t');
    
### Run Again 
Run your code again, this time using the already-running cluster. Select "Existing Cluster - 2 Nodes" from the Hadoop Cluster dropdown in the Run window. When the job completes, click on it, and download and check out the results. Surprised? We were.
    

<a name='parameters'></a>
# Adding Parameters to Your Script

You'll often want to run a script on different data sets or with different conditions.  Script parameters allow you to run the same script with different parameters.

 
### Before Parameterization

Let's take an example of a script that processes New York Stock Exchange (NYSE) data.  Imagine that our script is filtered to look at data for only the Apple Inc. (APPL) stock.  Before being parameterized, our script looks like:

    -- load up the NYSE daily price data    
	nyse_daily_prices = LOAD 's3n://hawk-example-data/NYSE/daily_prices' 
                       USING PigStorage(',')
                          AS (exchange:chararray, stock_symbol:chararray, date:chararray, 
                              stock_price_open:float, stock_price_high:float,
                              stock_price_low:float, stock_price_close:float, stock_volume:long,
                              stock_price_adj_close:float);

    -- filter to get just the stock we want
    my_stock_only = FILTER nyse_daily_prices BY stock_symbol == 'APPL';


### After Parameterization

Let's parameterize this script to make it run on **any** stock.  We'll add a parameter called `STOCK_TO_ANALYZE` to the top of the script:

	-- create a parameter
	%default STOCK_TO_ANALYZE "APPL";
	
    -- load up the NYSE daily price data    
	nyse_daily_prices = LOAD 's3n://hawk-example-data/NYSE/daily_prices' 
                       USING PigStorage(',')
                          AS (exchange:chararray, stock_symbol:chararray, date:chararray, 
                              stock_price_open:float, stock_price_high:float,
                              stock_price_low:float, stock_price_close:float, stock_volume:long,
                              stock_price_adj_close:float);

    -- filter to get just the stock we want
    my_stock_only = FILTER nyse_daily_prices BY stock_symbol == '$STOCK_TO_ANALYZE';

Now, whenever we launch this job, Mortar will let us define the stock we want to analyze:

![Run Job With Parameter](https://github.com/mortardata/handbook/raw/master/assets/parameters/run_job_with_parameter.png)

<a name='macros'></a>
# Using Pig Macros

[Pig macros](http://ofps.oreilly.com/titles/9781449302641/advanced_pig_latin.html#macros) help you break up large pig scripts into modular, reusable chunks.

## A Simple Example
Let's look at an example where a macro would be helpful.  Imagine that, using our NYSE data, we'd like to get the price data for any range of years.  We can put this code into a macro that looks like:

	DEFINE get_nyse_for_years(first_year, last_year)
	returns filtered_year_prices {
		
		-- load up the data
		nyse_daily_prices = 
		            LOAD 's3n://hawk-example-data/NYSE/daily_prices' 
                   USING PigStorage(',') 
                      AS (exchange:chararray, stock_symbol:chararray, date:chararray, 
                          stock_price_open:float, stock_price_high:float, stock_price_low:float,
                          stock_price_close:float, stock_volume:long, stock_price_adj_close:float);
        
        -- extract the the year from the date string
        prices_with_year = FOREACH nyse_daily_prices 
                     GENERATE exchange..stock_price_adj_close,
                                 (int)SUBSTRING(date, 0,4) AS year:int;
        
        -- filter to get the right years
        $filtered_year_prices = FILTER prices_with_year
        					       BY year >= $first_year AND year <= $last_year;
	};

We'll store this macro script in our S3 bucket at `s3n://hawk-example-data/NYSE/macros/nyse-macros.pig`.  With the macro file in place, we can reference it in any Hawk script.  For example:

	-- import the NYSE macros
	IMPORT 's3n://hawk-example-data/NYSE/macros/nyse-macros.pig';

	-- grab stock prices from 2005 to 2007
	nyse_prices_2005_2007 = get_nyse_for_years(2005, 2007);


## Returning Multiple Relations

You'll often want to return more than one relation from your macro. This happens particularly often when grouping data.  For example, in the following macro we need to expose both the `grouped_by_symbol` relation **and** the `nyse_daily_prices` to let callers use the grouped results:

	DEFINE get_stocks_by_symbol()
	returns nyse_daily_prices, grouped_by_symbol {
	
      -- load up the data
    	$nyse_daily_prices = 
                LOAD 's3n://hawk-example-data/NYSE/daily_prices' 
               USING PigStorage(',') 
                  AS (exchange:chararray, stock_symbol:chararray, date:chararray, 
                      stock_price_open:float, stock_price_high:float, stock_price_low:float,
                      stock_price_close:float, stock_volume:long, stock_price_adj_close:float);
    
        -- group by symbol
        $grouped_by_symbol = GROUP $nyse_daily_prices
                                BY stock_symbol;
    };

Here's how we'd call this macro from our pig script:

	-- import the NYSE macros
	IMPORT 's3n://hawk-example-data/NYSE/macros/nyse-macros.pig';

	-- get the groups of stocks by symbol
	nyse_prices, grouped_by_symbol = get_stocks_by_symbol();
	
	-- do something interesting with the data
	avg_by_symbol = FOREACH grouped_by_symbol
				   GENERATE group AS symbol,
				   	    AVG(nyse_prices.stock_price_close) AS average_price;

<a name='s3_python'></a>
#Using Python from S3

Storing commonly used Python in S3 is an easy way to reuse code across different scripts and to share code between different Hawk users.

## An exciting example

Here's a simple script that operates on the excite search data included in Hawk and calculates the average length of words in each user's queries.

Pig:

    -- Load up the search log data
    searches =  LOAD 's3n://hawk-example-data/tutorial/excite.log.bz2' 
               USING PigStorage('\t') 
                  AS (user_id:chararray, timestamp:chararray, query:chararray);
    
    -- Group searches by user.
    user_searches = GROUP searches by user_id;
    
    -- Calculate average search length for each user.
    word_length =  FOREACH user_searches
                  GENERATE avg_word_length(searches) as average_word_length;

Python:

    @outputSchema('avg_word_length:double')
	def avg_word_length(bag):
    	"""
    	Get the average word length in each search.
    	"""
    	num_chars_total = 0
    	num_words_total = 0
    	for tpl in bag:
        	query = tpl[2] or ''
        	words = query.split(' ')
        	num_words = len(words)
        	num_chars = sum([len(word) for word in words])

        	num_words_total += num_words
        	num_chars_total += num_chars

    	return float(num_chars_total) / float(num_words_total) \
        	if num_words_total > 0 \
        	else 0.0

After writing this script it might turn out that we find another use for our avg_word_length UDF.  The easiest option for sharing this code is to move it into a separate file that can be shared through S3.

## Creating a Shareable Python File.

First, we need to create a file that contains all of our udf's python code.  In our case we'll call it <i>word_udfs.py</i> and copy all of the above python code into that file.

Second, we need to provide the python definition for the outputSchema annotation.  To do this, we'll add at the very top of <i>word_udfs.py</i> the line:  

    from pig_util import outputSchema
    
If you're interested in running this script locally you can find  [pig_util.py here](https://github.com/mortardata/handbook/raw/master/code/pig_util.py).  Just download the file to the same directory as <i>word_udfs.py</i>.

Finally, we'll need to upload the python file to an S3 location that is accessible from our Hawk account.  For our purposes we'll use: s3n://hawk-example-data/shared_code/word_udfs.py.

## Registering the Python File in Hawk

Now that we have our s3 accessible python file we can write our original pig script like so:

Pig:
    
    REGISTER 's3n://hawk-example-data/tutorial/shared_udfs/word_udfs.py' using streaming_python;

    -- Load up the search log data
    searches =  LOAD 's3n://hawk-example-data/tutorial/excite.log.bz2' 
               USING PigStorage('\t') 
                  AS (user_id:chararray, timestamp:chararray, query:chararray);
    
    user_searches = GROUP searches by user_id;
    
    word_length =  FOREACH user_searches
                  GENERATE avg_word_length(searches) as average_word_length;

and leave the Python section blank.

If you have a script that uses some shared python UDFs stored in S3 and some custom UDFs defined in the Python section of Hawk the only restriction is that all UDFs must be distinctly named (similar to if all python code was defined in one single file).

<a name='keep_cluster_running'></a>
# Keeping a Cluster Running for Development

Generally, Hawk jobs are run on single-use, per-job Hadoop clusters.  However, as you're developing, it can be helpful to keep a cluster running to rapidly test modifications to your scripts without waiting for a new cluster to launch.

To keep a cluster running, all you need to do is check the "Keep cluster running after job finishes" checkbox when running your job:

![Keep Cluster Running After Job Finishes](https://github.com/mortardata/handbook/raw/master/assets/keep_cluster_running/run_job-keep_cluster_running.png)

As soon as the cluster for your job has started, you will be able to use it for any new jobs as well.  To do so, select an "Existing Cluster" option from the "Hadoop Cluster" dropdown on the Run Job popup:

![Run on Existing Cluster](https://github.com/mortardata/handbook/raw/master/assets/keep_cluster_running/run_job-existing_cluster.png)

Hawk will automatically shut down your cluster after it is idle (no jobs running) for 1 hour.
