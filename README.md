![Mortar Logo](https://github.com/mortardata/handbook/raw/master/assets/mortar_logo_type.png)

# The Mortar Hawk Handbook

A simple, work-in-progress guide to using Mortar Hawk.  


# Table of Contents

* [Adding Parameters to Your Script](#parameters)

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
