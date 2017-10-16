module AST
export SPARQLNode, Clause, Statement, Expression, Call,
  Node, Resource, ResourceURI, ResourceCURIE, Literal, Blank, Variable,
  Pattern, VariableBinding, Triple, Graph, Optional, Bind, Filter_,
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

# Nodes
#######

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

# Patterns
##########

abstract type Pattern <: SPARQLNode end

const VariableBinding = Pair{<:Expression,Variable}
const VariableOrBinding = Union{Variable,VariableBinding}

@auto_hash_equals struct Triple <: Pattern
  subject::Node
  predicate::Node
  object::Node
end

@auto_hash_equals struct Graph <: Pattern
  node::Node
  patterns::Vector{<:Pattern}
end

@auto_hash_equals struct Optional <: Pattern
  patterns::Vector{<:Pattern}
end

@auto_hash_equals struct Bind <: Pattern
  binding::VariableBinding
end

# XXX: Use `Filter_` until the deprecated `Base.Filter` is removed.
@auto_hash_equals struct Filter_ <: Pattern
  constraint::Expression
end

# Query
#######

abstract type Query <: Statement end

@auto_hash_equals struct Select <: Query
  variables::Vector{<:VariableOrBinding}
  patterns::Vector{<:Pattern}
  clauses::Vector{<:Clause}
  distinct::Bool
  reduced::Bool
  
  function Select(vars::Vector{<:VariableOrBinding}, patterns::Vector{<:Pattern},
                  args...; distinct::Bool=false, reduced::Bool=false)
    new(vars, patterns, collect(args), distinct, reduced)
  end
end

@auto_hash_equals struct Construct <: Query
  construct::Vector{Triple}
  patterns::Vector{<:Pattern}
  clauses::Vector{<:Clause}
  
  function Construct(cons::Vector{Triple}, patterns::Vector{<:Pattern}, args...)
    new(cons, patterns, collect(args))
  end
end

@auto_hash_equals struct Ask <: Query
  patterns::Vector{<:Pattern}
  clauses::Vector{<:Clause}
  
  function Ask(patterns::Vector{<:Pattern}, args...)
    new(patterns, collect(args))
  end
end

@auto_hash_equals struct Describe <: Query
  nodes::Vector{<:Node}
  patterns::Vector{<:Pattern}
  clauses::Vector{<:Clause}
  
  function Describe(nodes::Vector{<:Node}, args...)
    new(nodes, Pattern[], collect(args))
  end
  function Describe(nodes::Vector{<:Node}, patterns::Vector{<:Pattern}, args...)
    new(nodes, patterns, collect(args))
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
  variables::Vector{<:VariableOrBinding}
end
GroupBy(variable::VariableOrBinding) = GroupBy([variable])

@auto_hash_equals struct Having <: SolutionModifierClause
  constraint::Expression
end

end
