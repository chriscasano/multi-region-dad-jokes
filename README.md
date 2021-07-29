# Webinar: CockroachDB Multi-Region Local Development

A quick tutorial on how to create and develop multi-region applications on your local desktop.

## Install Cockroach

[Install Cockroach](https://www.cockroachlabs.com/docs/v21.1/install-cockroachdb-mac)

## Create A Simulated Multi-Region on Your Laptop

Create a 9 node multi region cluster

```bash
cockroach demo --global --nodes 9 --empty
```

Open the Admin UI url that displays under "Connection Parameters" -> "(webui)".  It should look like: "http://127.0.0.1:8080/demologin?password=demo11449&username=demo"

Navigate to the Node Map and the home page to see that the cluster is set up in a multi-region fashion

<p align=center>
<img src="./map.png" alt="Node Map" width="200">
</p>

Navigate to the "Network Latency" page and notice how their is simulated latency between the nodes. How fabulous is that?  Have you ever tried to simulate network latency?  Don't worry, you don't have to!

<p align=center>
<img src="./network.png" alt="Node Map" width="200"/>
</p>

Ok - Let's display all of the available nodes in the cluster.  We can connect to any of these nodes as well as service them (i.e. restart, shutdown & decommission)

```bash
\demo ls
```

The output will look something like this...

```csv
...
node 7:
  (webui)    http://127.0.0.1:8086/demologin?password=demo37633&username=demo
  (sql)      postgres://demo:demo37633@127.0.0.1:26263?sslmode=require
  (sql/unix) postgres://demo:demo37633@?host=%2Fvar%2Ffolders%2Fyj%2Fw8fnqyz95qg3w3mlxz6117c80000gp%2FT%2Fdemo982228732&port=26263
...
```


Open up a new terminal and log into node 7.  We'll use this terminal later on to test out some latencies

```bash
cockroach sql --url <node 7 (SQL) url from above>
```

Let's create a sample database called 'dad' and put some jokes in it :)  We'll also make the database multi-region.  You can do this one of two ways.  The first way is importing a SQL file like this...

```sql
\i setup.sql
```

Cockroach Labs recently added a feature of importing files from the shell (`\i`).  It's exciting!  Let's use it.  Optionally you can manually copy and paste the code here into the SQL shell.  If you accidentally run it twice, no big deal.

```sql
set sql_safe_updates = false;
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

insert into dad.jokes (joke, punchline)
values ('what did the elephant say when it ate the clown?', 'tastes funny');
insert into dad.jokes (joke, punchline)
values ('what do prisoners use to communicate?', 'cell phones');
insert into dad.jokes (joke, punchline)
values ('why did the bike take a nap?', 'it was two tired');
insert into dad.jokes (joke, punchline)
values ('¿Cuál es la fruta más cómica?', 'Naranja ja ja ja');
insert into dad.jokes (joke, punchline)
values ('किन कुखुरा सडक पार गरे','अर्को छेउमा पुग्न');
```

## Demonstrate Multi-Region Tables

Ok, now we'll showcase the new multi-region SQL abstractions.  We're going to test the latency of reads and writes from each of the regions using Regional, Global and Regional By Row tables.  

First, let's show the locality in both terminal windows

```sql
show locality
```

Now, let's show that reads from the US East terminal are fast but the reads from Europe are slow.  This is because we picked US East as the primary region.  Run this select a few times to see the latency.

```sql
select * from dad.jokes;
```

See how the latency in US East is about 1ms and about ~60ms in Europe.  Now, to lower the latency in Europe, change the primary region to be in Europe.  

```sql
alter database dad primary region "europe-west1";
```

It may take a few seconds for the change to occur.  Keep testing the read latency until you see a change.  The reads should get slower in US East but faster in Europe.

```sql
select * from dad.jokes;
```

Well this isn't fair, we don't have latency equality.  But we can achieve this by creating a Global table for our dad jokes.  Let's do that.

```sql
alter table dad.jokes set locality global;
```

Again, wait a few seconds for the change to happen.  You'll wow have fast, consistent reads on both sides of the pond.  But what does our write latency look like?

Let's do this write in US East

```sql
insert into dad.jokes (joke,punchline)
values ('what do you a call bee that lives in america?','A USB');
```

And this write in Europe

```sql
insert into dad.jokes (joke, punchline)
values ('what do you say to your French friend who woke up early?', 'Europe!');
```

Notice how the latency isn't that great for writes?  Let's try one last thing.  Let's create a regional by row table.  This will automatically geo-partition the data using an invisible region column.  A region column value will be specified once the data is created in that region which will in turn keep the row partitioned  in the originating region.  This will give us the best of both worlds.  Fast reads and fast writes within a region..

```sql
alter table dad.jokes set locality regional by row;
```

Let's try our writes again.  This time let's do this in US East:

```sql
insert into dad.jokes (id,joke,punchline)
values (1,'Guess What?','Thats What!');
```

And this one in Europe

```sql
insert into dad.jokes (id,joke,punchline)
values (2,'Hey Mom','Nevermind');
```

And let's try the selects as well!  Let's try this in US East:

```sql
select * from dad.jokes where id = 1;
```

And this one in Europe.

```sql
select * from dad.jokes where id = 2;
```

## Surviving Node Failures (...and dad jokes)

By default, the survival goal setup is to survive an Availability Zone outage.

```sql
show survival goal from database dad;
```

However, if you want to survive a regional outage, you can alter the database with the coolest SQL command

```sql
alter database dad survive region failure;
```

You can also test failure in cockroach demo and see the resilience!

```
\demo decommission 7
```

Notice how the Europe client shell no longer works.  However, try running a query on the US East shell.  You should definitely see some results.

```sql
select * from dad.jokes;
```

Congrats, you did it!  Welcome to the new multi-region experience with CockroachDB.


# References

[Andy Wood's Multi-Region Demo](https://gist.github.com/awoods187/a91617a8bd4334ad0f8bfa52fd516296)

[Multi-Region Docs](https://www.cockroachlabs.com/docs/v21.1/demo-low-latency-multi-region-deployment.html)
