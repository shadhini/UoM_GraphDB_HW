// Make a 1 min video of you doing the following tasks:


//  2. Add yourself to the database:  15 Points
//  3. Add at least 10 movies you have seen from the movies that are in the database. 
//      (No need to manually add. Just show and execute multiple automated insertions.). 
//      You need to show the movie names. If two students have the exactly same 10 movies listed, 
//      they will each get half of the marks. If there are three, one-third.  And so on.  25 Points
//  4. Run the recommendation result for yourself. Show the movies that are listed: 25 Points
//  5. Run and show the new/changed result of the Page Rank algorithm on the data set. 
//      In your verbal commentary, you must point out the changes that have happened in the order.  25 Points
//  6. Upload the 1 min video. (MP4, MKV, AVI, or any other video format that is compatible with VLC media player 3.0.12 is acceptable). 
//      The filename of the video must be your index number.


// visualize schema
CALL db.schema.visualization()

// _________________________________________________________________________________________________________________________________
//  1. Run the Page Rank algorithm and show the results (The Idea is to show the most influential movies before adding yourself): 
//      10 Points
// _________________________________________________________________________________________________________________________________

// create a grpah projection i.e. a in-memory graph
// Their use enables GDS to run quickly and efficiently through the calculations. 
CALL gds.graph.project(
  'movies_v3',
  ['Movie', 'User', 'Actor', 'Director', 'Genre', 'Person'],
  ['ACTED_IN', 'RATED', 'IN_GENRE', 'DIRECTED']
)
YIELD
    graphName, nodeProjection, nodeCount, relationshipProjection, relationshipCount

// graph listing and existence
CALL gds.graph.list()
CALL gds.graph.list('movies_v3') 



// stream mode will output the results of the calculation without altering the database or the graph projection. 

// -- filtered only movie nodes
CALL gds.pageRank.stream('movies_v3')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score AS pageRank
MATCH (n:Movie)
RETURN n.title AS movie_title, n.released AS released_year, n.imdbRating AS imdb_rating, pageRank
ORDER BY pageRank DESC, movie_title ASC



// add myself to database
CREATE (u:User {name: 'Shadhini'})
RETURN u

MATCH (u:User), (m1:Movie), (m2:Movie), (m3:Movie), (m4:Movie), (m5:Movie), (m6:Movie), (m7:Movie), (m8:Movie), (m9:Movie), (m10:Movie)
WHERE u.name = 'Shadhini' AND
      m1.title = 'Outbreak' AND
      m2.title = 'Tale of Two Sisters, A (Janghwa, Hongryeon)' AND
      m3.title = 'Joint Security Area (Gongdong gyeongbi guyeok JSA)' AND
      m4.title = 'My Sassy Girl (Yeopgijeogin geunyeo)' AND
      m5.title = 'Forrest Gump' AND
      m6.title = 'Beauty and the Beast' AND
      m7.title = 'Jurassic Park' AND
      m8.title = 'Terminator 2: Judgment Day' AND
      m9.title = 'Snow Falling on Cedars' AND
      m10.title = 'The Devil\'s Advocate' 
CREATE (u)-[r1:RATED {rating: 4.1, timestamp: timestamp()}]->(m1)
CREATE (u)-[r2:RATED {rating: 3.8, timestamp: timestamp()}]->(m2)
CREATE (u)-[r3:RATED {rating: 4.5, timestamp: timestamp()}]->(m3)
CREATE (u)-[r4:RATED {rating: 4.6, timestamp: timestamp()}]->(m4)
CREATE (u)-[r5:RATED {rating: 3.2, timestamp: timestamp()}]->(m5)
CREATE (u)-[r6:RATED {rating: 4.8, timestamp: timestamp()}]->(m6)
CREATE (u)-[r7:RATED {rating: 4.9, timestamp: timestamp()}]->(m7)
CREATE (u)-[r8:RATED {rating: 2.1, timestamp: timestamp()}]->(m8)
CREATE (u)-[r9:RATED {rating: 3.0, timestamp: timestamp()}]->(m9)
CREATE (u)-[r10:RATED {rating: 2.7, timestamp: timestamp()}]->(m10)
RETURN u, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, type(r1)

MATCH (u:User {name: 'Shadhini'}) - [r:RATED] -> (m:Movie)
RETURN u, r, m
MATCH (u:User {name: 'Cynthia Freeman'}) - [r:RATED] -> (m:Movie)
RETURN u, r, m

// Collaborative Filtering – Neighborhood-Based Recommendations

MATCH (u1:User {name:"Shadhini"})-[r:RATED]->(m:Movie)
WITH u1, avg(r.rating) AS u1_mean

MATCH (u1)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2)
WITH u1, u1_mean, u2, COLLECT({r1: r1, r2: r2}) AS ratings WHERE size(ratings) > 5

MATCH (u2)-[r:RATED]->(m:Movie)
WITH u1, u1_mean, u2, avg(r.rating) AS u2_mean, ratings

UNWIND ratings AS r

WITH sum( (r.r1.rating-u1_mean) * (r.r2.rating-u2_mean) ) AS nom,
     sqrt( sum( (r.r1.rating - u1_mean)^2) * sum( (r.r2.rating - u2_mean) ^2)) AS denom,
     u1, u2 WHERE denom <> 0

WITH u1, u2, nom/denom AS pearson
ORDER BY pearson DESC LIMIT 10

MATCH (u2)-[r:RATED]->(m:Movie) WHERE NOT EXISTS( (u1)-[:RATED]->(m) )

RETURN m.title, SUM( pearson * r.rating) AS score
ORDER BY score DESC LIMIT 25

// re run page rank algo
CALL gds.graph.project(
  'movies_v3',
  ['Movie', 'User', 'Actor', 'Director', 'Genre', 'Person'],
  ['ACTED_IN', 'RATED', 'IN_GENRE', 'DIRECTED']
)
YIELD
    graphName, nodeProjection, nodeCount, relationshipProjection, relationshipCount

CALL gds.pageRank.stream('movies_v4')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score AS pageRank
MATCH (n:Movie)
RETURN n.title AS movie_title, n.imdbRating AS imdb_rating, pageRank
ORDER BY pageRank DESC, movie_title ASC


// delete myself
MATCH (u:User {name: 'Shadhini'})
DELETE u

MATCH (u:User {name: 'Shadhini'})
DETACH DELETE u