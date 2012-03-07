![Mortar Logo](https://github.com/mortardata/handbook/raw/master/assets/mortar_logo_type.png)

# The Mortar Hawk Handbook

A simple, work-in-progress guide to using Mortar Hawk.  


# Table of Contents

* [Adding Parameters to Your Script](#parameters)
* [Using Pig Macros](#macros)

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
Let's look at an example where a macro would be helpful.  Imagine that, using our NYSE data, we'd like to write a script that can get the price data for any range of years.  We can do this with a macro.  The macro would look like:

	-- macro to get NYSE data for a given year
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

	-- macro to get NYSE data for a given year
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




