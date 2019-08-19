-- Stored procedure
-- Convert odd str fields that are coming from Oracle 
-- exports into something which MySQL's flavor of SQL can handle
--
-- Usage
-- select id, name, sname, timezone, to_char(starts, 'YYYY MM DD HH24 MI AM') as starts_split from evts;

DROP FUNCTION IF EXISTS to_char;
DELIMITER //
CREATE FUNCTION to_char (infield tinytext, fmt TINYTEXT) 
	RETURNS TINYTEXT
	DETERMINISTIC
BEGIN
  DECLARE outfield TINYTEXT;

	IF fmt = 'YYYY MM DD HH24 MI AM' THEN 
	set outfield = date_format(infield, '%Y %c %d %k %i %p');
	END IF;
	
	IF fmt = 'YYYY MM DD' THEN
	set outfield = date_format(infield, '%Y %c %d');
	END IF;
	
	IF fmt = 'MM-DD-YYYY' THEN
	set outfield = date_format(infield, '%c-%d-%Y');
	END IF;

	IF fmt = 'Month ddth, YYYY' THEN
	set outfield = date_format(infield, '%M %D, %Y');
	END IF;
	
	IF fmt = 'Mon dd YYYY' THEN
	set outfield = date_format(infield, '%M %D %Y');
	END IF;
	
	if fmt = 'hh:mi a.m. Mon dd YYYY' THEN
	set outfield = date_format(infield, '%l:%i %p %M %D %Y');
	END IF;

	IF fmt = 'Day, hh:mi am' THEN
	set outfield = date_format(infield, '%W %l:%i %p');
	END IF;

	IF fmt = 'j' THEN
	set outfield = unix_timestamp(infield) / 60 / 60 / 24;
	END IF;

	IF fmt = 'HH24:MI MM-DD-YYYY' THEN
	set outfield = date_format(infield, '%k:%i %c-%d-%Y');
	END IF;

	IF fmt = 'MM' THEN
	set outfield = date_format(infield, '%c');
	END IF;

	IF fmt = 'DD' THEN
	set outfield = date_format(infield, '%d');
	END IF;

	IF fmt = 'YYYY' THEN
	set outfield = date_format(infield, '%Y');
	END IF;

	IF fmt = 'HH24' THEN
	set outfield = date_format(infield, '%k');
	END IF;

	IF fmt = 'MI' THEN
	set outfield = date_format(infield, '%i');
	END IF;

	IF fmt = 'fm9,999,999.90' THEN
	set outfield = format(infield,2);
	END IF;
	
	IF fmt = '9999999.90' THEN
	-- set outfield = format(infield,2);
	set outfield = infield;
	END IF;
	
	IF fmt = '9999990.90' THEN
	set outfield = infield;
	END IF;

	RETURN outfield;
END //
DELIMITER ;

