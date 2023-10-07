.bail on
.mode box
.header on

.load target/debug/liblines0.dylib

select lines_version();

select * from lines_read('Cargo.toml');

.load ../sqlite-http/target/debug/libsqlite_http.dylib sqlite3_http_init


with subset as (
  select line
  from lines_read(http_request('https://github.com/datadesk/california-coronavirus-data/raw/master/latimes-place-totals.csv'))
  limit 10
)
select
  count(*),
  sum(length(line)),
  group_concat(line)
from subset;
