// ===================================
// Neo4j Graph Data Science
// ===================================

// Neo4j Graph Data Science (GDS) contains a set of graph algorithms, exposed through Cypher procedures. 
//      Graph algorithms provide insights into the graph structure and elements
//      E.g.: by computing centrality, similarity scores, and detecting communities. 

// How to run production-tier algorithms. 
// ========================================
//  1. Create a graph projection
//  2. Run a graph algorithm on a projection
//  3. Show and interpret example results


// ========================================================================================================================
// Example: Airports
// ========================================================================================================================

// node labels (Airport, City, Country, Continent, and Region) 
// relationship types (:HAS_ROUTE, :IN_CITY, :IN_COUNTRY, :IN_REGION, and :ON_CONTINENT).

// visualize schema
CALL db.schema.visualization()


// ______________________________________________________________________________________________________________________________________
// Basic graph exploratory data analysis (EDA)
// ______________________________________________________________________________________________________________________________________

// examine a few airport nodes within the graph 
MATCH (a:Airport) RETURN a LIMIT 3

// distribution of the number of airports per continent 
MATCH (:Airport) - [:ON_CONTINENT] -> (c:Continent) 
RETURN c.name AS continentName, count(*) AS numAirports
ORDER BY numAirports DESC

// continentName	numAirports
// "NA"	989
// "AS"	971
// "EU"	605
// "AF"	321
// "SA"	313
// "OC"	304

// calculate the minimum, maximum, average, and standard deviation of the number of flights out of each airport
MATCH (a:Airport)-[:HAS_ROUTE]->(:Airport)
WITH a, count(*) AS numberOfRoutes
RETURN min(numberOfRoutes), max(numberOfRoutes), avg(numberOfRoutes), stdev(numberOfRoutes)

MATCH (:Airport)-[r:HAS_ROUTE]->(:Airport)
WITH r.distance AS routeDistance
RETURN min(routeDistance), max(routeDistance), avg(routeDistance), stdev(routeDistance)

// ______________________________________________________________________________________________________________________________________
// Graph creation
// ______________________________________________________________________________________________________________________________________
// The first step in executing any GDS algorithm is to create a graph projection (also referred to as an in-memory graph) 
// under a user-defined name. 
// Graph projections, stored in the graph catalog under a user-defined name, 
// are subsets of our full graph to be used in calculating results through the GDS algorithms. 
// Their use enables GDS to run quickly and efficiently through the calculations. 
// In the creation of these projections, the nature of the graph elements may change in the following ways:
//      The direction of relationships may be changed
//      Node labels and relationship types may be renamed
//      Parallel Relationships may be aggregated
// Graphs can also be created via Cypher projections

CALL gds.graph.project(
    graphName: String,
    nodeProjection: String or List or Map,
    relationshipProjection: String or List or Map,
    configuration: Map
)
YIELD
  graphName: String,
  nodeProjection: Map,
  nodeCount: Integer,
  relationshipProjection: Map,
  relationshipCount: Integer,
  projectMillis: Integer

// e.g.:
CALL gds.graph.project(
    'routes',
    'Airport',
    'HAS_ROUTE'
)
YIELD
    graphName, nodeProjection, nodeCount, relationshipProjection, relationshipCount


// Graph catalog: listing and existence
// ______________________________________________________________________________________________________________________________________
CALL gds.graph.list()
CALL gds.graph.list('routes')


// ______________________________________________________________________________________________________________________________________
// Algorithm syntax: available execution modes
// ______________________________________________________________________________________________________________________________________

// Once you have created a named graph projection, there are 4 different execution modes provided for each production tier algorithm:

//      1. stream: Returns the results of the algorithm as a stream of records without altering the database
//      2. write: Writes the results of the algorithm to the Neo4j database and returns a single record of summary statistics
//      3. mutate: Writes the results of the algorithm to the projected graph and returns a single record of summary statistics
//      4. stats: Returns a single record of summary statistics but does not write to either the Neo4j database or the projected graph
// In addition to the above for modes, it is possible to use estimate to obtain an estimation of how much memory a given algorithm will use.

// A special note on "mutate" mode
// When it comes time for feature engineering, you will likely want to include some quantities calculated by GDS into your graph projection. 
// This is what mutate is for. It does not change the database itself, but writes the results of the calculation to each node within the projected graph for future calculations. 
// This behavior is useful for when you are using more complicated graph algorithms or pipelines. 

CALL gds[.<tier>].<algorithm>.<execution-mode>[.<estimate>](
  graphName: String,
  configuration: Map
)

// where    items in [] are optional. 
//          <tier>, if present, indicates whether the algorithm is in the alpha or beta tier (production-tiered algorithms do not use this), 
//          <algorithm> is the name of the algorithm, 
//          <execution-mode> is one of the 4 execution modes, and 
//          <estimate> is an optional flag indicating that the estimate of memory usage should be returned.



// ========================================================================================================================
// Centrality measurements via PageRank
// ========================================================================================================================
// There are many ways to determine the centrality or importance of a node, but one of the most popular is through the calculation of PageRank. 
// PageRank measures the transitive (or directional) influence of a node. 
// The benefit to this approach is that it uses the influence of a node’s neighbors to determine the influence of the target node. 
// The general idea is that a node that has more incoming and more influential links from other nodes is considered to be more important 
// (i.e. a higher PageRank).

// The algorithm itself is an iterative algorithm. 
// The number of iterations can be set as a configuration parameter in GDS, however the algorithm can terminate if the node scores converge based on a specified tolerance value, which is also configurable in GDS.

// ______________________________________________________________________________________________________________________________________
// PageRank: stream mode
// ______________________________________________________________________________________________________________________________________

// As previously stated, stream mode will output the results of the calculation without altering the database or the graph projection. 
CALL gds.pageRank.stream('routes')
YIELD nodeId, score
WITH gds.util.asNode(nodeId) AS n, score AS pageRank
RETURN n.iata AS iata, n.descr AS description, pageRank
ORDER BY pageRank DESC, iata ASC

// This gives us a list of airports ordered by decreasing PageRank. 
// The utility function gds.util.asNode() maps the nodes from the database to the GDS stream results, 
//      allowing us to include properties from the database in our final query result. 
// In this case we included airport IATA code and description.

// PageRank can also run weighted via a relationship property which can prove useful in many scenarios where there is a quantity, strength, or other numeric property that we want to weigh the PageRank score with.

// ______________________________________________________________________________________________________________________________________
// PageRank: write mode
// ______________________________________________________________________________________________________________________________________

// If we want to attach the results of the PageRank calculation as a node property to each node in the graph, we would use .write() as follows:

CALL gds.pageRank.write('routes',
    {
        writeProperty: 'pageRank'
    }
)
YIELD nodePropertiesWritten, ranIterations

// We can then confirm the results using:

MATCH (a:Airport)
RETURN a.iata AS iata, a.descr AS description, a.pageRank AS pageRank
ORDER BY a.pageRank DESC, a.iata ASC