Running Page Rank Algorithm and Try Out kNN movie recommendation using Pearson similarity


// visualize schema
CALL db.schema.visualization()

// _________________________________________________________________________________________________________________________________
//  1. Run the Page Rank algorithm and show the results (The Idea is to show the most influential movies before adding yourself): 
//      10 Points
// _________________________________________________________________________________________________________________________________

// create a grpah projection i.e. a in-memory graph
// Their use enables GDS to run quickly and efficiently through the calculations. 
CALL gds.graph.project(
  'movies_v1',
  ['Movie', 'User'],
  {
    RATED: {properties: "rating"}
  }
)
YIELD
    graphName, nodeProjection, nodeCount, relationshipProjection, relationshipCount

// graph listing and existence
CALL gds.graph.list()
CALL gds.graph.list('movies_v1') 



// stream mode will output the results of the calculation without altering the database or the graph projection. 

// -- filtered only movie nodes
CALL gds.pageRank.stream('movies_v1')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score AS pageRank
MATCH (n:Movie)
RETURN n.title AS movie_title, pageRank
ORDER BY pageRank DESC, movie_title ASC


// _________________________________________________________________________________________________________________________________
//  2. Add yourself to the database:  15 Points
// _________________________________________________________________________________________________________________________________

// add myself to database
CREATE (u:User {name: 'Shadhini Jayatilake'})
RETURN u

// _________________________________________________________________________________________________________________________________
//  3. Add at least 10 movies you have seen from the movies that are in the database. 
//      (No need to manually add. Just show and execute multiple automated insertions.). 
//      You need to show the movie names. If two students have the exactly same 10 movies listed, 
//      they will each get half of the marks. If there are three, one-third.  And so on.  25 Points
// _________________________________________________________________________________________________________________________________

MATCH (u:User), (m1:Movie), (m2:Movie), (m3:Movie), (m4:Movie), (m5:Movie), (m6:Movie), (m7:Movie), (m8:Movie), (m9:Movie), (m10:Movie)
WHERE u.name = 'Shadhini Jayatilake' AND
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
CREATE (u)-[r1:RATED {rating: 4.1, timestamp: timestamp()}]->(m1),
       (u)-[r2:RATED {rating: 3.8, timestamp: timestamp()}]->(m2),
       (u)-[r3:RATED {rating: 4.5, timestamp: timestamp()}]->(m3),
       (u)-[r4:RATED {rating: 4.6, timestamp: timestamp()}]->(m4),
       (u)-[r5:RATED {rating: 3.2, timestamp: timestamp()}]->(m5),
       (u)-[r6:RATED {rating: 4.8, timestamp: timestamp()}]->(m6),
       (u)-[r7:RATED {rating: 4.9, timestamp: timestamp()}]->(m7),
       (u)-[r8:RATED {rating: 0.8, timestamp: timestamp()}]->(m8),
       (u)-[r9:RATED {rating: 3.0, timestamp: timestamp()}]->(m9),
       (u)-[r10:RATED {rating: 2.7, timestamp: timestamp()}]->(m10)
RETURN u, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, type(r1)

MATCH (u:User {name: 'Shadhini Jayatilake'}) - [r:RATED] -> (m:Movie)
RETURN u, r, m

// _________________________________________________________________________________________________________________________________
//  4. Run the recommendation result for yourself. Show the movies that are listed: 25 Points
// _________________________________________________________________________________________________________________________________
// kNN movie recommendation using Pearson similarity

// Collaborative Filtering – Recommendations - K-Nearest Neighbors

//allow each of the k most similar users to vote for what items should be recommended.

// Essentially: "Who are the 10 users with tastes in movies most similar to mine? 
// What movies have they rated highly that I haven’t seen yet?"

// When users rate movies, 
// on average some users tend to give higher ratings than others
// Pearson similarity metric takes into account the fact that different users will have different mean ratings and 
// it accounts for these discrepancies.
// So, that is why pearson simlilarityb metric is particularly well-suited for product recommendations 

MATCH (u1:User {name:"Shadhini Jayatilake"})-[r:RATED]->(m:Movie)
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

// _________________________________________________________________________________________________________________________________
//  5. Run and show the new/changed result of the Page Rank algorithm on the data set. 
//      In your verbal commentary, you must point out the changes that have happened in the order.  25 Points
// _________________________________________________________________________________________________________________________________

// re run page rank algo
CALL gds.graph.project(
  'movies_v2',
  ['Movie', 'User'],
  {
    RATED: {properties: "rating"}
  }
)
YIELD
    graphName, nodeProjection, nodeCount, relationshipProjection, relationshipCount

CALL gds.pageRank.stream('movies_v2')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score AS pageRank
MATCH (n:Movie)
RETURN n.title AS movie_title, pageRank
ORDER BY pageRank DESC, movie_title ASC

// _________________________________________________________________________________________________________________________________
//  6. Upload the 1 min video. (MP4, MKV, AVI, or any other video format that is compatible with VLC media player 3.0.12 is acceptable). 
//      The filename of the video must be your index number.
// _________________________________________________________________________________________________________________________________

// delete myself
MATCH (u:User {name: 'Shadhini Jayatilake'})
DELETE u

MATCH (u:User {name: 'Shadhini Jayatilake'})
DETACH DELETE u

// delete graph projection
CALL gds.graph.drop('movies_v1') YIELD graphName
CALL gds.graph.drop('movies_v1') YIELD graphName

CALL gds.graph.list()
CALL gds.graph.list('movies_v1') 