![Mortar Logo](https://github.com/mortardata/handbook/raw/master/assets/mortar_logo_type.png)

# The Mortar Handbook

A simple, work-in-progress guide to using Mortar.  


# Table of Contents

* [Quick-Start](#quick-start)
 * [Demo Script](#demo-script)
 * [Script from Scratch](#script-from-scratch) 
* [Adding Parameters to Your Script](#parameters)

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
Highlight one of the Pig variables, `top_density` for example. Click the Illustrate button at the top right. ![Illustrate button](http://dl.dropbox.com/u/155396/button-illustrate.png)

Illustrate will check that your code will run, and will show you the data flowing through each step of your script (load, filter, etc.) until it reaches `top_density`. Illustrate will take less than a minute to do sophisticated sampling; much faster than manually curating the subset of the data yourself.

### Run
To make the run finish faster, switch the 'songs' alias to load one file `s3n://tbmmsd/A.tsv.a` instead of the full dataset.

Click the Run button. ![Run button](http://dl.dropbox.com/u/155396/button-run.png)

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

![AWS Key Console](http://dl.dropbox.com/u/155396/aws-access-keys.png)

### Set up S3
Download the  [Austin Daily Weather](http://dl.dropbox.com/u/155396/central_texas_daily_weather.tsv.bz2) dataset and then upload it into your s3 bucket. [s3cmd](http://s3tools.org/s3cmd) and [Transmit](https://panic.com/transmit/) (recommended) work well to upload directly to s3.

**Transmit**

Download and install [Transmit](https://panic.com/transmit/). Launch it, and provide the same Access Key and Secret Access Key you used in the prior step. You can leave the Initial Path field empty.

![Transmit AWS Key Entry](http://dl.dropbox.com/u/155396/transmit-keys.png)

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

![Download Results](http://dl.dropbox.com/u/155396/hottest-download-results.png)

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

Let's take an example of a script that analyzes New York Stock Exchange (NYSE) data.  Imagine that we have a script that analyzes data for only the Apple Inc. (APPL) stock:

    -- load up the NYSE daily price data    
	nyse_daily_prices = LOAD 's3n://hawk-example-data/NYSE/daily_prices' 
                       USING PigStorage(',')
                          AS (exchange:chararray, stock_symbol:chararray, date:chararray, 
                              stock_price_open:float, stock_price_high:float,
                              stock_price_low:float, stock_price_close:float, stock_volume:long,
                              stock_price_adj_close:float);

    -- filter to get just the stock we want
    my_stock_only = FILTER nyse_daily_prices BY stock_symbol == 'APPL';


Let's parameterize this script to make it run on **any** stock.  We'll add a script parameter at the top of the script:

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
