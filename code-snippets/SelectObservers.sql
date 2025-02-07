select
user_id as Observer,
user_login as ObserverLogin,
user_name as ObserverName,
min(observed_on) as FirstObservation,
min(observed_on) as JoinDate,
'N' as Deleted,
'' as DeletedDate
from researchgradeobssampleexport
group by user_id, user_login, user_name, Deleted, deleteddate

--for create table, when new cycle imported if user is not in current database,
-- then set JoinDate as date of extract or first date of bimby cycle. (TBD)
--If user in database no longer matches any user in the extract,then update Deleted to 'Y'
--and DeletedDate to extract date#

select
    count(distinct(user_id)) as TotalObservers,
    left(observed_on,4) as Years
from researchgradeobssampleexport
group by Years