select
      left(observed_on,4) as Years
    ,count(distinct(user_id)) as TotalObservers
from inaturalist_import
group by Years

select
left(observed_on,4) as Years,
count(distinct id) as Observations
from inaturalist_import
group by Years;

select quality_grade,
       count(id)
from inaturalist_import
group by quality_grade;

select DATE_FORMAT(observed_on,'%M') as month_name,
       count(id)
from inaturalist_import
group by DATE_FORMAT(observed_on,'%M');

select DATE_FORMAT(observed_on,'%M') as month_name,
       month(observed_on) as month_number,
      common_name,
      count(id)
from inaturalist_import
group by DATE_FORMAT(observed_on,'%M'),month(observed_on), common_name
order by month(observed_on) asc ,count(id) desc;

select DATE_FORMAT(observed_on,'%M') as month_name,
       month(observed_on) as month_number,
       day(observed_on) as day,
       place_state_name as province,
      common_name,
      count(id)
from inaturalist_import
where  month(observed_on) = 3
group by DATE_FORMAT(observed_on,'%M'),month(observed_on), day(observed_on),
       place_state_name, common_name
order by day(observed_on) asc ,count(id) desc;

select common_name,
       count(id),
       '2025-10-25' as extract_date
from inaturalist_import
where quality_grade='research'
group by common_name,  '2025-10-25'
order by count(id) desc;

select place_state_name as province,
       count(id)
from inaturalist_import
group by place_state_name
order by place_state_name asc;

select place_state_name as province,
       count(distinct(common_name)) as species
    from inaturalist_import
group by place_state_name
order by place_state_name asc;


