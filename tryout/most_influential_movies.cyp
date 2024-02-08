// Make a 1 min video of you doing the following tasks:

//  1. Run the Page Rank algorithm and show the results (The Idea is to show the most influential movies before adding yourself): 
//      10 Points
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

// create a grpah projection i.e. a in-memory graph
// Their use enables GDS to run quickly and efficiently through the calculations. 
CALL gds.graph.project(
  'movies_v1',
  ['Movie', 'Person'],
  ['ACTED_IN', 'REVIEWED', 'PRODUCED', 'WROTE', 'FOLLOWS', 'DIRECTED']
)
YIELD
    graphName, nodeProjection, nodeCount, relationshipProjection, relationshipCount

CALL gds.graph.project(
  'movies_v2',
  'Movie',
  ['ACTED_IN', 'REVIEWED', 'PRODUCED', 'WROTE', 'DIRECTED']
)
YIELD
    graphName, nodeProjection, nodeCount, relationshipProjection, relationshipCount

// graph listing and existence
CALL gds.graph.list()
CALL gds.graph.list('movies_v1') // all nodes and all relationships
CALL gds.graph.list('movies_v2') // only movie nodes and all relationships except "follows" relationship ==> 0 relationships , only nodes


// stream mode will output the results of the calculation without altering the database or the graph projection. 
//PR1 -- have ranks for both movie and person nodes, thus have some null values for movie.title
CALL gds.pageRank.stream('movies_v1')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score AS pageRank
RETURN n.title AS movie_title, n.released AS released_year, pageRank
ORDER BY pageRank DESC, movie_title ASC

//PR2 -- filtered only movie nodes
CALL gds.pageRank.stream('movies_v1')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score AS pageRank
MATCH (n:Movie)
RETURN n.title AS movie_title, n.released AS released_year, pageRank
ORDER BY pageRank DESC, movie_title ASC

//PR3 -- graph has only movies and no relationships -- all the movies has same page rank -- WRONG
CALL gds.pageRank.stream('movies_v2')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score AS pageRank
RETURN n.title AS movie_title, n.released AS released_year, pageRank
ORDER BY pageRank DESC, movie_title ASC


// add myself to database
CREATE (p:Person {name: 'Shadhini'})
RETURN p

MATCH (p:Person), (m1:Movie), (m2:Movie), (m3:Movie), (m4:Movie), (m5:Movie), (m6:Movie), (m7:Movie), (m8:Movie), (m9:Movie), (m10:Movie)
WHERE p.name = 'Shadhini' AND
      m1.title = 'The Matrix Reloaded' AND
      m2.title = 'Top Gun' AND
      m3.title = 'Stand By Me' AND
      m4.title = 'Snow Falling on Cedars' AND
      m5.title = 'You\'ve Got Mail' AND
      m6.title = 'Sleepless in Seattle' AND
      m7.title = 'Joe Versus the Volcano' AND
      m8.title = 'When Harry Met Sally' AND
      m9.title = 'That Thing You Do' AND
      m10.title = 'The Devil\'s Advocate' 
CREATE (p)-[w1:WATCHED]->(m1)
CREATE (p)-[w2:WATCHED]->(m2)
CREATE (p)-[w3:WATCHED]->(m3)
CREATE (p)-[w4:WATCHED]->(m4)
CREATE (p)-[w5:WATCHED]->(m5)
CREATE (p)-[w6:WATCHED]->(m6)
CREATE (p)-[w7:WATCHED]->(m7)
CREATE (p)-[w8:WATCHED]->(m8)
CREATE (p)-[w9:WATCHED]->(m9)
CREATE (p)-[w10:WATCHED]->(m10)
RETURN p, m1, m2, m3, m4, m5, m6, m7, m8, m9, m10, type(w1)

// Collaborative Filtering – Neighborhood-Based Recommendations


