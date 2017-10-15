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

# Query
#######

# Select

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

# Construct

@test spprint(Construct(
  [ Triple(Resource("http://example.org/person#Alice"), Resource("vcard","FN"), Variable("name")) ],
  [ Triple(Variable("x"), Resource("foaf","name"), Variable("name")) ],
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
  Prefix("vcard", "http://www.w3.org/2001/vcard-rdf/3.0#"),
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
PREFIX vcard: <http://www.w3.org/2001/vcard-rdf/3.0#>
CONSTRUCT { <http://example.org/person#Alice> vcard:FN ?name }
WHERE { ?x foaf:name ?name }
"""

# Ask

@test spprint(Ask(
  [ Triple(Variable("x"), Resource("foaf","name"), Literal("Alice")) ],
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
ASK { ?x foaf:name "Alice" }
"""

@test spprint(Ask(
  [ Triple(Variable("x"), Resource("foaf","name"), Literal("Alice")) ],
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
  Dataset(Resource("http://example.org/foaf/aliceFoaf")),
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
ASK
FROM <http://example.org/foaf/aliceFoaf>
WHERE { ?x foaf:name "Alice" }
"""

# Describe

@test spprint(Describe(
  [ Resource("http://example.org/") ],
)) == "DESCRIBE <http://example.org/>\n"

@test spprint(Describe(
  [ Variable("x") ],
  [ Triple(Variable("x"), Resource("foaf","mbox"), Resource("mailto:alice@org")) ],
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
DESCRIBE ?x
WHERE { ?x foaf:mbox <mailto:alice@org> }
"""

# Clauses
#########

@test spprint(BaseURI("http://www.example.com")) ==
  "BASE <http://www.example.com>\n"
@test spprint(Prefix("ex", "http://www.example.com")) ==
  "PREFIX ex: <http://www.example.com>\n"

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
