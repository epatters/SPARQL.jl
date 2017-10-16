module Writer
export pprint

using ..AST

""" Pretty print a SPARQL AST in valid SPARQL syntax.
"""
pprint(expr::Expression) = pprint(STDOUT, expr)
pprint(io::IO, expr::Expression) = pprint(io, expr, 0)

# Nodes
#######

const unary_prefix_ops = Set([:!, :-, :^])
const unary_postfix_ops = Set([:*, :+, :?])
const unary_ops = union(unary_prefix_ops, unary_postfix_ops)
const binary_ops = Set([:(=), :!=, :<, :>, :<=, :>=, :&, :|, :&&, :||,
                        :+, :-, :*, :/, :IN, Symbol("NOT IN") ])

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

function pprint(io::IO, node::Call, n::Int)
  pprint_node(io, node, false)
end

function pprint_node(io::IO, node::Node, paren::Bool)
  pprint(io, node)
end
function pprint_node(io::IO, node::Call, paren::Bool)
  # Space between operator and operands. Purely cosmetic.
  op_space = all(isa(arg, ResourceCURIE) for arg in node.args) ? "" : " "
  
  # Case 1: Unary operation.
  if length(node.args) == 1 && node.head in unary_ops
    arg = first(node.args)
    if paren; print(io, "(") end
    if node.head in unary_prefix_ops
      print(io, node.head, op_space)
    end
    pprint_node(io, arg, true)
    if node.head in unary_postfix_ops
      print(io, op_space, node.head)
    end
    if paren; print(io, ")") end
  
  # Case 2: Binary operation.
  elseif node.head in binary_ops
    if paren; print(io, "(") end
    for (i, arg) in enumerate(node.args)
      if i > 1
        print(io, op_space, node.head, op_space)
      end
      pprint_node(io, arg, true)
    end
    if paren; print(io, ")") end
  
  # Case 3: Builtin function call.
  else
    print(io, node.head, "(")
    join(io, (sprint(pprint, arg) for arg in node.args), ",")
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

function pprint(io::IO, graph::Graph, n::Int)
  print(io, "GRAPH ")
  pprint(io, graph.node)
  print(io, " ")
  pprint_patterns(io, graph.patterns, n+2; newline=false)
end

function pprint(io::IO, optional::Optional, n::Int)
  print(io, "OPTIONAL ")
  pprint_patterns(io, optional.patterns, n+2; newline=false)
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

function pprint_patterns(io::IO, patterns::Vector, n::Int; newline::Bool=true)
  if isempty(patterns)
    print(io, "{ }")
  elseif length(patterns) == 1 && isa(first(patterns), Triple)
    print(io, "{ ")
    pprint(io, first(patterns))
    print(io, " }")
  else
    println(io, "{")
    for (i, pattern) in enumerate(patterns)
      if i != 1
        println(io, " .")
      end
      indent(io, n)
      pprint(io, pattern, n)
    end
    print(io, " }")
  end
  if newline; println(io) end
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
  pprint_clauses(io, query.clauses, Where, n)
  pprint_clauses(io, query.clauses, SolutionModifierClause, n)
end

function pprint(io::IO, query::Construct, n::Int)
  pprint_clauses(io, query.clauses, PrologueClause, n)
  
  iprint(io, n, "CONSTRUCT ")
  pprint_patterns(io, query.construct, n+2)
  
  pprint_clauses(io, query.clauses, Dataset, n)
  pprint_clauses(io, query.clauses, Where, n)
  pprint_clauses(io, query.clauses, SolutionModifierClause, n)
end

function pprint(io::IO, query::Ask, n::Int)
  pprint_clauses(io, query.clauses, PrologueClause, n)
  
  iprint(io, n, "ASK")
  if any(isa(clause, Dataset) for clause in query.clauses)
    println(io)
  else
    print(io, " ")
  end
  
  pprint_clauses(io, query.clauses, Dataset, n)
  pprint_clauses(io, query.clauses, Where, n)
  pprint_clauses(io, query.clauses, SolutionModifierClause, n)
end

function pprint(io::IO, query::Describe, n::Int)
  pprint_clauses(io, query.clauses, PrologueClause, n)
  
  iprint(io, n, "DESCRIBE ")
  join(io, (sprint(pprint, node) for node in query.nodes), " ")
  println(io)
  
  pprint_clauses(io, query.clauses, Dataset, n)
  pprint_clauses(io, query.clauses, Where, n)
  pprint_clauses(io, query.clauses, SolutionModifierClause, n)
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

function pprint(io::IO, clause::Where, n::Int)
  iprint(io, n, "WHERE ")
  pprint_patterns(io, clause.patterns, n+2)
end

function pprint(io::IO, clause::OrderBy, n::Int)
  iprint(io, n, "ORDER BY ")
  join(io, (sprint(pprint, node) for node in clause.nodes), " ")
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
