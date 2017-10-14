module AST
export SPARQLNode, Clause, Statement,
  Node, Resource, ResourceURI, ResourceCURIE, Literal, Blank, Variable, Triple,
  Expression,
  PrologueClause, BaseURI, Prefix,
  Query, Select, Construct, Ask, Describe

using AutoHashEquals

""" Base type for all nodes in SPARQL AST.
"""
abstract type SPARQLNode end

""" Base type for clauses (subordinate expressions) in SPARQL grammar.
"""
abstract type Clause <: SPARQLNode end

""" Base type for statements (complete expressions) in SPARQL grammar.
"""
abstract type Statement <: SPARQLNode end

# Nodes and triples
###################

abstract type Node <: SPARQLNode end
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

# Expressions
#############

abstract type Expression <: Node end

# Prologue
##########

abstract type PrologueClause <: Clause end

@auto_hash_equals struct BaseURI <: PrologueClause
  uri::String
end

@auto_hash_equals struct Prefix <: PrologueClause
  name::String
  uri::String
end

# Query
#######

abstract type Query <: Statement end

const VariableBinding = Union{Variable,Pair{Expression,Variable}}

@auto_hash_equals struct Select <: Query
  variables::Vector{<:VariableBinding}
  pattern::Vector{Triple}
  modifiers::Vector{<:Clause}
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
  modifiers::Vector{<:Clause}
  
  function Construct(cons::Vector{Triple}, pattern::Vector{Triple}, args...)
    new(cons, pattern, collect(args))
  end
end

@auto_hash_equals struct Ask <: Query
  pattern::Vector{Triple}
  modifiers::Vector{<:Clause}
  
  function Ask(pattern::Vector{Triple}, args...)
    new(pattern, collect(args))
  end
end

@auto_hash_equals struct Describe <: Query
  nodes::Vector{<:Node}
  pattern::Vector{Triple}
  modifiers::Vector{<:Clause}
  
  function Describe(nodes::Vector{<:Node}, pattern::Vector{Triple}, args...)
    new(nodes, pattern, collect(args))
  end
end

end
