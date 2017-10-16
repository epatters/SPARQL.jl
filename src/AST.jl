module AST
export Expression, Clause, Statement,
  Node, Resource, ResourceURI, ResourceCURIE, Literal, Blank, Variable, Call,
  Pattern, VariableBinding, Triple, Graph, Optional, Bind, Filter_,
  Query, Select, Construct, Ask, Describe, Dataset, Where,
  PrologueClause, BaseURI, Prefix,
  SolutionModifierClause, OrderBy, Limit, Offset, GroupBy, Having

using AutoHashEquals

""" Base type for all expressions in SPARQL grammar.
"""
abstract type Expression end

""" Base type for subordinate clauses in SPARQL grammar.
"""
abstract type Clause <: Expression end

""" Base type for complete statements in SPARQL grammar.
"""
abstract type Statement <: Expression end

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

@auto_hash_equals struct Call <: Node
  head::Symbol
  args::Vector{<:Node}
  Call(head, args...) = new(head, collect(args))
end

# Convenience constructors
Resource(uri::String) = ResourceURI(uri)
Resource(prefix::String, name::String) = ResourceCURIE(prefix, name)

# Patterns
##########

abstract type Pattern <: Expression end

const VariableBinding = Pair{<:Node,Variable}
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
  constraint::Node
end

# Query
#######

abstract type Query <: Statement end

@auto_hash_equals struct Select <: Query
  variables::Vector{<:VariableOrBinding}
  clauses::Vector{<:Clause}
  distinct::Bool
  reduced::Bool
  
  function Select(vars::Vector{<:VariableOrBinding}, args...;
                  distinct::Bool=false, reduced::Bool=false)
    new(vars, collect(args), distinct, reduced)
  end
end

@auto_hash_equals struct Construct <: Query
  construct::Vector{Triple}
  clauses::Vector{<:Clause}
  
  Construct(cons::Vector{Triple}, args...) = new(cons, collect(args))
end

@auto_hash_equals struct Ask <: Query
  clauses::Vector{<:Clause}
  
  Ask(args...) = new(collect(args))
end

@auto_hash_equals struct Describe <: Query
  nodes::Vector{<:Node}
  clauses::Vector{<:Clause}
  
  Describe(nodes::Vector{<:Node}, args...) = new(nodes, collect(args))
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

@auto_hash_equals struct Where <: Clause
  patterns::Vector{<:Pattern}
end
Where() = Where(Pattern[])

@auto_hash_equals struct OrderBy <: SolutionModifierClause
  nodes::Vector{<:Node}
end
OrderBy(node::Node) = OrderBy([node])

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
  constraint::Node
end

end
