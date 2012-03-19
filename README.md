![Mortar Logo](https://github.com/mortardata/handbook/raw/master/assets/mortar_logo_type.png)

# The Mortar Hawk Handbook

A simple, work-in-progress guide to using Mortar Hawk.  


# Table of Contents

* [Adding Parameters to Your Script](#parameters)
* [Using Pig Macros](#macros)
* [Using Python from S3](#s3_python)
* [Keeping a Cluster Running for Development](#keep_cluster_running)

<a name='parameters'></a>
# Adding Parameters to Your Script


You'll often want to run a script on different data sets or with different conditions.  Script parameters allow you to run the same Hawk script with different parameters.

 
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

Now, whenever we launch this job, Hawk will let us define the stock we want to analyze:

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
    avg_word_length =  FOREACH user_searches
                       GENERATE avg_word_length(searches) as avg_word_length;

Python:

    @outputSchema('avg_word_length:double')
    def avg_word_length(bag):
        """
        Get the average word length in each search.
        """
        num_chars_total = 0
        num_words_total = 0
        for tpl in bag:
            query = tpl[2]
            words = query.split(' ')
            num_words = len(words)
            num_chars = sum([len(word) for word in words])
    
            num_words_total += num_words
            num_chars_total += num_chars
    
        return float(num_chars_total) / float(num_words_total)

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
    
    avg_word_length =  FOREACH user_searches
                    GENERATE avg_word_length(searches) as avg_word_length;

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
