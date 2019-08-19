-- ############################################################
-- RSI
-- Building by hand for now.
-- Relative Strength Index (RSI) Analysis The relative strength index (RSI) 
-- is a momentum osciallator that is able to measure the velocity and magnitude
-- of stock price changes. Momentum is calculated as the ratio of positive price
-- changes to negative price changes.

ALTER TABLE `tradestat` ADD `rsi14` DOUBLE(7,4);


UPDATE `tradestat` temp_table_1, (
	SELECT
		temp_table_3.*,
		100 - (100 / (1 + (temp_table_3.numerator / ABS(temp_table_3.divisor)))) as `RS14`
	FROM (
		SELECT date, symbol, close,
			AVG(CASE WHEN close - open > 0 THEN close - open END)
				OVER (PARTITION BY symbol ORDER BY `date` ROWS BETWEEN 14 PRECEDING and 0 PRECEDING) as `numerator`,
			AVG(CASE WHEN open - close > 0 THEN open - close END)
				OVER (PARTITION BY symbol ORDER BY `date` ROWS BETWEEN 14 PRECEDING and 0 PRECEDING) as `divisor`
		FROM tradestat
	) temp_table_3
) temp_table_2
SET
	temp_table_1.rsi14 = temp_table_2.RS14
WHERE temp_table_1.symbol = temp_table_2.symbol
AND temp_table_1.date = temp_table_2.date
;


-- ############################################################
-- SMAs via window functions
ALTER TABLE `tradestat` ADD `sma10` DOUBLE(12,4);
ALTER TABLE `tradestat` ADD `sma50` DOUBLE(12,4);
ALTER TABLE `tradestat` ADD `sma200` DOUBLE(12,4);

UPDATE `tradestat` temp_table_1, (
	SELECT 
		date,
		symbol,
		close,
		AVG(close) OVER (PARTITION BY symbol ORDER BY `date` ROWS BETWEEN 10 PRECEDING AND 0 PRECEDING) as `sma10`,
		AVG(close) OVER (PARTITION BY symbol ORDER BY `date` ROWS BETWEEN 50 PRECEDING AND 0 PRECEDING) as `sma50`,
		AVG(close) OVER (PARTITION BY symbol ORDER BY `date` ROWS BETWEEN 200 PRECEDING AND 0 PRECEDING) as `sma200`
	FROM tradestat
) temp_table_2
SET
	temp_table_1.sma10 = temp_table_2.sma10,
	temp_table_1.sma50 = temp_table_2.sma50,
	temp_table_1.sma200 = temp_table_2.sma200
WHERE temp_table_1.symbol = temp_table_2.symbol
AND temp_table_1.date = temp_table_2.date
;

