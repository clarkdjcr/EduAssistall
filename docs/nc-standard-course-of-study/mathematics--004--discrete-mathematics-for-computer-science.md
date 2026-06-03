---
title: "Mathematics - Discrete Mathematics for Computer Science"
source_url: "https://docs.google.com/document/d/1SUspBdXjdZt34AHCPvsSMTM-qOp4L6h9eWIG4ZN65tU/edit?usp=drive_link"
kind: "google-doc"
subject: "Mathematics"
retrieved: "2026-06-03"
status: "success"
---
# Mathematics - Discrete Mathematics for Computer Science

Discrete Mathematics for Computer Science - Glossary of Terms

For the new Standard Course of Study that will be effective in all North Carolina schools in the 2020-21 School Year.

This document is designed to help North Carolina educators teach Discrete Mathematics for Computer Science Standard Course of Study. NCDPI staff are continually updating and improving these tools to better serve teachers and districts.

What is the purpose of this tool?
This tool provides educators with terminologies that represent the concepts and ideas teachers need to know and understand in order to effectively teach the North Carolina Standard Course of Study and use supporting materials. The Glossary of Terms is not meant to be exhaustive, but seeks to address critical terms and definitions essential in building content knowledge and understanding but also in promoting consistency across disciplines, increased student outcomes, and improved parent communication. This is a living document and will undergo revision and additions in terms over time.

How do I send Feedback?
We intend the explanations and examples in this document to be helpful and specific. That said, we believe that as this document is used, educators will find ways in which the tool can be improved and made even more useful. If there are terms which are either omitted or which you feel are misrepresented in this glossary, please send feedback by completing the Feedback on Mathematic Support Documents form.

Where are the standards and unpacking documents for the North Carolina Standard Course of Study for mathematics?
All standards are located at https://www.dpi.nc.gov/teach-nc/curriculum-instruction/standard-course-study/mathematics

Glossary by Objective
Number and Quantity
Objective
	Word
	Definition
	DCS.N.1.1
	matrix
	A rectangular array of elements organized in rows and columns.
	DCS.N.1.2
	vector
	A quantity having both magnitude and direction.
	DCS.N.1.3
	Inverse Matrix
	is an inverse matrix of  if and only if , where  is the identity matrix. An inverse matrix does not exist for all matrices.
	DCS.N.2.2
	Leslie Models

Markov Chains
	The Leslie model is , where is the initial population matrix, is the Leslie matrix, and is the number of cycles. This model, named after P.H. Leslie, is most often used to model population growth over time when given a population age distribution, with corresponding birth and survival rates.

A Markov chain is , where is the initial-state matrix, is the transition matrix, and is the number of transitions. Markov chains, named after Andrei Markov who studied linked chains of events, begins with an initial-state matrix that is multiplied by a transition matrix to produce the next state.
	DCS.N.2.3
	matrix equation
	An equation in which the variable is a matrix or elements within a matrix.

	DCS.N.3.1
	Subset

proper subset
	A set is a subset if all the elements in the set are contained within another set. For example, set A is a subset of set B if all of the elements of set A are also elements in set B. It can also be said that set B is a superset of set A.

A subset is a proper subset if the elements of the subset do not contain all of the elements of the superset. For example, set A is a proper subset of set B if set B contains elements that are not in set A.
	DCS.N.3.2
	set operations

set difference
	Defined criteria that construct new sets from given sets. The set operations are unions, intersections, complements, and set differences.

The set difference of sets A and B is the set of elements in set A that are not in set B.
	DCS.N.3.3
	Venn diagram
	A diagram representing the relationship between mathematical or logical sets pictorially within an area defined as the universal set. Sets are often represented with circles with elements common to the sets located with the areas where the circles, representing the sets, overlap.
	DCS.N.4.1
	Euclidean Algorithm
	An iterative process used by technology to determine the greatest common factor and least common multiple for numbers  and , such that and .
	DCS.N.4.2
	Fundamental Theorem of Arithmetic
	If and is an integer, than  can we rewritten as a product of prime numbers that is unique to .
	Functions
Objective
	Word
	Definition
	DCS.F.1.2
	sigma notation
	The representation of the sum of a series using the Greek letter sigma. This notation is used to represent finite or infinite series. This notation is a shorthand way of representing each element in the series as the elements relate to each other.
	DCS.F.1.3
	finite sequence
	A sequence in which the number of elements is finite, or countable.
	DCS.F.1.4
	infinite sequence

converge

diverge
	A sequence in which the number of elements is infinite, or uncountable.

An infinite series converges when the sum of the elements approach a value without going over that value.

An infinite series diverges when the sum of the elements is infinite.

Statistics & Probability
Objective
	Word
	Definition
	DCS.SP.1.1
	Fundamental Counting Principle
	If one event can occur m ways and a second event can occur n ways after the first event, then the two events can occur in  ways.
	DCS.SP.1.2
	Permutation

combination
	The selection of subsets, without replacements, when the order of selection is a factor.

The selection of subsets, without replacements, when the order of selection is not a factor.
	Graph Theory
Objective
	Word
	Definition
	DCS.GT.1.1
	vertex-edge graph

adjacency matrix

vertex-edge table
	A graph that consists of points (vertices) and connections between the points (edges) that represent a context.

A matrix representing a vertex-edge graph in which the rows and columns are the vertices of the graph. The elements of the graph are 1s or 0s in which adjacent vertices are represented with a 1 and non-adjacent vertices are represented with a 0.

A table which displays the number of edges from each vertex. The number of edges from a vertex is also known as the degree of that vertex. In some cases, the vertex-edge table also includes a listing of all adjacent vertices. Also known as an edge table.
	DCS.GT.1.2
	Path

Circuit

Euler path

Euler circuit

Hamiltonian path

Hamiltonian circuit

	A sequence of adjacent vertices, vertices connected by an edge. In a path, an edge can only be used once.

A path that starts and ends at the same vertex.

A graph or digraph in which when starting at a vertex, one can travel through each edge exactly once and end at a different vertex.

A graph or digraph in which when starting at a vertex, one can travel through each edge exactly once and end at the starting vertex.

A graph or digraph in which when starting at a vertex, one can travel through each vertex exactly once and end at a different vertex.

A graph or digraph in which when starting at a vertex, one can travel through each vertex exactly once and end at the starting vertex.

	DCS.GT.1.3
	complete graph

digraph
	A graph is complete if all vertices are connected to all other vertices by an edge.

A directed graph in which the flow is from one vertex to another vertex represented by arrows.
	DCS.GT.2.1
	critical path

minimum project time
	The path from a vertex to the end of a project with the longest processing time.

The sum of the processing times for each task in the critical path. Also known as the critical time. The minimum project time provides an estimate of the minimum time needed to complete a project.
	DCS.GT.2.2
	Traveling Salesperson Problem

brute force method

nearest-neighbor algorithm

cheapest-link algorithm

	A category of problem, involving Hamiltonian circuits, in which the goal is to determine the most efficient pathway.

A method used to find the optimal solution to a Traveling Salesperson Problem. In this method, all possible Hamiltonian circuits are listed and the most optimal circuit is chosen.

An efficient method to find a solution to a Traveling Salesperson Problem. In this method, a starting vertex is chosen and the circuit is completed by taking the next edge with the lowest weight until the circuit is complete, avoiding any cycles.

An efficient method to find a solution to a Traveling Salesperson Problem. In this method, the circuit is constructed with the lowest weight edges of the graph, avoiding any cycles.
	DCS.GT.2.3
	vertex-coloring
	A way of using colors to label vertices to solve problems involving constraints. Vertices connected by an edge must have different colors. The solution to these problems is found by minimizing the number of colors used in the graph. This number is known as the chromatic number.
	DCS.GT.2.4
	connected graph

spanning tree

minimum spanning tree

weight of a path
Kruskal’s algorithm

Prim’s algorithm

	A graph is connected if a path joins any two vertices. When referring to a real-life application, a connected graph is commonly referred to as a network.

A subgraph that includes all vertices of the original graph with no circuits.

A subgraph with the least total weight that includes all vertices of the original graph with no circuits

The sum of all values of interest included in a path.
A method to identify a minimum spanning tree and the weight of that tree. In this method, the minimum spanning tree is constructed by marking the edges in order of the least weight, avoiding the creation of a cycle, until n-1 edges have been marked.

A method to identify a minimum spanning tree and the weight of that tree. In this method, the minimum spanning tree is constructed by marking the edge with the least weight and marking the next lowest edge adjacent to the edge just marked, avoiding the creation of a cycle. This pattern is repeated until all vertices are connected to the tree.
	Logic
Objective
	Word
	Definition
	DCS.L.1.1
	truth table
	A table that shows the truth-value of a compound statement for every truth value of its component statements.
	DCS.L.1.2
	Tautology

contradiction
	Assertions that are true in all interpretations

Assertions that are incompatible or incongruous
	DCS.L.1.3
	Boolean
	A logical combinatorial system that represents, symbolically, relationships between entities such as sets, propositions, or on-off computer circuit elements.
	Glossary by Alphabetical Order
Word
	Definition
	adjacency matrix
	A matrix representing a vertex-edge graph in which the rows and columns are the vertices of the graph. The elements of the graph are 1s or 0s in which adjacent vertices are represented with a 1 and non-adjacent vertices are represented with a 0.
	Boolean
	A logical combinatorial system that represents, symbolically, relationships between entities such as sets, propositions, or on-off computer circuit elements.
	brute force method
	A method used to find the optimal solution to a Traveling Salesperson Problem. In this method, all possible Hamiltonian circuits are listed and the most optimal circuit is chosen.
	cheapest-link algorithm
	An efficient method to find a solution to a Traveling Salesperson Problem. In this method, the circuit is constructed with the lowest weight edges of the graph, avoiding any cycles.
	circuit
	A path that starts and ends at the same vertex.
	combination
	The selection of subsets, without replacements, when the order of selection is not a factor.
	complete graph
	A graph is complete if all vertices are connected to all other vertices by an edge.
	connected graph
	A graph is connected if a path joins any two vertices. When referring to a real-life application, a connected graph is commonly referred to as a network.
	contradiction
	Assertions that are incompatible or incongruous
	converge
	An infinite series converges when the sum of the elements approach a value without going over that value.
	critical path
	The path from a vertex to the end of a project with the longest processing time.
	digraph
	A directed graph in which the flow is from one vertex to another vertex represented by arrows.
	diverge
	An infinite series diverges when the sum of the elements is infinite.
	Euclidean Algorithm
	An iterative process used by technology to determine the greatest common factor and least common multiple for numbers  and , such that and .
	Euler circuit
	A graph or digraph in which when starting at a vertex, one can travel through each edge exactly once and end at the starting vertex.
	Euler path
	A graph or digraph in which when starting at a vertex, one can travel through each edge exactly once and end at a different vertex.
	finite sequence
	A sequence in which the number of elements is finite, or countable.
	Fundamental Counting Principle
	If one event can occur m ways and a second event can occur n ways after the first event, then the two events can occur in  ways.
	Fundamental Theorem of Arithmetic
	If and is an integer, than  can we rewritten as a product of prime numbers that is unique to .
	Hamiltonian circuit
	A graph or digraph in which when starting at a vertex, one can travel through each vertex exactly once and end at the starting vertex.
	Hamiltonian path
	A graph or digraph in which when starting at a vertex, one can travel through each vertex exactly once and end at a different vertex.
	infinite sequence
	A sequence in which the number of elements is infinite, or uncountable.
	Inverse matrix
	is an inverse matrix of  if and only if , where  is the identity matrix. An inverse matrix does not exist for all matrices.
	Kruskal’s algorithm
	A method to identify a minimum spanning tree and the weight of that tree. In this method, the minimum spanning tree is constructed by marking the edges in order of the least weight, avoiding the creation of a cycle, until n-1 edges have been marked.
	Leslie Models
	The Leslie model is , where is the initial population matrix, is the Leslie matrix, and is the number of cycles. This model, named after P.H. Leslie, is most often used to model population growth over time when given a population age distribution, with corresponding birth and survival rates.
	Markov Chains
	A Markov chain is , where is the initial-state matrix, is the transition matrix, and is the number of transitions. Markov chains, named after Andrei Markov who studied linked chains of events, begins with an initial-state matrix that is multiplied by a transition matrix to produce the next state.
	matrix
	A rectangular array of elements organized in rows and columns.
	matrix equation
	An equation in which the variable is a matrix or elements within a matrix.
	minimum project time
	The sum of the processing times for each task in the critical path. Also known as the critical time. The minimum project time provides an estimate of the minimum time needed to complete a project.
	minimum spanning tree
	A subgraph with the least total weight that includes all vertices of the original graph with no circuits
	nearest-neighbor algorithm
	An efficient method to find a solution to a Traveling Salesperson Problem. In this method, a starting vertex is chosen and the circuit is completed by taking the next edge with the lowest weight until the circuit is complete, avoiding any cycles.
	path
	A sequence of adjacent vertices, vertices connected by an edge. In a path, an edge can only be used once.
	permutation
	The selection of subsets, without replacements, when the order of selection is a factor.
	Prim’s algorithm
	A method to identify a minimum spanning tree and the weight of that tree. In this method, the minimum spanning tree is constructed by marking the edge with the least weight and marking the next lowest edge adjacent to the edge just marked, avoiding the creation of a cycle. This pattern is repeated until all vertices are connected to the tree.
	proper subset
	A subset is a proper subset if the elements of the subset do not contain all of the elements of the superset. For example, set A is a proper subset of set B if set B contains elements that are not in set A.
	set difference
	The set difference of sets A and B is the set of elements in set A that are not in set B.
	set operations
	Defined criteria that construct new sets from given sets. The set operations are unions, intersections, complements, and set differences.
	sigma notation
	The representation of the sum of a series using the Greek letter sigma. This notation is used to represent finite or infinite series. This notation is a shorthand way of representing each element in the series as the elements relate to each other.
	spanning tree
	A subgraph that includes all vertices of the original graph with no circuits.
	subset
	A set is a subset if all the elements in the set are contained within another set. For example, set A is a subset of set B if all of the elements of set A are also elements in set B. It can also be said that set B is a superset of set A.
	tautology
	Assertions that are true in all interpretations
	Traveling Salesperson Problem
	A category of problem, involving Hamiltonian circuits, in which the goal is to determine the most efficient pathway.
	truth table
	A table that shows the truth-value of a compound statement for every truth value of its component statements.
	vector
	A quantity having both magnitude and direction.
	Venn diagram
	A diagram representing the relationship between mathematical or logical sets pictorially within an area defined as the universal set. Sets are often represented with circles with elements common to the sets located with the areas where the circles, representing the sets, overlap.
	vertex-coloring
	A way of using colors to label vertices to solve problems involving constraints. Vertices connected by an edge must have different colors. The solution to these problems is found by minimizing the number of colors used in the graph. This number is known as the chromatic number.
	vertex-edge graph
	A graph that consists of points (vertices) and connections between the points (edges) that represent a context.
	vertex-edge table
	A table which displays the number of edges from each vertex. The number of edges from a vertex is also known as the degree of that vertex. In some cases, the vertex-edge table also includes a listing of all adjacent vertices. Also known as an edge table.
	weight of a path
	The sum of all values of interest included in a path.

NCDPI Glossary of Terms        Discrete Mathematics for Computer Science        Revised June 2020
