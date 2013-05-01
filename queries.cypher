
# PLAYER RECCOMENDATIONS
START a=node:player('player:johnnyfuchs')
MATCH (a)-[x:PLAYS]->(b)
WHERE x.play_time > 5
WITH b
MATCH (b)<-[y:PLAYS]-(c)-[z:PLAYS]->(d)
WHERE y.play_time > 5
AND   z.play_time > 5
RETURN distinct d.name AS name,
       sum(z.play_time)/count(z) AS ave
ORDER BY ave DESC
LIMIT 20;



# PLAYER RECCOMENDATIONS WITH LIMITS
START a=node:player('player:johnnyfuchs')
MATCH (a)-[x:PLAYS]->(b)<-[y:PLAYS]-(c)
WHERE x.play_time > 5
WITH b, c, count(y) AS k
ORDER BY k desc
LIMIT 10
MATCH (c)-[z:PLAYS]->(d)
WHERE z.play_time > 5
AND   d <> b
RETURN distinct d.name AS name,
       sum(z.play_time)/count(z) AS ave
ORDER BY ave DESC
LIMIT 20;
