module TestWriter
using Base.Test

using SPARQL.AST
using SPARQL.Writer

spprint(ast::SPARQLNode) = sprint(pprint, ast)

# Nodes
#######

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

# Unary operators
@test spprint(Call(:!, Variable("x"))) == "! ?x"
@test spprint(Call(:-, Variable("x"))) == "- ?x"

# Binary operators
@test spprint(Call(:!=, Variable("x"), Variable("y"))) == "?x != ?y"
@test spprint(Call(:+, Variable("x"), Literal(1))) == "?x + 1"
@test spprint(Call(:+, Variable("x"), Variable("y"), Literal(1))) == "?x + ?y + 1"
@test spprint(Call(:+,
  Variable("x"),
  Call(:*, Variable("y"), Literal(2)))) == "?x + (?y * 2)"
@test spprint(Call(:*,
  Variable("x"),
  Call(:+, Variable("y"), Literal(1)))) == "?x * (?y + 1)"

# Builtin calls
@test spprint(Call(:STRLEN, Literal("foo"))) == "STRLEN(\"foo\")"
@test spprint(Call(:CEIL, Literal(1.5))) == "CEIL(1.5)"
@test spprint(Call(:IF,
  Call(:CONTAINS, Variable("x"), Literal("foo")),
  Call(:UCASE, Variable("x")),
  Call(:LCASE, Variable("x"))
)) == """IF(CONTAINS(?x,"foo"),UCASE(?x),LCASE(?x))"""

# Patterns
##########

@test spprint(Triple(Resource("ex","bob"), Resource("rdf","type"), Resource("ex","Person"))) ==
  "ex:bob rdf:type ex:Person"

# Property patterns

@test spprint(Triple(
  Resource("","book1"),
  Call(:|, Resource("dc","title"), Resource("rdfs","label")),
  Variable("displayString")
)) == ":book1 dc:title|rdfs:label ?displayString"

@test spprint(Triple(
  Variable("x"),
  Call(:/, Resource("foaf","knows"), Resource("foaf","name")),
  Variable("name")
)) == "?x foaf:knows/foaf:name ?name"

@test spprint(Triple(
  Resource("mailto:alice@example"),
  Call(:^, Resource("foaf","mbox")),
  Variable("x")
)) == "<mailto:alice@example> ^foaf:mbox ?x"

@test spprint(Triple(
  Variable("x"),
  Call(:/, Resource("foaf","knows"), Call(:^, Resource("foaf","knows"))),
  Variable("y")
)) == "?x foaf:knows / (^foaf:knows) ?y"

# Special keywords

@test spprint(Graph(
  Variable("graph"),
  [ Triple(Variable("sub"), Variable("pred"), Variable("obj")) ]
)) == "GRAPH ?graph { ?sub ?pred ?obj }"
  
@test spprint(Optional([
  Triple(Variable("x"), Resource("foaf","mbox"), Variable("mbox"))
])) == "OPTIONAL { ?x foaf:mbox ?mbox }"

@test spprint(Bind(Call(:+, Variable("x"), Variable("y")) => Variable("z"))) ==
  "BIND(?x + ?y AS ?z)"
@test spprint(Filter_(Call(:>, Variable("x"), Literal(10)))) ==
  "FILTER(?x > 10)"

# Query
#######

# Select

@test spprint(Select(
  [ Variable("name"), Variable("mbox") ],
  Where([
    Triple(Variable("x"), Resource("foaf","name"), Variable("name")),
    Triple(Variable("x"), Resource("foaf","mbox"), Variable("mbox")),
  ]),
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
  Where([ Triple(Variable("x"), Resource("foaf","name"), Variable("name")) ]),
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
  Where([Triple(Variable("x"), Resource("foaf","name"), Variable("name")) ]),
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
  OrderBy(Variable("name"))
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?name
WHERE { ?x foaf:name ?name }
ORDER BY ?name
"""

@test spprint(Select(
  [ Variable("src"), Variable("bobNick") ],
  Where([
    Graph(
      Variable("src"),
      [ Triple(Variable("x"), Resource("foaf","mbox"), Resource("mailto:bob@work.example")),
        Triple(Variable("x"), Resource("foaf","nick"), Variable("bobNick")) ])
  ]),
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
  Dataset(Resource("http://example.org/foaf/aliceFoaf"); named=true),
  Dataset(Resource("http://example.org/foaf/bobFoaf"); named=true),
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?src ?bobNick
FROM NAMED <http://example.org/foaf/aliceFoaf>
FROM NAMED <http://example.org/foaf/bobFoaf>
WHERE {
  GRAPH ?src {
    ?x foaf:mbox <mailto:bob@work.example> .
    ?x foaf:nick ?bobNick } }
"""

@test spprint(Select(
  [ Variable("name"), Variable("mbox") ],
  Where([
    Triple(Variable("x"), Resource("foaf","name"), Variable("name")),
    Optional([
      Triple(Variable("x"), Resource("foaf","mbox"), Variable("mbox"))
    ]),
  ]),
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
SELECT ?name ?mbox
WHERE {
  ?x foaf:name ?name .
  OPTIONAL { ?x foaf:mbox ?mbox } }
"""

# Construct

@test spprint(Construct(
  [ Triple(Resource("http://example.org/person#Alice"), Resource("vcard","FN"), Variable("name")) ],
  Where([ Triple(Variable("x"), Resource("foaf","name"), Variable("name")) ]),
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
  Where([ Triple(Variable("x"), Resource("foaf","name"), Literal("Alice")) ]),
  Prefix("foaf", "http://xmlns.com/foaf/0.1/"),
)) == """
PREFIX foaf: <http://xmlns.com/foaf/0.1/>
ASK WHERE { ?x foaf:name "Alice" }
"""

@test spprint(Ask(
  Where([ Triple(Variable("x"), Resource("foaf","name"), Literal("Alice")) ]),
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
  Where([
    Triple(Variable("x"), Resource("foaf","mbox"), Resource("mailto:alice@org"))
  ]),
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

@test spprint(Where()) == "WHERE { }\n"
@test spprint(Where([
  Triple(Variable("x"), Resource("foaf","name"), Literal("Alice"))
])) == """WHERE { ?x foaf:name "Alice" }\n"""
@test spprint(Where([
  Triple(Variable("x"), Resource("foaf","name"), Variable("name")),
  Triple(Variable("x"), Resource("foaf","mbox"), Variable("mbox"))
])) == """
WHERE {
  ?x foaf:name ?name .
  ?x foaf:mbox ?mbox }
"""

@test spprint(OrderBy(Variable("x"))) == "ORDER BY ?x\n"
@test spprint(OrderBy([Variable("x"),Variable("y")])) == "ORDER BY ?x ?y\n"

@test spprint(Limit(10)) == "LIMIT 10\n"
@test spprint(Offset(5)) == "OFFSET 5\n"

@test spprint(GroupBy(Variable("x"))) == "GROUP BY ?x\n"
@test spprint(GroupBy([Variable("x"),Variable("y")])) == "GROUP BY ?x ?y\n"

@test spprint(Having(Call(:>, Call(:AVG, Variable("size")), Literal(10)))) ==
  "HAVING(AVG(?size) > 10)\n"

end
