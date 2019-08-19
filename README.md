# SQL-projects

Awesome or interesting SQL queries that must never be forgotten and that might be used again by me. These are of limited interest and applicability to the general public.


## latent-semantic-analysis.sql

Early NLP work, fully in database with a stored procedure.

A SP in 2013 MySQL idiom that uses the [General Harvard Inquirer](http://www.wjh.harvard.edu/~inquirer/j1_1/manual/) dictionary to initalize a SVM. The SVM then, through multiple epochs, inflects the words of the corpus under study with an emotional / semantic payload. This code was used to track authorship and radicalization on BB message boards through measuring the changing emotional content of the messages over time. *The logic and the full analysis belong to a research scientist friend, and are not available here.* I implemented this portion of the workflow in MySQL because it was faster to run in-database than as Python scripts. Maybe I'll need it again!

## aggregated-ticketing-report.sql

Business logic in SQL. Detailed `SQL` to pull summary reporting from some legacy database tables.

## technical-indicators-RSI-SMA.sql

Using [MariaDB window functions](https://mariadb.com/kb/en/library/window-functions/. Mocking up some technical indicators to quickly add SMA and RSI columns to db tables of stock market data. This, after being annoyed upon finding no mature project to make TAs as stored procedures. Probably time to look again...

## laravel-messenger-improvement.sql

[Fixing an issue](https://github.com/cmgmyr/laravel-messenger/issues/280) where some queries were very slow for the Laravel Messenger library, using a modestly large databse of seeding data. This query cuts the response time from 3 minutes to 0.09 seconds. Putting this here because I know I'll forget when I need to support that site in teh future.

## oracle-to-mysql-converter.sql

Stored procedure. Convenience function in MySQL to convert `str` fields we were getting from Oracle exports. Makes strings of various formats into date / datetime fields. *Not sure where I got this idea from originally!*