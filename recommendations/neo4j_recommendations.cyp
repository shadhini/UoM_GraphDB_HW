// ====================================================================================
// Graph-Based Recommendations
// ====================================================================================
// Main benefits of using graphs to generate recommendations include:
//      1. Performance. 
//          Index-free adjacency allows for calculating recommendations in real time, 
//          ensuring the recommendation is always relevant and reflecting up-to-date information.
//      2. Data model. 
//          The labeled property graph model allows for easily combining datasets from multiple sources, 
//          allowing enterprises to unlock value from previously separated data silos.

// Nodes
// Movie, Actor, Director, User, Genre are the labels used in this example.

// Relationships
// ACTED_IN, IN_GENRE, DIRECTED, RATED are the relationships used in this example.

// Properties
// title, name, year, rating are some of the properties used in this example.
CALL db.schema.visualization()


// Eliminate Data Silos
// ====================================================================================
// In this use case, we are using graphs to combine data from multiple sources.
// By combining these two in the graph, we are able to query across datasets to generate personalized product recommendations.

// Product Catalog: Data describing movies comes from the product catalog silo.
// User Purchases / Reviews: Data on user purchases and reviews comes from the user or transaction source.

// Graph Patterns
// ====================================================================================

// Nodes
// _____________________________________________________________________________________
// defined within parentheses (). Optionally, specify node label(s): 
(:Movie)

// Relationships
// _____________________________________________________________________________________
//  defined within square brackets []. Optionally, specify type and direction:
(:Movie)<-[:RATED]-(:User)

// Variables
// _____________________________________________________________________________________
// Graph elements can be bound to variables that can be referred to later in the query:
(m:Movie)<-[r:RATED]-(u:User)

// Predicates
// _____________________________________________________________________________________
// Filters. Boolean logic operators, regular expressions and string comparison operators can be used here within the WHERE clause
//e.g. 
WHERE m.title CONTAINS 'Matrix'

// Aggregations
// _____________________________________________________________________________________
// There is an implicit group of all non-aggregated fields when using aggregation functions such as count.


// Dissecting a Cypher Statement
// _____________________________________________________________________________________
// "How many reviews does each Matrix movie have?"
MATCH (m:Movie)<-[:RATED]-(u:User)
WHERE m.title CONTAINS 'Matrix'
WITH m, count(*) AS reviews
RETURN m.title AS movie, reviews
ORDER BY reviews DESC LIMIT 5;

// find: Search for an existing graph pattern
MATCH (m:Movie)<-[:RATED]-(u:User)

// filter: Filter matching paths to only those matching a predicate
WHERE m.title CONTAINS "Matrix"

// aggregate: Count number of paths matched for each movie
WITH m, count(*) AS reviews

// return: Specify columns to be returned by the statement
RETURN m.title as movie, reviews

// order: Order by number of reviews, in descending order
ORDER BY reviews DESC

// limit: Only return first five records
LIMIT 5;



// Personalized Recommendations
// ====================================================================================
// 2 approaches to recommendation algorithms.

// 1. Content-Based Filtering
// _____________________________________________________________________________________
// Recommend items that are similar to those that a user is viewing, rated highly or purchased previously.
// "Items similar to the item you’re looking at now"
MATCH p=(m:Movie {title: 'Net, The'})
       -[:ACTED_IN|IN_GENRE|DIRECTED*2]-()
RETURN p LIMIT 25


// 2. Collaborative Filtering
// _____________________________________________________________________________________
// Use the preferences, ratings and actions of other users in the network to find items to recommend.
// "Users who got this item, also got that other item."
MATCH (m:Movie {title: 'Crimson Tide'})<-[:RATED]-
      (u:User)-[:RATED]->(rec:Movie)
WITH rec, COUNT(*) AS usersWhoAlsoWatched
ORDER BY usersWhoAlsoWatched DESC LIMIT 25
RETURN rec.title AS recommendation, usersWhoAlsoWatched

// Similarity Based on Common Genres ---------------------------------------------------
// Find similar movies by common genres
MATCH (m:Movie)-[:IN_GENRE]->(g:Genre)
              <-[:IN_GENRE]-(rec:Movie)
WHERE m.title = 'Inception'
WITH rec, collect(g.name) AS genres, count(*) AS commonGenres
RETURN rec.title, genres, commonGenres
ORDER BY commonGenres DESC LIMIT 10;

// Personalized Recommendations Based on Genres ----------------------------------------
// Recommend movies similar to those the user has already watched
// Content recommendation by overlapping genres
MATCH (u:User {name: 'Angelica Rodriguez'})-[r:RATED]->(m:Movie),
      (m)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie)
WHERE NOT EXISTS{ (u)-[:RATED]->(rec) }
WITH rec, g.name as genre, count(*) AS count
WITH rec, collect([genre, count]) AS scoreComponents
RETURN rec.title AS recommendation, rec.year AS year, scoreComponents,
       reduce(s=0,x in scoreComponents | s+x[1]) AS score
ORDER BY score DESC LIMIT 10

// Weighted Content Algorithm -----------------------------------------------------------
// Of course there are many more traits in addition to just genre that we can consider to compute similarity, such as actors and directors. 
// Let’s use a weighted sum to score the recommendations based on the 
// number of actors (3x), genres (5x) and directors (4x) they have in common to boost the score:
// Compute a weighted sum based on the number and types of overlapping traits
// Find similar movies by common genres
MATCH (m:Movie) WHERE m.title = 'Wizard of Oz, The'
MATCH (m)-[:IN_GENRE]->(g:Genre)<-[:IN_GENRE]-(rec:Movie)

WITH m, rec, count(*) AS gs

OPTIONAL MATCH (m)<-[:ACTED_IN]-(a)-[:ACTED_IN]->(rec)
WITH m, rec, gs, count(a) AS as

OPTIONAL MATCH (m)<-[:DIRECTED]-(d)-[:DIRECTED]->(rec)
WITH m, rec, gs, as, count(d) AS ds

RETURN rec.title AS recommendation,
       (5*gs)+(3*as)+(4*ds) AS score
ORDER BY score DESC LIMIT 25

// Collaborative Filtering – Neighborhood-Based Recommendations

// kNN – K-Nearest Neighbors
// Now that we have a method for finding similar users based on preferences, the next step is to allow each of the k most similar users to vote for what items should be recommended.

// Essentially:

// "Who are the 10 users with tastes in movies most similar to mine? What movies have they rated highly that I haven’t seen yet?"

// kNN movie recommendation using Pearson similarity
// MATCH (u1:User {name:"Cynthia Freeman"})-[r:RATED]->(m:Movie)
// WITH u1, avg(r.rating) AS u1_mean

// MATCH (u1)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2)
// WITH u1, u1_mean, u2, COLLECT({r1: r1, r2: r2}) AS ratings WHERE size(ratings) > 10

// MATCH (u2)-[r:RATED]->(m:Movie)
// WITH u1, u1_mean, u2, avg(r.rating) AS u2_mean, ratings