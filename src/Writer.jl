module Writer
export pprint

using ..AST

""" Pretty print a SPARQL AST in valid SPARQL syntax.
"""
pprint(ast::SPARQLNode) = pprint(STDOUT, ast)
pprint(io::IO, ast::SPARQLNode) = pprint(io, ast, 0)

# Nodes and triples
###################

function pprint(io::IO, node::ResourceURI, n::Int)
  print(io, "<", node.uri, ">")
end

function pprint(io::IO, node::ResourceCURIE, n::Int)
  print(io, node.prefix, ":", node.name)
end

function pprint(io::IO, node::Literal, n::Int)
  pprint_literal(io, node.value)
  if !isempty(node.language)
    print(io, "@", node.language)
  end
end

pprint_literal(io::IO, value::Any) = print(io, value)
pprint_literal(io::IO, value::AbstractString) = print(io, repr(value))

function pprint(io::IO, node::Blank, n::Int)
  print(io, "_:", node.name)
end

function pprint(io::IO, node::Variable, n::Int)
  print(io, "?", node.name)
end

function pprint(io::IO, triple::Triple, n::Int)
  pprint(io, triple.subject)
  print(io, " ")
  pprint(io, triple.predicate)
  print(io, " ")
  pprint(io, triple.object)
end

# Prologue
##########

function pprint(io::IO, base::BaseURI, n::Int)
  iprintln(io, n, "BASE <", base.uri, ">")
end

function pprint(io::IO, prefix::Prefix, n::Int)
  iprintln(io, n, "PREFIX ", prefix.name, ": <", prefix.uri, ">")
end

# Query
#######

function pprint(io::IO, select::Select, n::Int)
  for clause in select.clauses
    if isa(clause, PrologueClause)
      pprint(io, clause, n)
    end
  end
  
  iprint(io, n,
    if select.distinct
      "SELECT DISTINCT "
    elseif select.reduced
      "SELECT REDUCED "
    else
      "SELECT "
    end)
  join(io, (sprint(pprint, var) for var in select.variables), " ")
  println(io)
  
  for clause in select.clauses
    if isa(clause, Dataset)
      pprint(io, clause, n)
    end
  end
  
  iprint(io, n, "WHERE ")
  pprint_block(io, select.pattern, n+2)
  
  for clause in select.clauses
    if !(isa(clause, Dataset) || isa(clause, PrologueClause))
      pprint(io, clause, n)
    end
  end
end

function pprint(io::IO, binding::Pair{Expression,Variable}, n::Int)
  print(io, "(")
  pprint(io, first(binding))
  print(io, " AS ")
  pprint(io, last(binding))
  print(io, ")")
end

function pprint_block(io::IO, expressions::Vector, n::Int)
  if isempty(expressions)
    println(io, "{ }")
  elseif length(expressions) == 1
    print(io, "{ ")
    pprint(io, first(expressions))
    println(io, " }")
  else  
    println(io, "{")
    for (i, expr) in enumerate(expressions)
      if i != 1
        println(io, " .")
      end
      indent(io, n)
      pprint(io, expr)
    end
    println(io, " }")
  end
end

# Clauses
#########

function pprint(io::IO, clause::Dataset, n::Int)
  iprint(io, n, "FROM ")
  if clause.named
    print(io, "NAMED ")
  end
  pprint(io, clause.resource)
  println(io)
end

function pprint(io::IO, clause::OrderBy, n::Int)
  iprint(io, n, "ORDER BY ")
  join(io, (sprint(pprint, var) for var in clause.variables), " ")
  println(io)
end

function pprint(io::IO, clause::Limit, n::Int)
  iprintln(io, n, "LIMIT $(clause.count)")
end

function pprint(io::IO, clause::Offset, n::Int)
  iprintln(io, n, "OFFSET $(clause.count)")
end

function pprint(io::IO, clause::GroupBy, n::Int)
  iprint(io, n, "GROUP BY ")
  join(io, (sprint(pprint, var) for var in clause.variables), " ")
  println(io)
end

function pprint(io::IO, clause::Having, n::Int)
  iprint(io, n, "HAVING ")
  pprint(io, clause.constraint)
  println(io)
end

# Utilities
###########

indent(io::IO, n::Int) = print(io, " "^n)

function iprint(io::IO, n::Int, xs...)
  indent(io, n)
  print(io, xs...)
end

function iprintln(io::IO, n::Int, xs...)
  indent(io, n)
  println(io, xs...)
end

end
