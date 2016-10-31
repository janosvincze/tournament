# The Swiss-style tournament
Udacity Swiss-style tournament project to learn how to design a basic database and how to use it with python. 
## Contents
1. Install
2. User's manual
3. Developer's manual
4. Sources

## Install
 1. You'll need python 2.7 and PostgreSQL 9.1 or later installed.
 2. Clone this repo with:
 
 ```
 git clone https://github.com/janosvincze/tournament.git
 ```
 
 3. Create tournament database
 
 ```
 cd tournament
 
 psql -c "CREATE DATABASE tournament"
 psql -f tournament.sql tournament
 ```
 
## User's manual
 Run the test code in the command line:
 
 ```
 python tournament_test.py
 ```
 
## Developer's manual
### Database
#### Table players
 ```
 CREATE TABLE public.players (
  player_id SERIAL,
  player_name VARCHAR(100),
  PRIMARY KEY(player_id)
);
 ```
#### Table matches
 It was designed to be more realistic and could be storing pairings.
 
 The result field's value means:
   - -1 the match is not played
   - 0 draw
   - 1 first player won
   - 2 second player won

   
 ```
 CREATE TABLE public.matches (
  match_id SERIAL,
  player1_id INTEGER REFERENCES players (player_id),
  player2_id INTEGER REFERENCES players (player_id),
  result INTEGER DEFAULT -1,
  CHECK (result >= -1 AND result <= 2),
  CONSTRAINT matches_pkey PRIMARY KEY(match_id)
) WITH (oids = false);
 ```
 
#### Pairing
 Creating two view to get the actual swiss pairing. The first one to get the player's ranking using windowing function.
 ```
CREATE VIEW vw_actual_standings_wrn AS
SELECT p.player_id, p.player_name, COUNT(m.match_id) AS won_matches,
	row_number() OVER (ORDER BY COUNT(m.match_id) DESC)
FROM players p LEFT OUTER JOIN
	matches m ON (p.player_id = m.player1_id AND m.result = 1) OR
    			(p.player_id = m.player2_id AND m.result = 2)
GROUP BY p.player_id, p.player_name
ORDER BY won_matches DESC;
 ```
 The second one to pairing every odd ranked player - coming from the previous view - with the next one:
 ```
CREATE VIEW vw_swiss_pairing AS
SELECT v1.player_id AS player1_id, v1.player_name AS player1_name,
	v2.player_id AS player2_id, v2.player_name AS player2_name
FROM vw_actual_standings_wrn v1 INNER JOIN
	vw_actual_standings_wrn v2 ON v2.row_number = v1.row_number + 1
WHERE (v1.row_number % 2) = 1
ORDER BY v1.row_number;
 ```

### Python code
 Using Psycopg PostgreSQL database adapter to access the database:
 ```
 import psycopg2
 ```
 
 Connecting to the tournament database with the connect() function:
 ```
  def connect():
    return psycopg2.connect("dbname=tournament")
 ```
 
 Using the following skeleton to retrieve or manipulate data:
 
  ```
conn = connect()
c = conn.cursor()
c.execute("SQL command here;")
conn.commit() 
conn.close()
 ```
 
 Creating a list from the retrieved data:
  ```
    c.execute("SELECT * FROM vw_actual_standings;")
    standing = list((row[0], str(row[1]), row[2], row[3])
                    for row in c.fetchall())
  ```
  
 Code makes use of query parameters to protect against SQL injection:
 ```
 c.execute("INSERT INTO players(player_name) VALUES(%s);", (name,))
 ```
 ```
 c.execute("""INSERT INTO matches(player1_id,player2_id,result)
             VALUES(%s,%s,1)""", (winner, loser,))
 ```
 
 
