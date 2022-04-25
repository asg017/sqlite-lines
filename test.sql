.bail on
.load dist/lines
.mode box
.header on




select name, lines.rowid, lines.contents
from fsdir('.')
join lines_read(name) as lines
where name like '%.txt';

.exit

select rowid, path, contents
from lines_glob("*.txt");

/*
select name
from fsdir(".")
where name like "%.txt";
*/
.exit

.timer on

.load ./vsv
create virtual table temp.t using vsv(
  filename="/Volumes/Sandisk1/draw/face.ndjson",
  fsep="*"
);


.print count speed test
select count(rowid)
from temp.t;
select count(*)
from lines_read("/Volumes/Sandisk1/draw/face.ndjson");--*/


.print distinct speed test

select count(distinct contents -> 'countrycode')
from lines_read("/Volumes/Sandisk1/draw/face.ndjson");

select count(distinct c0 -> 'countrycode')
from temp.t;

