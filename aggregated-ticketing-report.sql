select
	tickettype, NUM_TOT, NUM_COMPED, NUM_SPONSORED, NUM_BOUGHT, TICKET_COST, GROSS_REV, TOTAL_COMP, ADJUSTMENTS
	,(GROSS_REV + TOTAL_COMP + ADJUSTMENTS) as NET_REV
from (
	select 
		t.tickettype as tickettype
		,sum(if('fee'=t.method, 1, 0)) as NUM_TOT
		,sum(if('fee'=t.method and 'y'=t.comp and (ra.sponsorcode='' or ra.sponsorcode is null), 1, 0)) as NUM_COMPED
		,sum(if('fee'=t.method and 'y'=t.comp and (ra.sponsorcode<>'' and ra.sponsorcode is not null), 1, 0)) as NUM_SPONSORED
		,sum(if('fee'=t.method and 'n'=t.comp, 1, 0)) as NUM_BOUGHT
		,max(if('fee'=t.method, t.amount, 0)) as TICKET_COST
		,sum(if('fee'=t.method, t.amount, 0)) as GROSS_REV
		,sum(
			if('fee'=t.method, 
				if(('golf'=t.tickettype or 'kidpreneur'=t.tickettype), if('y'=t.comp, t.amount*-1,0),0),
				if('discount'=t.method, t.amount, 0)
				) 
		) TOTAL_COMP
		,sum(if('adjust'=t.method, t.amount, 0)) as ADJUSTMENTS
	from t2 t, attendee ra 
	where 1=1
	and t.status='a' 
	and ra.id=t.attendee_id 
	and ra.status in ('a')
	and ra.id in (
		select ra.id 
		from attendee ra, transact t 
		where ra.id=t.attendee_id 
		and ra.reg_id in
			(select reg_id from (
				select reg_id,sum(amount) as amt from transact where status='a' group by reg_id having amt<=0
			) x1 )
		and ra.status='a' and t.method='fee' and t.status='a' and (t.tickettype<>'') 
	)
	and ra.reg_id not in (/* exclude IDs here */)
	group by t.tickettype
) derived_table_1
