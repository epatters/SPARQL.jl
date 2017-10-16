module Writer
export pprint

using ..AST

""" Pretty print a SPARQL AST in valid SPARQL syntax.
"""
pprint(ast::SPARQLNode) = pprint(STDOUT, ast)
pprint(io::IO, ast::SPARQLNode) = pprint(io, ast, 0)

# Nodes
#######

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

# Calls
#######

const unary_ops = Set([:!, :+, :-])
const binary_ops = Set([:(=), :!=, :<, :>, :<=, :>=, :&&, :||, :+, :-, :*, :/,
                        :IN, Symbol("NOT IN") ])

function pprint(io::IO, expr::Call, n::Int)
  pprint_expr(io, expr, false)
end

function pprint_expr(io::IO, expr::Expression, paren::Bool)
  pprint(io, expr)
end
function pprint_expr(io::IO, expr::Call, paren::Bool)
  # Case 1: Unary operation.
  if length(expr.args) == 1 && expr.head in unary_ops
    if paren; print(io, "(") end
    print(io, expr.head, " ")
    pprint_expr(io, first(expr.args), true)
    if paren; print(io, ")") end
  
  # Case 2: Binary operation.
  elseif expr.head in binary_ops
    if paren; print(io, "(") end
    for (i, arg) in enumerate(expr.args)
      if i > 1
        print(io, " ", expr.head, " ")
      end
      pprint_expr(io, arg, true)
    end
    if paren; print(io, ")") end
  
  # Case 3: Builtin function call.
  else
    print(io, expr.head, "(")
    join(io, (sprint(pprint, arg) for arg in expr.args), ",")
    print(io, ")")
  end
end

# Patterns
##########

function pprint(io::IO, binding::VariableBinding, n::Int)
  print(io, "(")
  pprint(io, first(binding))
  print(io, " AS ")
  pprint(io, last(binding))
  print(io, ")")
end
pprint(io::IO, binding::VariableBinding) = pprint(io, binding, 0)

function pprint(io::IO, triple::Triple, n::Int)
  pprint(io, triple.subject)
  print(io, " ")
  pprint(io, triple.predicate)
  print(io, " ")
  pprint(io, triple.object)
end

function pprint(io::IO, pattern::Bind, n::Int)
  print(io, "BIND")
  pprint(io, pattern.binding)
end

function pprint(io::IO, pattern::Filter_, n::Int)
  print(io, "FILTER(")
  pprint(io, pattern.constraint)
  print(io, ")")
end

# Query
#######

function pprint(io::IO, query::Select, n::Int)
  pprint_clauses(io, query.clauses, PrologueClause, n)
  
  iprint(io, n,
    if query.distinct
      "SELECT DISTINCT "
    elseif query.reduced
      "SELECT REDUCED "
    else
      "SELECT "
    end)
  join(io, (sprint(pprint, var) for var in query.variables), " ")
  println(io)
  
  pprint_clauses(io, query.clauses, Dataset, n)
  iprint(io, n, "WHERE ")
  pprint_block(io, query.patterns, n+2)
  pprint_clauses(io, query.clauses, SolutionModifierClause, n)
end

function pprint(io::IO, query::Construct, n::Int)
  pprint_clauses(io, query.clauses, PrologueClause, n)
  
  iprint(io, n, "CONSTRUCT ")
  pprint_block(io, query.construct, n+2)
  
  pprint_clauses(io, query.clauses, Dataset, n)
  iprint(io, n, "WHERE ")
  pprint_block(io, query.patterns, n+2)
  pprint_clauses(io, query.clauses, SolutionModifierClause, n)
end

function pprint(io::IO, query::Ask, n::Int)
  pprint_clauses(io, query.clauses, PrologueClause, n)
  
  iprint(io, n, "ASK")
  
  if any(isa(clause, Dataset) for clause in query.clauses)
    println(io)
    pprint_clauses(io, query.clauses, Dataset, n)
    iprint(io, n, "WHERE ")
  else
    print(io, " ")
  end
  pprint_block(io, query.patterns, n+2)
  pprint_clauses(io, query.clauses, SolutionModifierClause, n)
end

function pprint(io::IO, query::Describe, n::Int)
  pprint_clauses(io, query.clauses, PrologueClause, n)
  
  iprint(io, n, "DESCRIBE ")
  join(io, (sprint(pprint, node) for node in query.nodes), " ")
  println(io)
  
  pprint_clauses(io, query.clauses, Dataset, n)
  if !isempty(query.patterns)
    iprint(io, n, "WHERE ")
    pprint_block(io, query.patterns, n+2)
  end
  pprint_clauses(io, query.clauses, SolutionModifierClause, n)
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

function pprint_clauses(io::IO, clauses::Vector{<:Clause}, typ::Type, n::Int)
  for clause in clauses
    if isa(clause, typ)
      pprint(io, clause, n)
    end
  end
end

# Clauses
#########

function pprint(io::IO, base::BaseURI, n::Int)
  iprintln(io, n, "BASE <", base.uri, ">")
end

function pprint(io::IO, prefix::Prefix, n::Int)
  iprintln(io, n, "PREFIX ", prefix.name, ": <", prefix.uri, ">")
end

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
  iprintln(io, n, "LIMIT ", clause.count)
end

function pprint(io::IO, clause::Offset, n::Int)
  iprintln(io, n, "OFFSET ", clause.count)
end

function pprint(io::IO, clause::GroupBy, n::Int)
  iprint(io, n, "GROUP BY ")
  join(io, (sprint(pprint, var) for var in clause.variables), " ")
  println(io)
end

function pprint(io::IO, clause::Having, n::Int)
  iprint(io, n, "HAVING(")
  pprint(io, clause.constraint)
  println(io, ")")
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
