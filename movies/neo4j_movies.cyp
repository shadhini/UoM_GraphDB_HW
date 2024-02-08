// What is Cypher?
// ===============================

// Cypher is a graph query language that is used to query the Neo4j Database. 
// Just like you use SQL to query a MySQL database, you would use Cypher to query the Neo4j Database.

CALL db.schema.visualization()

// 5 movies released after 2000
MATCH (m:Movie)
WHERE m.released > 2000
RETURN m LIMIT 5

// movies released after 2005
MATCH (m:Movie)
WHERE m.released > 2005
RETURN m

// # of movies released after 2005
MATCH (m:Movie)
WHERE m.released > 2005
RETURN count(m)

// Nodes
// ===============================

// A node in graph database is similar to a row in a relational database. 
// 2 kinds of nodes here - Person and Movie. In writing a Cypher query, 

// (p:Person) 
//      where   p is a variable  
//              Person is the type of node it is referring to

// Relationship
// ===============================

// Here, ACTED_IN, REVIEWED, PRODUCED, WROTE and DIRECTED are all relationships 

// [w:WORKS_FOR] 
//      where   w is a variable  
//              WORKS_FOR is the type of relationship it is referring to

// movies releaed after 2010 that has been directed by persons , along with relationship directed
MATCH (p:Person) - [d:DIRECTED] - (m:Movie)
WHERE m.released > 2010
RETURN p,d,m

// Labels
// ===============================

// Here,    Movie and Person are Node labels and 
//          ACTED_IN, REVIEWED, etc are Relationship types.

// (p:Person) 
//      means   p variable denoted 
//      Person labeled nodes.

// 20 persons nodes
MATCH (p:Person)
RETURN p
LIMIT 20

// 20 of all nodes
MATCH (n)
RETURN n
LIMIT 20

// Properties
// ===============================

// Properties are name-value pairs that are used to add attributes to nodes and relationships.

// movie titles and rleased years
MATCH (m:Movie)
RETURN m.title, m.released


// Create a Node
// ===============================

// CREATE clause can be used to create a new node or a relationship.

CREATE (p:Person {name: 'John Doe'})
RETURN p

// The above statement will create a new Person node with property name having value 'John Doe'.


// Finding Nodes with Match and Where Clause
// =================================================

// Match clause is used to find nodes that match a particular pattern. 

MATCH (p:Person {name: 'Tom Hanks'})
RETURN p
// you can only do basic string match based filtering this way (without using WHERE clause).

// use a WHERE clause which allows for more complex filtering including >, <, STARTS WITH, ENDS WITH, etc

MATCH (p:Person)
WHERE p.name = "Tom Hanks"
RETURN p
// Both of the above queries will return the same results.



// Merge Clause
// =================================================

// The MERGE clause is used to either
//      match the existing nodes and bind them or
//      create new node(s) and bind them
// It is a combination of MATCH and CREATE and additionally allows to specify additional actions if the data was matched or created.

MERGE (p:Person {name: 'John Doe'})
ON CREATE SET p.createdAt = timestamp()
ON MATCH SET p.lastLoggedInAt = timestamp()
RETURN p
// The above statement will create the Person node if it does not exist. 
// If the node already exists, then it will set the property lastLoggedInAt to the current timestamp. 
// If the node did not exist and was newly created instead, then it will set the createdAt property to the current timestamp.

MERGE (m:Movie {title: 'Greyhound'})
ON CREATE SET m.released = "2020", m.lastUpdatedAt = timestamp()
ON MATCH SET m.lastUpdatedAt = timestamp()
RETURN m


// Create a Relationship
// =================================================

// A Relationship connects 2 nodes.

MATCH (p:Person), (m:Movie)
WHERE p.name = "Tom Hanks" AND m.title = "Cloud Atlas"

CREATE (p)-[w:WATCHED]->(m)
RETURN type(w)
// The above statement will create a relationship :WATCHED between the existing Person and Movie nodes and return the type of relationship (i.e WATCHED).



// Relationship Types
// =================================================

// 2 kinds of relationships - incoming and outgoing.

// In the above example, the Tom Hanks node is said to have an outgoing relationship while 
//      the Cloud Atlas node is said to have an incoming relationship.

// Relationships always have a direction. However, you only have to pay attention to the direction where it is useful.
//      To denote an outgoing or an incoming relationship in cypher, we use → or ←.


MATCH (p:Person)-[r:ACTED_IN]->(m:Movie)
RETURN p,r,m
// Here, Person has an outgoing relationship and movie has an incoming relationship.

// Although, in the case of the movies dataset, the direction of the relationship is not that important and 
//      even without denoting the direction in the query, it will return the same result. So the query

MATCH (p:Person)-[r:ACTED_IN]-(m:Movie)
RETURN p,r,m
// will return the same reuslt as the above one.

MATCH (p:Person)-[r:REVIEWED]-(m:Movie)
RETURN p,r,m




// Advanced Cypher queries
// =================================================

// Finding who directed Cloud Atlas movie
MATCH (m:Movie {title: 'Cloud Atlas'})<-[d:DIRECTED]-(p:Person)
RETURN p.name
// Finding all people who have co-acted with Tom Hanks in any movie
MATCH (tom:Person {name: "Tom Hanks"})-[:ACTED_IN]->(:Movie)<-[:ACTED_IN]-(p:Person)
RETURN p.name
// Finding all people related to the movie Cloud Atlas in any way
MATCH (p:Person)-[relatedTo]-(m:Movie {title: "Cloud Atlas"})
RETURN p.name, type(relatedTo)
// In the above query, we only used the variable relatedTo which will try to find all the relationships between any Person node and the movie node "Cloud Atlas"
// Finding Movies and Actors that are 3 hops away from Kevin Bacon.
MATCH (p:Person {name: 'Kevin Bacon'})-[*1..3]-(hollywood)
RETURN DISTINCT p, hollywood