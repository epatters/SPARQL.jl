module AST
export SPARQLNode, Clause, Statement, Expression, Call,
  Node, Resource, ResourceURI, ResourceCURIE, Literal, Blank, Variable, Triple,
  Query, Select, Construct, Ask, Describe,
  PrologueClause, BaseURI, Prefix,
  SolutionModifierClause, Dataset, OrderBy, Limit, Offset, GroupBy, Having

using AutoHashEquals

""" Base type for all nodes in SPARQL AST.
"""
abstract type SPARQLNode end

""" Base type for (subordinate) clauses in SPARQL grammar.
"""
abstract type Clause <: SPARQLNode end

""" Base type for (complete) statements in SPARQL grammar.
"""
abstract type Statement <: SPARQLNode end

""" Base type for expression nodes in SPARQL AST.
"""
abstract type Expression <: SPARQLNode end

# Nodes and triples
###################

abstract type Node <: Expression end
abstract type Resource <: Node end

@auto_hash_equals struct ResourceURI <: Resource
  uri::String
end

@auto_hash_equals struct ResourceCURIE <: Resource
  prefix::String
  name::String
end

@auto_hash_equals struct Literal <: Node
  value::Any
  language::String
  Literal(value::Any, language::String="") = new(value, language)
end

@auto_hash_equals struct Blank <: Node
  name::String
end

@auto_hash_equals struct Variable <: Node
  name::String
end

@auto_hash_equals struct Triple <: SPARQLNode
  subject::Node
  predicate::Node
  object::Node
end

# Convenience constructors
Resource(uri::String) = ResourceURI(uri)
Resource(prefix::String, name::String) = ResourceCURIE(prefix, name)

# Calls
#######

@auto_hash_equals struct Call <: Expression
  head::Symbol
  args::Vector{<:Expression}
  Call(head, args...) = new(head, collect(args))
end

# Query
#######

abstract type Query <: Statement end

const VariableBinding = Union{Variable,Pair{Expression,Variable}}

@auto_hash_equals struct Select <: Query
  variables::Vector{<:VariableBinding}
  pattern::Vector{Triple}
  clauses::Vector{<:Clause}
  distinct::Bool
  reduced::Bool
  
  function Select(vars::Vector{<:VariableBinding}, pattern::Vector{Triple}, args...;
                  distinct::Bool=false, reduced::Bool=false)
    new(vars, pattern, collect(args), distinct, reduced)
  end
end

@auto_hash_equals struct Construct <: Query
  construct::Vector{Triple}
  pattern::Vector{Triple}
  clauses::Vector{<:Clause}
  
  function Construct(cons::Vector{Triple}, pattern::Vector{Triple}, args...)
    new(cons, pattern, collect(args))
  end
end

@auto_hash_equals struct Ask <: Query
  pattern::Vector{Triple}
  clauses::Vector{<:Clause}
  
  function Ask(pattern::Vector{Triple}, args...)
    new(pattern, collect(args))
  end
end

@auto_hash_equals struct Describe <: Query
  nodes::Vector{<:Node}
  pattern::Vector{Triple}
  clauses::Vector{<:Clause}
  
  function Describe(nodes::Vector{<:Node}, args...)
    new(nodes, Triple[], collect(args))
  end
  function Describe(nodes::Vector{<:Node}, pattern::Vector{Triple}, args...)
    new(nodes, pattern, collect(args))
  end
end

# Clauses
#########

abstract type PrologueClause <: Clause end
abstract type SolutionModifierClause <: Clause end

@auto_hash_equals struct BaseURI <: PrologueClause
  uri::String
end

@auto_hash_equals struct Prefix <: PrologueClause
  name::String
  uri::String
end

@auto_hash_equals struct Dataset <: Clause
  resource::Resource
  named::Bool
  Dataset(resource::Resource; named::Bool=false) = new(resource, named)
end

@auto_hash_equals struct OrderBy <: SolutionModifierClause
  variables::Vector{<:Expression}
end
OrderBy(variable::Expression) = OrderBy([variable])

@auto_hash_equals struct Limit <: SolutionModifierClause
  count::Int
end

@auto_hash_equals struct Offset <: SolutionModifierClause
  count::Int
end

@auto_hash_equals struct GroupBy <: SolutionModifierClause
  variables::Vector{<:VariableBinding}
end
GroupBy(variable::VariableBinding) = GroupBy([variable])

@auto_hash_equals struct Having <: SolutionModifierClause
  constraint::Expression
end

end
