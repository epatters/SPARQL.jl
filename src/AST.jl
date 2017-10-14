module AST
export SPARQLNode, Statement, Node, Resource, ResourceURI, ResourceCURIE,
  Literal, Blank, Variable, Triple

using AutoHashEquals

""" Base type for all nodes in SPARQL AST.
"""
abstract type SPARQLNode end

""" Base type for statement in SPARQL grammar.
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

end
