-- Get number of messages for a member of the site

select count(mm.id) as aggregate
	FROM messenger_messages AS mm 
	LEFT JOIN messenger_threads as mt ON (mm.thread_id = mt.id)
	LEFT JOIN messenger_participants as mp ON (mm.thread_id = mp.thread_id)
WHERE 1=1 
AND mm.user_id != USER_ID
AND mp.user_id = USER_ID 
AND (mp.last_read < mm.created_at or mp.last_read IS NULL)
AND mp.deleted_at is NULL
AND mm.deleted_at is NULL
AND mt.deleted_at is NULL