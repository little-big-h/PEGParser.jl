import Base.show
import Base.convert
import Base.getindex

abstract Rule

type Grammar
  rules::Dict{Symbol, Rule}
end

type EmptyRule <: Rule
end

type ParserData
  # map of parsers to use
  parsers

  # built up list of actions to resolve
  # resolution_list
end

function parseDefinition(name::String, sym::Symbol, pdata::ParserData)
  fn = get(pdata.parsers, sym, nothing)

  if fn !== nothing
    return fn(name, pdata, nothing)
  end

  # if not found, just return the symbol
  return sym
end

function parseDefinition(name::String, expr::Expr, pdata::ParserData)
  # if it's a macro (e.g. r"regex", then we want to expand it first)
  if expr.head === :macrocall
    return parseDefinition(name, eval(expr), pdata)
  end

  if expr.head === :curly
    rule = parseDefinition(name, expr.args[1], pdata)
    rule.action = expr.args[2]
    return rule
  end

  fn = get(pdata.parsers, expr.args[1], nothing)

  if fn !== nothing
    return fn(name, pdata, expr.args[2:end])
  end

  return (EmptyRule(), nothing)
end

# general case, just return value
expand_names(value) = value

# if it's a symbol, check that it matches, and if so, convert it
function expand_names(sym::Symbol)
  m = match(r"_(\d+)", string(sym))
  if m !== nothing
    i = parseint(m.captures[1])

    if i == 0
      return :(value)
    else
      return :(children[$i])
    end
  end
  return sym
end

# if it's an expression, recursively go through tree and
# transform all symbols that match '_i'
function expand_names(expr::Expr)
  new_args = [expand_names(arg) for arg in expr.args]
  return Expr(expr.head, new_args...)
end

function parseGrammar(grammar_name::Symbol, expr::Expr, pdata::ParserData)
  code = {}
  push!(code, :(rules = Dict()))

  for definition in expr.args[2:2:end]
    name = string(definition.args[1])
    ref_by_name = Expr(:ref, :rules, name)

    rule = parseDefinition(name, definition.args[2], pdata)
    action_type = typeof(rule.action)

    if action_type !== Function
      rule_action = expand_names(rule.action)
    else
      rule_action = rule.action
    end

    rcode = quote
      rules[$name] = $(esc(rule))

      if $(esc(action_type)) !== Function
        rules[$name].action = (rule, value, first, last, children) -> begin
          return $(rule_action)
        end
      end
    end

    push!(code, rcode)
  end

  push!(code, :($(esc(grammar_name)) = Grammar(rules)))
  return Expr(:block, code...)
end
