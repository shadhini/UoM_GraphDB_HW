
-- create
CREATE TABLE Person (
  ID INTEGER PRIMARY KEY,
  Name TEXT NOT NULL
);
 
CREATE TABLE Friend (
  PersonID INTEGER,
  FriendID INTEGER
);
 
 
-- insert
INSERT INTO Person VALUES (0001, 'Alice');
INSERT INTO Person VALUES (0002, 'Bob');
INSERT INTO Person VALUES (0099, 'Zach');
 
INSERT INTO Friend VALUES (0001, 0002);
INSERT INTO Friend VALUES (0002, 0001);
INSERT INTO Friend VALUES (0002, 0099);
INSERT INTO Friend VALUES (0099, 0001);

-- query
select distinct Person.ID, Person.Name from 
    (select Friend.FriendID as AliceFriendsFriendsID from 
        (select Friend.FriendID as AliceFriendID from Person join Friend 
            on Person.ID = Friend.PersonID  
            where Person.Name = 'Alice') as  AliceFriends
        join 
        Friend 
        on AliceFriends.AliceFriendID = Friend.PersonID) as AliceFriendsFriends
    join -- this join is to extract the name of the Alice's friends' friend
    Person
    on AliceFriendsFriends.AliceFriendsFriendsID = Person.ID
    where Person.Name != 'Alice';


-- Output:

-- ID	Name
-- 99	Zach

-- query
SELECT p1.Name AS SOURCE, p2.Name AS FRIEND_OF_FRIEND
FROM Friend f1 JOIN Person p1
ON f1.PersonID = p1.ID
JOIN Friend f2
ON f2.PersonID = f1.FriendID 
JOIN Person p2
ON f2.FriendID = p2.ID WHERE p1.Name='Alice' AND f2.FriendID <> p1.ID

-- Output:

-- SOURCE	FRIEND_OF_FRIEND
-- Alice	Zach

