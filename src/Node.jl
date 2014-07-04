immutable Node
  name::String
  value::String
  first::Int64
  last::Int64
  children::Array{Node}
  ruleType::Type
  sym::Any

  function Node(name::String, value::String, first::Int64, last::Int64, children::Array, ruleType::Type)
    if length(name) == 0
      sym = nothing
    else
      sym = symbol(name)
    end

    return new(name, value, first, last, children, ruleType, sym)
  end
end

function Node(name::String, value::String, first::Int64, last::Int64, typ)
  return Node(name, value, first, last, [], typ)
end

function show(io::IO, node::Node, indent)
  println(io, "node($(node.name)) {$(node.value), $(node.ruleType)}")
  for (i, child) in enumerate(node.children)
    print(io, "  "^indent)
    print(io, "$i: ")
    show(io, child, indent+1)
  end
end

function show(io::IO, node::Node)
    show(io, node, 0)
end