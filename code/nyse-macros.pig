-- macro to get NYSE data between two years
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

-- macro to get NYSE data grouped by stock symbol
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
