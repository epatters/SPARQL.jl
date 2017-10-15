module TestWriter
using Base.Test

using SPARQL.AST
using SPARQL.Writer

spprint(ast::SPARQLNode) = sprint(pprint, ast)

# Nodes and triples
###################

@test spprint(ResourceCURIE("ex", "bob")) == "ex:bob"
@test spprint(ResourceURI("http://www.example.com")) == "<http://www.example.com>"
@test spprint(Literal("string")) == "\"string\""
@test spprint(Literal("string", "en")) == "\"string\"@en"
@test spprint(Literal(1)) == "1"
@test spprint(Literal(1.0)) == "1.0"
@test spprint(Literal(true)) == "true"
@test spprint(Literal(false)) == "false"
@test spprint(Blank("b")) == "_:b"
@test spprint(Variable("a")) == "?a"
@test spprint(Triple(Resource("ex","bob"), Resource("rdf","type"), Resource("ex","Person"))) ==
  "ex:bob rdf:type ex:Person"

# Prologue
##########

@test spprint(BaseURI("http://www.example.com")) ==
  "BASE <http://www.example.com>\n"
@test spprint(Prefix("ex", "http://www.example.com")) ==
  "PREFIX ex: <http://www.example.com>\n"

# Query
#######

@test spprint(Select(
  [ Variable("name"), Variable("mbox") ],
  [ Triple(Variable("x"), Resource("foaf","name"), Variable("name")),
    Triple(Variable("x"), Resource("foaf","mbox"), Variable("mbox")) ],
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?name ?mbox
WHERE {
  ?x foaf:name ?name .
  ?x foaf:mbox ?mbox }
"""

@test spprint(Select(
  [ Variable("name") ],
  [ Triple(Variable("x"), Resource("foaf","name"), Variable("name")) ],
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
  Dataset(Resource("http://example.org/foaf/aliceFoaf")),
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?name
FROM <http://example.org/foaf/aliceFoaf>
WHERE { ?x foaf:name ?name }
"""

@test spprint(Select(
  [ Variable("name") ],
  [ Triple(Variable("x"), Resource("foaf","name"), Variable("name")) ],
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
  OrderBy(Variable("name"))
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?name
WHERE { ?x foaf:name ?name }
ORDER BY ?name
"""

# Clauses
#########

@test spprint(Dataset(Resource("http://example.org"))) ==
  "FROM <http://example.org>\n"
@test spprint(Dataset(Resource("http://example.org/alice"), named=true)) ==
  "FROM NAMED <http://example.org/alice>\n"

@test spprint(OrderBy(Variable("x"))) == "ORDER BY ?x\n"
@test spprint(OrderBy([Variable("x"),Variable("y")])) == "ORDER BY ?x ?y\n"

@test spprint(Limit(10)) == "LIMIT 10\n"
@test spprint(Offset(5)) == "OFFSET 5\n"

@test spprint(GroupBy(Variable("x"))) == "GROUP BY ?x\n"
@test spprint(GroupBy([Variable("x"),Variable("y")])) == "GROUP BY ?x ?y\n"

@test spprint(Having(Variable("x"))) == "HAVING ?x\n"

end
