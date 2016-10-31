-- Table definitions for the tournament project.
--
-- Put your SQL 'create table' statements in this file; also 'create view'
-- statements if you choose to use it.
--
-- You can write comments in this file by starting them with two dashes, like
-- these lines here.


CREATE TABLE public.players (
  player_id SERIAL,
  player_name VARCHAR(100),
  PRIMARY KEY(player_id)
);

-- Matches table
-- It was designed to be more realistic and
-- could be storing pairings.
-- The result field's value means:
-- -1 the match is not played
--  0 draw
--  1 first player won
--  2 second player won

CREATE TABLE public.matches (
  match_id SERIAL,
  player1_id INTEGER REFERENCES players (player_id),
  player2_id INTEGER REFERENCES players (player_id),
  result INTEGER DEFAULT -1,
  CHECK (result >= -1 AND result <= 2),
  CONSTRAINT matches_pkey PRIMARY KEY(match_id)
) WITH (oids = false);


-- vw_actual_standings view
-- to get players actual standings:
-- won matches, played matches

CREATE VIEW vw_actual_standings AS
SELECT p.player_id, p.player_name, COUNT(m.match_id) AS won_matches,
	COUNT(mb.match_id) AS cnt_matches
FROM players p LEFT OUTER JOIN
	matches mb ON (p.player_id = mb.player1_id OR p.player_id = mb.player2_id)
    LEFT OUTER JOIN
	matches m ON (p.player_id = m.player1_id AND m.result = 1) OR
    			(p.player_id = m.player2_id AND m.result = 2)
GROUP BY p.player_id, p.player_name
ORDER BY won_matches DESC;


-- vw_actual_standings_wrn view
-- to get players actual standings with their ranks
-- to use in the following view to pairing them

CREATE VIEW vw_actual_standings_wrn AS
SELECT p.player_id, p.player_name, COUNT(m.match_id) AS won_matches,
	row_number() OVER (ORDER BY COUNT(m.match_id) DESC)
FROM players p LEFT OUTER JOIN
	matches m ON (p.player_id = m.player1_id AND m.result = 1) OR
    			(p.player_id = m.player2_id AND m.result = 2)
GROUP BY p.player_id, p.player_name
ORDER BY won_matches DESC;


-- vw_swiss_pairing view
-- pairing every odd ranked player to the next one

CREATE VIEW vw_swiss_pairing AS
SELECT v1.player_id AS player1_id, v1.player_name AS player1_name,
	v2.player_id AS player2_id, v2.player_name AS player2_name
FROM vw_actual_standings_wrn v1 INNER JOIN
	vw_actual_standings_wrn v2 ON v2.row_number = v1.row_number + 1
WHERE (v1.row_number % 2) = 1
ORDER BY v1.row_number;