-- See description in README.md
-- Latent semantic analysis using Harvard Dict to inflect a corpus of posts or messages.
-- 
-- To run this procedure:
-- mysql> call runLSA(bboard_tablename, newdictionaryname)
-- Sample:
-- 	mysql> call runLSA('bbposts', 'semantic_dictionary');

DELIMITER ;
DROP PROCEDURE IF EXISTS runLSA;
DELIMITER //

CREATE PROCEDURE runLSA (IN srctable tinytext, IN dictionary tinytext)
LANGUAGE SQL
NOT DETERMINISTIC
CONTAINS SQL
proc:

BEGIN
	DECLARE workWord tinytext;
	DECLARE i int(6);
	DECLARE iterationMax int(6);
	DECLARE no_more_words int(1);
	DECLARE word_cursor CURSOR FOR SELECT word from lsa_word_lookup_thread;
	DECLARE CONTINUE HANDLER FOR NOT FOUND SET no_more_words=1;
	SET iterationMax = 10000; -- 1000000 this will change...
	select @delta := 50 from t1; -- is this how we do it!?

	-- Cache tables
	DROP TABLE IF EXISTS vector_word; CREATE TABLE IF NOT EXISTS vector_word   select * from harvard where 1=2; DELETE FROM vector_word;
	DROP TABLE IF EXISTS vector_post; CREATE TABLE IF NOT EXISTS vector_post   select * from harvard where 1=2; DELETE FROM vector_post;
	DROP TABLE IF EXISTS vector_delta; CREATE TABLE IF NOT EXISTS vector_delta select * from harvard where 1=2; DELETE FROM vector_delta;

	SET i=0;
	myloop: LOOP
	
		IF i>iterationMax THEN
			LEAVE myloop;
		END IF;
		
		-- Prepare some statements
		SET @offSetQuery = concat('SELECT @offSet := FLOOR(RAND() * (SELECT COUNT(*) FROM `',srctable,'`))');
		PREPARE STMT FROM @offSetQuery;
		EXECUTE STMT;
		-- SET @randRow = concat('SELECT @randRowID := id FROM `', srctable, '` limit ',@offSet,',1');
		SET @randRow = concat('SELECT @randRowID := id FROM `', srctable, '` limit ',@offSet,',1');
		PREPARE STMT_RANDROW FROM @randRow;
		EXECUTE STMT_RANDROW;

		SET @tmpQuery = concat('SELECT @ID := id FROM `', srctable, '` where id= ', @randRowID,'');
		PREPARE STMT_ID FROM @tmpQuery;
		EXECUTE STMT_ID;

		-- Clean up cache tables to receive list of words in the post
		DELETE FROM vector_word;
		DELETE FROM vector_post;

		-- Select the word we're going to nudge
		SET @offSetQuery = concat('SELECT @offSet := FLOOR( RAND() * (SELECT COUNT(*) FROM `lsa_word_lookup_minus` WHERE id = ',@ID,'))');
		PREPARE STMT FROM @offSetQuery;
		EXECUTE STMT;
		SET @tmpQuery = concat('SELECT @randWord := word from `lsa_word_lookup_minus` WHERE id = ', @ID,' LIMIT ',@offSet,', 1');
		PREPARE STMT FROM @tmpQuery;
		EXECUTE STMT;

		-- Get the number of words in this post
		SET @tmpQuery = concat('SELECT count(*) from `lsa_word_lookup` WHERE id = ', @ID, ' INTO @postWordCount');
		PREPARE STMT FROM @tmpQuery;
		EXECUTE STMT;

		DROP TABLE IF EXISTS lsa_word_lookup_thread;
		SET @tmpQuery = concat('CREATE TABLE lsa_word_lookup_thread SELECT * FROM lsa_word_lookup WHERE id = ', @ID); 
		PREPARE STMT FROM @tmpQuery;
		EXECUTE STMT;

		-- Cumulatively build the post vector
		OPEN word_cursor;
		word_loop: LOOP
			FETCH word_cursor INTO workWord;
			IF (no_more_words) THEN
				LEAVE word_loop;
			END IF;

			-- DELETE FROM vector_word;
			
			-- Match workWord to either harvard or unanchored dictionary
			SET @tmpQuery = concat('insert into vector_word select * from `harvard` where stemmed = \'', workWord, '\'');
			PREPARE stmt1 FROM @tmpQuery;
			EXECUTE stmt1;
			SET @tmpQuery = concat('insert into vector_word select * from `', dictionary, '` where word = \'', workWord, '\'');
			PREPARE stmt1 FROM @tmpQuery;
			EXECUTE stmt1;

			-- select concat('End of loop with workWord: ', workWord, ', and nudge word ', @randWord, '!') Notification;

		END LOOP;
		CLOSE word_cursor;
		SET no_more_words=0;

		-- Sum all the word vectors into vector_post
		insert into vector_post 
		(select 
			NULL,'x'
			,'x' --`stemmed` field
			,sum(w.positiv   ) / @postWordCount
			,sum(w.negativ   ) / @postWordCount
			,sum(w.pstv      ) / @postWordCount
			,sum(w.affil     ) / @postWordCount
			,sum(w.ngtv      ) / @postWordCount
			,sum(w.hostile   ) / @postWordCount
			,sum(w.strong    ) / @postWordCount
			,sum(w.power     ) / @postWordCount
			,sum(w.weak      ) / @postWordCount
			,sum(w.submit    ) / @postWordCount
			,sum(w.active    ) / @postWordCount
			,sum(w.passive   ) / @postWordCount
			,sum(w.pleasur   ) / @postWordCount
			,sum(w.pain      ) / @postWordCount
			,sum(w.feel      ) / @postWordCount
			,sum(w.arousal   ) / @postWordCount
			,sum(w.emot      ) / @postWordCount
			,sum(w.virtue    ) / @postWordCount
			,sum(w.vice      ) / @postWordCount
			,sum(w.ovrst     ) / @postWordCount
			,sum(w.undrst    ) / @postWordCount
			,sum(w.academ    ) / @postWordCount
			,sum(w.doctrin   ) / @postWordCount
			,sum(w.econ      ) / @postWordCount
			,sum(w.exch      ) / @postWordCount
			,sum(w.econ_b    ) / @postWordCount
			,sum(w.exprsv    ) / @postWordCount
			,sum(w.legal     ) / @postWordCount
			,sum(w.milit     ) / @postWordCount
			,sum(w.polit     ) / @postWordCount
			,sum(w.polit_b   ) / @postWordCount
			,sum(w.relig     ) / @postWordCount
			,sum(w.role      ) / @postWordCount
			,sum(w.coll      ) / @postWordCount
			,sum(w.work      ) / @postWordCount
			,sum(w.ritual    ) / @postWordCount
			,sum(w.socrel    ) / @postWordCount
			,sum(w.race      ) / @postWordCount
			,sum(w.kin       ) / @postWordCount
			,sum(w.male      ) / @postWordCount
			,sum(w.female    ) / @postWordCount
			,sum(w.nonadlt   ) / @postWordCount
			,sum(w.hu        ) / @postWordCount
			,sum(w.ani       ) / @postWordCount
			,sum(w.place     ) / @postWordCount
			,sum(w.social    ) / @postWordCount
			,sum(w.region    ) / @postWordCount
			,sum(w.route     ) / @postWordCount
			,sum(w.aquatic   ) / @postWordCount
			,sum(w.land      ) / @postWordCount
			,sum(w.sky       ) / @postWordCount
			,sum(w.object    ) / @postWordCount
			,sum(w.tool      ) / @postWordCount
			,sum(w.food      ) / @postWordCount
			,sum(w.vehicle   ) / @postWordCount
			,sum(w.bldgpt    ) / @postWordCount
			,sum(w.comnobj   ) / @postWordCount
			,sum(w.natobj    ) / @postWordCount
			,sum(w.bodypt    ) / @postWordCount
			,sum(w.comform   ) / @postWordCount
			,sum(w.com       ) / @postWordCount
			,sum(w.say       ) / @postWordCount
			,sum(w.need      ) / @postWordCount
			,sum(w.goal      ) / @postWordCount
			,sum(w.try       ) / @postWordCount
			,sum(w.means     ) / @postWordCount
			,sum(w.persist   ) / @postWordCount
			,sum(w.complet   ) / @postWordCount
			,sum(w.fail      ) / @postWordCount
			,sum(w.natrpro   ) / @postWordCount
			,sum(w.begin     ) / @postWordCount
			,sum(w.vary      ) / @postWordCount
			,sum(w.increas   ) / @postWordCount
			,sum(w.decreas   ) / @postWordCount
			,sum(w.finish    ) / @postWordCount
			,sum(w.stay      ) / @postWordCount
			,sum(w.rise      ) / @postWordCount
			,sum(w.exert     ) / @postWordCount
			,sum(w.fetch     ) / @postWordCount
			,sum(w.travel    ) / @postWordCount
			,sum(w.fall      ) / @postWordCount
			,sum(w.think     ) / @postWordCount
			,sum(w.know      ) / @postWordCount
			,sum(w.causal    ) / @postWordCount
			,sum(w.ought     ) / @postWordCount
			,sum(w.perceiv   ) / @postWordCount
			,sum(w.compare   ) / @postWordCount
			,sum(w.eval      ) / @postWordCount
			,sum(w.eval_b    ) / @postWordCount
			,sum(w.solve     ) / @postWordCount
			,sum(w.abs       ) / @postWordCount
			,sum(w.abs_b     ) / @postWordCount
			,sum(w.quality   ) / @postWordCount
			,sum(w.quan      ) / @postWordCount
			,sum(w.numb      ) / @postWordCount
			,sum(w.ord       ) / @postWordCount
			,sum(w.card      ) / @postWordCount
			,sum(w.freq      ) / @postWordCount
			,sum(w.dist      ) / @postWordCount
			,sum(w.time      ) / @postWordCount
			,sum(w.time_b    ) / @postWordCount
			,sum(w.space     ) / @postWordCount
			,sum(w.pos       ) / @postWordCount
			,sum(w.dim       ) / @postWordCount
			,sum(w.rel       ) / @postWordCount
			,sum(w.color     ) / @postWordCount
			,sum(w.self      ) / @postWordCount
			,sum(w.our       ) / @postWordCount
			,sum(w.you       ) / @postWordCount
			,sum(w.name      ) / @postWordCount
			,sum(w.yes       ) / @postWordCount
			,sum(w.no        ) / @postWordCount
			,sum(w.negate    ) / @postWordCount
			,sum(w.intrj     ) / @postWordCount
			,sum(w.iav       ) / @postWordCount
			,sum(w.dav       ) / @postWordCount
			,sum(w.sv        ) / @postWordCount
			,sum(w.ipadj     ) / @postWordCount
			,sum(w.indadj    ) / @postWordCount
			,sum(w.powgain   ) / @postWordCount
			,sum(w.powloss   ) / @postWordCount
			,sum(w.powends   ) / @postWordCount
			,sum(w.powaren   ) / @postWordCount
			,sum(w.powcon    ) / @postWordCount
			,sum(w.powcoop   ) / @postWordCount
			,sum(w.powaupt   ) / @postWordCount
			,sum(w.powpt     ) / @postWordCount
			,sum(w.powdoct   ) / @postWordCount
			,sum(w.powauth   ) / @postWordCount
			,sum(w.powoth    ) / @postWordCount
			,sum(w.powtot    ) / @postWordCount
			,sum(w.rcethic   ) / @postWordCount
			,sum(w.rcrelig   ) / @postWordCount
			,sum(w.rcgain    ) / @postWordCount
			,sum(w.rcloss    ) / @postWordCount
			,sum(w.rcends    ) / @postWordCount
			,sum(w.rctot     ) / @postWordCount
			,sum(w.rspgain   ) / @postWordCount
			,sum(w.rsploss   ) / @postWordCount
			,sum(w.rspoth    ) / @postWordCount
			,sum(w.rsptot    ) / @postWordCount
			,sum(w.affgain   ) / @postWordCount
			,sum(w.affloss   ) / @postWordCount
			,sum(w.affpt     ) / @postWordCount
			,sum(w.affoth    ) / @postWordCount
			,sum(w.afftot    ) / @postWordCount
			,sum(w.wltpt     ) / @postWordCount
			,sum(w.wlttran   ) / @postWordCount
			,sum(w.wltoth    ) / @postWordCount
			,sum(w.wlttot    ) / @postWordCount
			,sum(w.wlbgain   ) / @postWordCount
			,sum(w.wlbloss   ) / @postWordCount
			,sum(w.wlbphys   ) / @postWordCount
			,sum(w.wlbpsyc   ) / @postWordCount
			,sum(w.wlbpt     ) / @postWordCount
			,sum(w.wlbtot    ) / @postWordCount
			,sum(w.enlgain   ) / @postWordCount
			,sum(w.enlloss   ) / @postWordCount
			,sum(w.enlends   ) / @postWordCount
			,sum(w.enlpt     ) / @postWordCount
			,sum(w.enloth    ) / @postWordCount
			,sum(w.enltot    ) / @postWordCount
			,sum(w.sklasth   ) / @postWordCount
			,sum(w.sklpt     ) / @postWordCount
			,sum(w.skloth    ) / @postWordCount
			,sum(w.skltot    ) / @postWordCount
			,sum(w.trngain   ) / @postWordCount
			,sum(w.trnloss   ) / @postWordCount
			,sum(w.tranlw    ) / @postWordCount
			,sum(w.meanslw   ) / @postWordCount
			,sum(w.endslw    ) / @postWordCount
			,sum(w.arenalw   ) / @postWordCount
			,sum(w.ptlw      ) / @postWordCount
			,sum(w.nation    ) / @postWordCount
			,sum(w.anomie    ) / @postWordCount
			,sum(w.negaff    ) / @postWordCount
			,sum(w.posaff    ) / @postWordCount
			,sum(w.surelw    ) / @postWordCount
			,sum(w.if        ) / @postWordCount
			,sum(w.notlw     ) / @postWordCount
			,sum(w.timespc   ) / @postWordCount
			,sum(w.formlw    ) / @postWordCount
			,'',''
		from vector_word w);

		-- select * from vector_post;

		-- Clean up some vectors
		delete from vector_word;
		delete from vector_delta;

		-- Insert workword's vector
		SET @tmpQuery = concat('insert into vector_word select * from `', dictionary, '` where word = \'', @randWord, '\'');
		PREPARE stmt1 FROM @tmpQuery;
		EXECUTE stmt1;
		
		-- vector_delta = (vector_post - vector_word) / @delta
		update vector_delta d, vector_post p, vector_word w 
		set 
			 d.positiv   = ( p.positiv   - w.positiv   ) / @delta
			,d.negativ   = ( p.negativ   - w.negativ   ) / @delta
			,d.pstv      = ( p.pstv      - w.pstv      ) / @delta
			,d.affil     = ( p.affil     - w.affil     ) / @delta
			,d.ngtv      = ( p.ngtv      - w.ngtv      ) / @delta
			,d.hostile   = ( p.hostile   - w.hostile   ) / @delta
			,d.strong    = ( p.strong    - w.strong    ) / @delta
			,d.power     = ( p.power     - w.power     ) / @delta
			,d.weak      = ( p.weak      - w.weak      ) / @delta
			,d.submit    = ( p.submit    - w.submit    ) / @delta
			,d.active    = ( p.active    - w.active    ) / @delta
			,d.passive   = ( p.passive   - w.passive   ) / @delta
			,d.pleasur   = ( p.pleasur   - w.pleasur   ) / @delta
			,d.pain      = ( p.pain      - w.pain      ) / @delta
			,d.feel      = ( p.feel      - w.feel      ) / @delta
			,d.arousal   = ( p.arousal   - w.arousal   ) / @delta
			,d.emot      = ( p.emot      - w.emot      ) / @delta
			,d.virtue    = ( p.virtue    - w.virtue    ) / @delta
			,d.vice      = ( p.vice      - w.vice      ) / @delta
			,d.ovrst     = ( p.ovrst     - w.ovrst     ) / @delta
			,d.undrst    = ( p.undrst    - w.undrst    ) / @delta
			,d.academ    = ( p.academ    - w.academ    ) / @delta
			,d.doctrin   = ( p.doctrin   - w.doctrin   ) / @delta
			,d.econ      = ( p.econ      - w.econ      ) / @delta
			,d.exch      = ( p.exch      - w.exch      ) / @delta
			,d.econ_b    = ( p.econ_b    - w.econ_b    ) / @delta
			,d.exprsv    = ( p.exprsv    - w.exprsv    ) / @delta
			,d.legal     = ( p.legal     - w.legal     ) / @delta
			,d.milit     = ( p.milit     - w.milit     ) / @delta
			,d.polit     = ( p.polit     - w.polit     ) / @delta
			,d.polit_b   = ( p.polit_b   - w.polit_b   ) / @delta
			,d.relig     = ( p.relig     - w.relig     ) / @delta
			,d.role      = ( p.role      - w.role      ) / @delta
			,d.coll      = ( p.coll      - w.coll      ) / @delta
			,d.work      = ( p.work      - w.work      ) / @delta
			,d.ritual    = ( p.ritual    - w.ritual    ) / @delta
			,d.socrel    = ( p.socrel    - w.socrel    ) / @delta
			,d.race      = ( p.race      - w.race      ) / @delta
			,d.kin       = ( p.kin       - w.kin       ) / @delta
			,d.male      = ( p.male      - w.male      ) / @delta
			,d.female    = ( p.female    - w.female    ) / @delta
			,d.nonadlt   = ( p.nonadlt   - w.nonadlt   ) / @delta
			,d.hu        = ( p.hu        - w.hu        ) / @delta
			,d.ani       = ( p.ani       - w.ani       ) / @delta
			,d.place     = ( p.place     - w.place     ) / @delta
			,d.social    = ( p.social    - w.social    ) / @delta
			,d.region    = ( p.region    - w.region    ) / @delta
			,d.route     = ( p.route     - w.route     ) / @delta
			,d.aquatic   = ( p.aquatic   - w.aquatic   ) / @delta
			,d.land      = ( p.land      - w.land      ) / @delta
			,d.sky       = ( p.sky       - w.sky       ) / @delta
			,d.object    = ( p.object    - w.object    ) / @delta
			,d.tool      = ( p.tool      - w.tool      ) / @delta
			,d.food      = ( p.food      - w.food      ) / @delta
			,d.vehicle   = ( p.vehicle   - w.vehicle   ) / @delta
			,d.bldgpt    = ( p.bldgpt    - w.bldgpt    ) / @delta
			,d.comnobj   = ( p.comnobj   - w.comnobj   ) / @delta
			,d.natobj    = ( p.natobj    - w.natobj    ) / @delta
			,d.bodypt    = ( p.bodypt    - w.bodypt    ) / @delta
			,d.comform   = ( p.comform   - w.comform   ) / @delta
			,d.com       = ( p.com       - w.com       ) / @delta
			,d.say       = ( p.say       - w.say       ) / @delta
			,d.need      = ( p.need      - w.need      ) / @delta
			,d.goal      = ( p.goal      - w.goal      ) / @delta
			,d.try       = ( p.try       - w.try       ) / @delta
			,d.means     = ( p.means     - w.means     ) / @delta
			,d.persist   = ( p.persist   - w.persist   ) / @delta
			,d.complet   = ( p.complet   - w.complet   ) / @delta
			,d.fail      = ( p.fail      - w.fail      ) / @delta
			,d.natrpro   = ( p.natrpro   - w.natrpro   ) / @delta
			,d.begin     = ( p.begin     - w.begin     ) / @delta
			,d.vary      = ( p.vary      - w.vary      ) / @delta
			,d.increas   = ( p.increas   - w.increas   ) / @delta
			,d.decreas   = ( p.decreas   - w.decreas   ) / @delta
			,d.finish    = ( p.finish    - w.finish    ) / @delta
			,d.stay      = ( p.stay      - w.stay      ) / @delta
			,d.rise      = ( p.rise      - w.rise      ) / @delta
			,d.exert     = ( p.exert     - w.exert     ) / @delta
			,d.fetch     = ( p.fetch     - w.fetch     ) / @delta
			,d.travel    = ( p.travel    - w.travel    ) / @delta
			,d.fall      = ( p.fall      - w.fall      ) / @delta
			,d.think     = ( p.think     - w.think     ) / @delta
			,d.know      = ( p.know      - w.know      ) / @delta
			,d.causal    = ( p.causal    - w.causal    ) / @delta
			,d.ought     = ( p.ought     - w.ought     ) / @delta
			,d.perceiv   = ( p.perceiv   - w.perceiv   ) / @delta
			,d.compare   = ( p.compare   - w.compare   ) / @delta
			,d.eval      = ( p.eval      - w.eval      ) / @delta
			,d.eval_b    = ( p.eval_b    - w.eval_b    ) / @delta
			,d.solve     = ( p.solve     - w.solve     ) / @delta
			,d.abs       = ( p.abs       - w.abs       ) / @delta
			,d.abs_b     = ( p.abs_b     - w.abs_b     ) / @delta
			,d.quality   = ( p.quality   - w.quality   ) / @delta
			,d.quan      = ( p.quan      - w.quan      ) / @delta
			,d.numb      = ( p.numb      - w.numb      ) / @delta
			,d.ord       = ( p.ord       - w.ord       ) / @delta
			,d.card      = ( p.card      - w.card      ) / @delta
			,d.freq      = ( p.freq      - w.freq      ) / @delta
			,d.dist      = ( p.dist      - w.dist      ) / @delta
			,d.time      = ( p.time      - w.time      ) / @delta
			,d.time_b    = ( p.time_b    - w.time_b    ) / @delta
			,d.space     = ( p.space     - w.space     ) / @delta
			,d.pos       = ( p.pos       - w.pos       ) / @delta
			,d.dim       = ( p.dim       - w.dim       ) / @delta
			,d.rel       = ( p.rel       - w.rel       ) / @delta
			,d.color     = ( p.color     - w.color     ) / @delta
			,d.self      = ( p.self      - w.self      ) / @delta
			,d.our       = ( p.our       - w.our       ) / @delta
			,d.you       = ( p.you       - w.you       ) / @delta
			,d.name      = ( p.name      - w.name      ) / @delta
			,d.yes       = ( p.yes       - w.yes       ) / @delta
			,d.no        = ( p.no        - w.no        ) / @delta
			,d.negate    = ( p.negate    - w.negate    ) / @delta
			,d.intrj     = ( p.intrj     - w.intrj     ) / @delta
			,d.iav       = ( p.iav       - w.iav       ) / @delta
			,d.dav       = ( p.dav       - w.dav       ) / @delta
			,d.sv        = ( p.sv        - w.sv        ) / @delta
			,d.ipadj     = ( p.ipadj     - w.ipadj     ) / @delta
			,d.indadj    = ( p.indadj    - w.indadj    ) / @delta
			,d.powgain   = ( p.powgain   - w.powgain   ) / @delta
			,d.powloss   = ( p.powloss   - w.powloss   ) / @delta
			,d.powends   = ( p.powends   - w.powends   ) / @delta
			,d.powaren   = ( p.powaren   - w.powaren   ) / @delta
			,d.powcon    = ( p.powcon    - w.powcon    ) / @delta
			,d.powcoop   = ( p.powcoop   - w.powcoop   ) / @delta
			,d.powaupt   = ( p.powaupt   - w.powaupt   ) / @delta
			,d.powpt     = ( p.powpt     - w.powpt     ) / @delta
			,d.powdoct   = ( p.powdoct   - w.powdoct   ) / @delta
			,d.powauth   = ( p.powauth   - w.powauth   ) / @delta
			,d.powoth    = ( p.powoth    - w.powoth    ) / @delta
			,d.powtot    = ( p.powtot    - w.powtot    ) / @delta
			,d.rcethic   = ( p.rcethic   - w.rcethic   ) / @delta
			,d.rcrelig   = ( p.rcrelig   - w.rcrelig   ) / @delta
			,d.rcgain    = ( p.rcgain    - w.rcgain    ) / @delta
			,d.rcloss    = ( p.rcloss    - w.rcloss    ) / @delta
			,d.rcends    = ( p.rcends    - w.rcends    ) / @delta
			,d.rctot     = ( p.rctot     - w.rctot     ) / @delta
			,d.rspgain   = ( p.rspgain   - w.rspgain   ) / @delta
			,d.rsploss   = ( p.rsploss   - w.rsploss   ) / @delta
			,d.rspoth    = ( p.rspoth    - w.rspoth    ) / @delta
			,d.rsptot    = ( p.rsptot    - w.rsptot    ) / @delta
			,d.affgain   = ( p.affgain   - w.affgain   ) / @delta
			,d.affloss   = ( p.affloss   - w.affloss   ) / @delta
			,d.affpt     = ( p.affpt     - w.affpt     ) / @delta
			,d.affoth    = ( p.affoth    - w.affoth    ) / @delta
			,d.afftot    = ( p.afftot    - w.afftot    ) / @delta
			,d.wltpt     = ( p.wltpt     - w.wltpt     ) / @delta
			,d.wlttran   = ( p.wlttran   - w.wlttran   ) / @delta
			,d.wltoth    = ( p.wltoth    - w.wltoth    ) / @delta
			,d.wlttot    = ( p.wlttot    - w.wlttot    ) / @delta
			,d.wlbgain   = ( p.wlbgain   - w.wlbgain   ) / @delta
			,d.wlbloss   = ( p.wlbloss   - w.wlbloss   ) / @delta
			,d.wlbphys   = ( p.wlbphys   - w.wlbphys   ) / @delta
			,d.wlbpsyc   = ( p.wlbpsyc   - w.wlbpsyc   ) / @delta
			,d.wlbpt     = ( p.wlbpt     - w.wlbpt     ) / @delta
			,d.wlbtot    = ( p.wlbtot    - w.wlbtot    ) / @delta
			,d.enlgain   = ( p.enlgain   - w.enlgain   ) / @delta
			,d.enlloss   = ( p.enlloss   - w.enlloss   ) / @delta
			,d.enlends   = ( p.enlends   - w.enlends   ) / @delta
			,d.enlpt     = ( p.enlpt     - w.enlpt     ) / @delta
			,d.enloth    = ( p.enloth    - w.enloth    ) / @delta
			,d.enltot    = ( p.enltot    - w.enltot    ) / @delta
			,d.sklasth   = ( p.sklasth   - w.sklasth   ) / @delta
			,d.sklpt     = ( p.sklpt     - w.sklpt     ) / @delta
			,d.skloth    = ( p.skloth    - w.skloth    ) / @delta
			,d.skltot    = ( p.skltot    - w.skltot    ) / @delta
			,d.trngain   = ( p.trngain   - w.trngain   ) / @delta
			,d.trnloss   = ( p.trnloss   - w.trnloss   ) / @delta
			,d.tranlw    = ( p.tranlw    - w.tranlw    ) / @delta
			,d.meanslw   = ( p.meanslw   - w.meanslw   ) / @delta
			,d.endslw    = ( p.endslw    - w.endslw    ) / @delta
			,d.arenalw   = ( p.arenalw   - w.arenalw   ) / @delta
			,d.ptlw      = ( p.ptlw      - w.ptlw      ) / @delta
			,d.nation    = ( p.nation    - w.nation    ) / @delta
			,d.anomie    = ( p.anomie    - w.anomie    ) / @delta
			,d.negaff    = ( p.negaff    - w.negaff    ) / @delta
			,d.posaff    = ( p.posaff    - w.posaff    ) / @delta
			,d.surelw    = ( p.surelw    - w.surelw    ) / @delta
			,d.if        = ( p.if        - w.if        ) / @delta
			,d.notlw     = ( p.notlw     - w.notlw     ) / @delta
			,d.timespc   = ( p.timespc   - w.timespc   ) / @delta
			,d.formlw    = ( p.formlw    - w.formlw    ) / @delta
		;
		

		-- nudge word_vector
		update vector_word w, vector_delta d
		set 
			 w.positiv   = ( d.positiv   + w.positiv   )
			,w.negativ   = ( d.negativ   + w.negativ   )
			,w.pstv      = ( d.pstv      + w.pstv      )
			,w.affil     = ( d.affil     + w.affil     )
			,w.ngtv      = ( d.ngtv      + w.ngtv      )
			,w.hostile   = ( d.hostile   + w.hostile   )
			,w.strong    = ( d.strong    + w.strong    )
			,w.power     = ( d.power     + w.power     )
			,w.weak      = ( d.weak      + w.weak      )
			,w.submit    = ( d.submit    + w.submit    )
			,w.active    = ( d.active    + w.active    )
			,w.passive   = ( d.passive   + w.passive   )
			,w.pleasur   = ( d.pleasur   + w.pleasur   )
			,w.pain      = ( d.pain      + w.pain      )
			,w.feel      = ( d.feel      + w.feel      )
			,w.arousal   = ( d.arousal   + w.arousal   )
			,w.emot      = ( d.emot      + w.emot      )
			,w.virtue    = ( d.virtue    + w.virtue    )
			,w.vice      = ( d.vice      + w.vice      )
			,w.ovrst     = ( d.ovrst     + w.ovrst     )
			,w.undrst    = ( d.undrst    + w.undrst    )
			,w.academ    = ( d.academ    + w.academ    )
			,w.doctrin   = ( d.doctrin   + w.doctrin   )
			,w.econ      = ( d.econ      + w.econ      )
			,w.exch      = ( d.exch      + w.exch      )
			,w.econ_b    = ( d.econ_b    + w.econ_b    )
			,w.exprsv    = ( d.exprsv    + w.exprsv    )
			,w.legal     = ( d.legal     + w.legal     )
			,w.milit     = ( d.milit     + w.milit     )
			,w.polit     = ( d.polit     + w.polit     )
			,w.polit_b   = ( d.polit_b   + w.polit_b   )
			,w.relig     = ( d.relig     + w.relig     )
			,w.role      = ( d.role      + w.role      )
			,w.coll      = ( d.coll      + w.coll      )
			,w.work      = ( d.work      + w.work      )
			,w.ritual    = ( d.ritual    + w.ritual    )
			,w.socrel    = ( d.socrel    + w.socrel    )
			,w.race      = ( d.race      + w.race      )
			,w.kin       = ( d.kin       + w.kin       )
			,w.male      = ( d.male      + w.male      )
			,w.female    = ( d.female    + w.female    )
			,w.nonadlt   = ( d.nonadlt   + w.nonadlt   )
			,w.hu        = ( d.hu        + w.hu        )
			,w.ani       = ( d.ani       + w.ani       )
			,w.place     = ( d.place     + w.place     )
			,w.social    = ( d.social    + w.social    )
			,w.region    = ( d.region    + w.region    )
			,w.route     = ( d.route     + w.route     )
			,w.aquatic   = ( d.aquatic   + w.aquatic   )
			,w.land      = ( d.land      + w.land      )
			,w.sky       = ( d.sky       + w.sky       )
			,w.object    = ( d.object    + w.object    )
			,w.tool      = ( d.tool      + w.tool      )
			,w.food      = ( d.food      + w.food      )
			,w.vehicle   = ( d.vehicle   + w.vehicle   )
			,w.bldgpt    = ( d.bldgpt    + w.bldgpt    )
			,w.comnobj   = ( d.comnobj   + w.comnobj   )
			,w.natobj    = ( d.natobj    + w.natobj    )
			,w.bodypt    = ( d.bodypt    + w.bodypt    )
			,w.comform   = ( d.comform   + w.comform   )
			,w.com       = ( d.com       + w.com       )
			,w.say       = ( d.say       + w.say       )
			,w.need      = ( d.need      + w.need      )
			,w.goal      = ( d.goal      + w.goal      )
			,w.try       = ( d.try       + w.try       )
			,w.means     = ( d.means     + w.means     )
			,w.persist   = ( d.persist   + w.persist   )
			,w.complet   = ( d.complet   + w.complet   )
			,w.fail      = ( d.fail      + w.fail      )
			,w.natrpro   = ( d.natrpro   + w.natrpro   )
			,w.begin     = ( d.begin     + w.begin     )
			,w.vary      = ( d.vary      + w.vary      )
			,w.increas   = ( d.increas   + w.increas   )
			,w.decreas   = ( d.decreas   + w.decreas   )
			,w.finish    = ( d.finish    + w.finish    )
			,w.stay      = ( d.stay      + w.stay      )
			,w.rise      = ( d.rise      + w.rise      )
			,w.exert     = ( d.exert     + w.exert     )
			,w.fetch     = ( d.fetch     + w.fetch     )
			,w.travel    = ( d.travel    + w.travel    )
			,w.fall      = ( d.fall      + w.fall      )
			,w.think     = ( d.think     + w.think     )
			,w.know      = ( d.know      + w.know      )
			,w.causal    = ( d.causal    + w.causal    )
			,w.ought     = ( d.ought     + w.ought     )
			,w.perceiv   = ( d.perceiv   + w.perceiv   )
			,w.compare   = ( d.compare   + w.compare   )
			,w.eval      = ( d.eval      + w.eval      )
			,w.eval_b    = ( d.eval_b    + w.eval_b    )
			,w.solve     = ( d.solve     + w.solve     )
			,w.abs       = ( d.abs       + w.abs       )
			,w.abs_b     = ( d.abs_b     + w.abs_b     )
			,w.quality   = ( d.quality   + w.quality   )
			,w.quan      = ( d.quan      + w.quan      )
			,w.numb      = ( d.numb      + w.numb      )
			,w.ord       = ( d.ord       + w.ord       )
			,w.card      = ( d.card      + w.card      )
			,w.freq      = ( d.freq      + w.freq      )
			,w.dist      = ( d.dist      + w.dist      )
			,w.time      = ( d.time      + w.time      )
			,w.time_b    = ( d.time_b    + w.time_b    )
			,w.space     = ( d.space     + w.space     )
			,w.pos       = ( d.pos       + w.pos       )
			,w.dim       = ( d.dim       + w.dim       )
			,w.rel       = ( d.rel       + w.rel       )
			,w.color     = ( d.color     + w.color     )
			,w.self      = ( d.self      + w.self      )
			,w.our       = ( d.our       + w.our       )
			,w.you       = ( d.you       + w.you       )
			,w.name      = ( d.name      + w.name      )
			,w.yes       = ( d.yes       + w.yes       )
			,w.no        = ( d.no        + w.no        )
			,w.negate    = ( d.negate    + w.negate    )
			,w.intrj     = ( d.intrj     + w.intrj     )
			,w.iav       = ( d.iav       + w.iav       )
			,w.dav       = ( d.dav       + w.dav       )
			,w.sv        = ( d.sv        + w.sv        )
			,w.ipadj     = ( d.ipadj     + w.ipadj     )
			,w.indadj    = ( d.indadj    + w.indadj    )
			,w.powgain   = ( d.powgain   + w.powgain   )
			,w.powloss   = ( d.powloss   + w.powloss   )
			,w.powends   = ( d.powends   + w.powends   )
			,w.powaren   = ( d.powaren   + w.powaren   )
			,w.powcon    = ( d.powcon    + w.powcon    )
			,w.powcoop   = ( d.powcoop   + w.powcoop   )
			,w.powaupt   = ( d.powaupt   + w.powaupt   )
			,w.powpt     = ( d.powpt     + w.powpt     )
			,w.powdoct   = ( d.powdoct   + w.powdoct   )
			,w.powauth   = ( d.powauth   + w.powauth   )
			,w.powoth    = ( d.powoth    + w.powoth    )
			,w.powtot    = ( d.powtot    + w.powtot    )
			,w.rcethic   = ( d.rcethic   + w.rcethic   )
			,w.rcrelig   = ( d.rcrelig   + w.rcrelig   )
			,w.rcgain    = ( d.rcgain    + w.rcgain    )
			,w.rcloss    = ( d.rcloss    + w.rcloss    )
			,w.rcends    = ( d.rcends    + w.rcends    )
			,w.rctot     = ( d.rctot     + w.rctot     )
			,w.rspgain   = ( d.rspgain   + w.rspgain   )
			,w.rsploss   = ( d.rsploss   + w.rsploss   )
			,w.rspoth    = ( d.rspoth    + w.rspoth    )
			,w.rsptot    = ( d.rsptot    + w.rsptot    )
			,w.affgain   = ( d.affgain   + w.affgain   )
			,w.affloss   = ( d.affloss   + w.affloss   )
			,w.affpt     = ( d.affpt     + w.affpt     )
			,w.affoth    = ( d.affoth    + w.affoth    )
			,w.afftot    = ( d.afftot    + w.afftot    )
			,w.wltpt     = ( d.wltpt     + w.wltpt     )
			,w.wlttran   = ( d.wlttran   + w.wlttran   )
			,w.wltoth    = ( d.wltoth    + w.wltoth    )
			,w.wlttot    = ( d.wlttot    + w.wlttot    )
			,w.wlbgain   = ( d.wlbgain   + w.wlbgain   )
			,w.wlbloss   = ( d.wlbloss   + w.wlbloss   )
			,w.wlbphys   = ( d.wlbphys   + w.wlbphys   )
			,w.wlbpsyc   = ( d.wlbpsyc   + w.wlbpsyc   )
			,w.wlbpt     = ( d.wlbpt     + w.wlbpt     )
			,w.wlbtot    = ( d.wlbtot    + w.wlbtot    )
			,w.enlgain   = ( d.enlgain   + w.enlgain   )
			,w.enlloss   = ( d.enlloss   + w.enlloss   )
			,w.enlends   = ( d.enlends   + w.enlends   )
			,w.enlpt     = ( d.enlpt     + w.enlpt     )
			,w.enloth    = ( d.enloth    + w.enloth    )
			,w.enltot    = ( d.enltot    + w.enltot    )
			,w.sklasth   = ( d.sklasth   + w.sklasth   )
			,w.sklpt     = ( d.sklpt     + w.sklpt     )
			,w.skloth    = ( d.skloth    + w.skloth    )
			,w.skltot    = ( d.skltot    + w.skltot    )
			,w.trngain   = ( d.trngain   + w.trngain   )
			,w.trnloss   = ( d.trnloss   + w.trnloss   )
			,w.tranlw    = ( d.tranlw    + w.tranlw    )
			,w.meanslw   = ( d.meanslw   + w.meanslw   )
			,w.endslw    = ( d.endslw    + w.endslw    )
			,w.arenalw   = ( d.arenalw   + w.arenalw   )
			,w.ptlw      = ( d.ptlw      + w.ptlw      )
			,w.nation    = ( d.nation    + w.nation    )
			,w.anomie    = ( d.anomie    + w.anomie    )
			,w.negaff    = ( d.negaff    + w.negaff    )
			,w.posaff    = ( d.posaff    + w.posaff    )
			,w.surelw    = ( d.surelw    + w.surelw    )
			,w.if        = ( d.if        + w.if        )
			,w.notlw     = ( d.notlw     + w.notlw     )
			,w.timespc   = ( d.timespc   + w.timespc   )
			,w.formlw    = ( d.formlw    + w.formlw    )
		;
		
		SET @tmpQuery = concat('
			UPDATE ', dictionary, ' d, vector_word w 
			SET
			 d.positiv   = w.positiv
			,d.negativ   = w.negativ
			,d.pstv      = w.pstv   
			,d.affil     = w.affil  
			,d.ngtv      = w.ngtv   
			,d.hostile   = w.hostile
			,d.strong    = w.strong 
			,d.power     = w.power  
			,d.weak      = w.weak   
			,d.submit    = w.submit 
			,d.active    = w.active 
			,d.passive   = w.passive
			,d.pleasur   = w.pleasur
			,d.pain      = w.pain   
			,d.feel      = w.feel   
			,d.arousal   = w.arousal
			,d.emot      = w.emot   
			,d.virtue    = w.virtue 
			,d.vice      = w.vice   
			,d.ovrst     = w.ovrst  
			,d.undrst    = w.undrst 
			,d.academ    = w.academ 
			,d.doctrin   = w.doctrin
			,d.econ      = w.econ   
			,d.exch      = w.exch   
			,d.econ_b    = w.econ_b 
			,d.exprsv    = w.exprsv 
			,d.legal     = w.legal  
			,d.milit     = w.milit  
			,d.polit     = w.polit  
			,d.polit_b   = w.polit_b
			,d.relig     = w.relig  
			,d.role      = w.role   
			,d.coll      = w.coll   
			,d.work      = w.work   
			,d.ritual    = w.ritual 
			,d.socrel    = w.socrel 
			,d.race      = w.race   
			,d.kin       = w.kin    
			,d.male      = w.male   
			,d.female    = w.female 
			,d.nonadlt   = w.nonadlt
			,d.hu        = w.hu     
			,d.ani       = w.ani    
			,d.place     = w.place  
			,d.social    = w.social 
			,d.region    = w.region 
			,d.route     = w.route  
			,d.aquatic   = w.aquatic
			,d.land      = w.land   
			,d.sky       = w.sky    
			,d.object    = w.object 
			,d.tool      = w.tool   
			,d.food      = w.food   
			,d.vehicle   = w.vehicle
			,d.bldgpt    = w.bldgpt 
			,d.comnobj   = w.comnobj
			,d.natobj    = w.natobj 
			,d.bodypt    = w.bodypt 
			,d.comform   = w.comform
			,d.com       = w.com    
			,d.say       = w.say    
			,d.need      = w.need   
			,d.goal      = w.goal   
			,d.try       = w.try    
			,d.means     = w.means  
			,d.persist   = w.persist
			,d.complet   = w.complet
			,d.fail      = w.fail   
			,d.natrpro   = w.natrpro
			,d.begin     = w.begin  
			,d.vary      = w.vary   
			,d.increas   = w.increas
			,d.decreas   = w.decreas
			,d.finish    = w.finish 
			,d.stay      = w.stay   
			,d.rise      = w.rise   
			,d.exert     = w.exert  
			,d.fetch     = w.fetch  
			,d.travel    = w.travel 
			,d.fall      = w.fall   
			,d.think     = w.think  
			,d.know      = w.know   
			,d.causal    = w.causal 
			,d.ought     = w.ought  
			,d.perceiv   = w.perceiv
			,d.compare   = w.compare
			,d.eval      = w.eval   
			,d.eval_b    = w.eval_b 
			,d.solve     = w.solve  
			,d.abs       = w.abs    
			,d.abs_b     = w.abs_b  
			,d.quality   = w.quality
			,d.quan      = w.quan   
			,d.numb      = w.numb   
			,d.ord       = w.ord    
			,d.card      = w.card   
			,d.freq      = w.freq   
			,d.dist      = w.dist   
			,d.time      = w.time   
			,d.time_b    = w.time_b 
			,d.space     = w.space  
			,d.pos       = w.pos    
			,d.dim       = w.dim    
			,d.rel       = w.rel    
			,d.color     = w.color  
			,d.self      = w.self   
			,d.our       = w.our    
			,d.you       = w.you    
			,d.name      = w.name   
			,d.yes       = w.yes    
			,d.no        = w.no     
			,d.negate    = w.negate 
			,d.intrj     = w.intrj  
			,d.iav       = w.iav    
			,d.dav       = w.dav    
			,d.sv        = w.sv     
			,d.ipadj     = w.ipadj  
			,d.indadj    = w.indadj 
			,d.powgain   = w.powgain
			,d.powloss   = w.powloss
			,d.powends   = w.powends
			,d.powaren   = w.powaren
			,d.powcon    = w.powcon 
			,d.powcoop   = w.powcoop
			,d.powaupt   = w.powaupt
			,d.powpt     = w.powpt  
			,d.powdoct   = w.powdoct
			,d.powauth   = w.powauth
			,d.powoth    = w.powoth 
			,d.powtot    = w.powtot 
			,d.rcethic   = w.rcethic
			,d.rcrelig   = w.rcrelig
			,d.rcgain    = w.rcgain 
			,d.rcloss    = w.rcloss 
			,d.rcends    = w.rcends 
			,d.rctot     = w.rctot  
			,d.rspgain   = w.rspgain
			,d.rsploss   = w.rsploss
			,d.rspoth    = w.rspoth 
			,d.rsptot    = w.rsptot 
			,d.affgain   = w.affgain
			,d.affloss   = w.affloss
			,d.affpt     = w.affpt  
			,d.affoth    = w.affoth 
			,d.afftot    = w.afftot 
			,d.wltpt     = w.wltpt  
			,d.wlttran   = w.wlttran
			,d.wltoth    = w.wltoth 
			,d.wlttot    = w.wlttot 
			,d.wlbgain   = w.wlbgain
			,d.wlbloss   = w.wlbloss
			,d.wlbphys   = w.wlbphys
			,d.wlbpsyc   = w.wlbpsyc
			,d.wlbpt     = w.wlbpt  
			,d.wlbtot    = w.wlbtot 
			,d.enlgain   = w.enlgain
			,d.enlloss   = w.enlloss
			,d.enlends   = w.enlends
			,d.enlpt     = w.enlpt  
			,d.enloth    = w.enloth 
			,d.enltot    = w.enltot 
			,d.sklasth   = w.sklasth
			,d.sklpt     = w.sklpt  
			,d.skloth    = w.skloth 
			,d.skltot    = w.skltot 
			,d.trngain   = w.trngain
			,d.trnloss   = w.trnloss
			,d.tranlw    = w.tranlw 
			,d.meanslw   = w.meanslw
			,d.endslw    = w.endslw 
			,d.arenalw   = w.arenalw
			,d.ptlw      = w.ptlw   
			,d.nation    = w.nation 
			,d.anomie    = w.anomie 
			,d.negaff    = w.negaff 
			,d.posaff    = w.posaff 
			,d.surelw    = w.surelw 
			,d.if        = w.if     
			,d.notlw     = w.notlw  
			,d.timespc   = w.timespc
			,d.formlw    = w.formlw 
			WHERE d.word = \'',@randWord, '\'
		');
		PREPARE STMT FROM @tmpQuery;
		EXECUTE STMT;

		-- select concat('>>>Nudged word `', @randWord, '` in iteration #', i, '.') Notification; 

		SET i=i+1;
	END LOOP myloop;

END; //
DELIMITER ;