show regions from cluster;

drop database if exists dad cascade;
create database dad;
use dad;

alter database dad primary region "us-east1";
alter database dad add region "us-west1";
alter database dad add region "europe-west1";

create table dad.jokes
(
  id int primary key default unique_rowid(),
  joke string,
  punchline string
);

insert into dad.jokes (joke, punchline) values ('what did the elephant say when it ate the clown?', 'tastes funny');
insert into dad.jokes (joke, punchline) values ('what do prisoners use to communicate?', 'cell phones');
insert into dad.jokes (joke, punchline) values ('why did the bike take a nap?', 'it was two tired');
insert into dad.jokes (joke, punchline) values ('¿Cuál es la fruta más cómica?', 'Naranja ja ja ja');
insert into dad.jokes (joke, punchline) values ('किन कुखुरा सडक पार गरे','अर्को छेउमा पुग्न');

-- alter database dad primary region "europe-west1";

-- alter table dad.jokes set locality global;

--alter table dad.jokes set locality regional by row;

insert into dad.jokes (joke,punchline) values ('what do you a call bee that lives in america?','A USB');
insert into dad.jokes (joke, punchline) values ('what do you say to your French friend who woke up early?', 'europe');
