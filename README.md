# PEGParser


PEGParser is a PEG Parser for Julia with Packrat capabilties. PEGParser was inspired by pyparsing, parsimonious, boost::spirit, as well as several others. I was originally writing the EBNF for an entirely different purpose, when it ocurred to me that it wouldn't be too difficult to write a parser. Thus, PEGParsing was born.

## Defining a grammar

To define a grammar you can write:

```julia
@grammar <name> begin
  rule1 = ...
  rule2 = ...
  ...
end
```

### Allowed rules

The following rules can be used:
* Terminals: Strings and characters
* Or: `a | b | c`
* And: `a + b + c`
* Grouping: `(a + b) | (c + d)`
* Optional: ?(a + b)
* One or more: `+((a + b) | (c + d))`
* Zero or more: `*((a + b) | (c + d))`
* Regular expressions: `r"[a-zA-Z]+"`

#### TODO
Multiple: `(a+b)^(3, 5)`

## Example 1
Suppose you want a parser that takes input and converts `[text]` into `<b>text<>`. You can write the following grammar:

```julia
@grammar markup begin
  # this is the standard start rule
  start = bold_text

  # compose a sequence
  bold_text = bold_open + text + bold_code

  # use a regular expression to define the text
  text = r"[a-zA-z]"

  bold_open = '['
  bold_close = ']'
end
```

The first step in using the grammar is to create an AST from a given input:

```julia
(ast, pos, error) = parse(markup, "[test]")
```

The variable `node` contains the AST which can be transformed to the desired result. To do so, first a mapping of the node names to transform has to established:

```julia
tohtml(node, cvalues, ::MatchRule{:bold_open}) = "<b>"
tohtml(node, cvalues, ::MatchRule{:bold_close}) = "</b>"
tohtml(node, cvalues, ::MatchRule{:text}) = node.value
tohtml(node, cvalues, ::MatchRule{:bold_text}) = join(children)

```

And finally:
```julia
result = transform(tohtml, ast)
println(result) # "<b>test</b>"
```

## Example 2
Transforms can also be used to calculate a value from the tree. Consider the standard calculator app:

```julia
@grammar calc begin
  start = expr
  number = r"([0-9]+)"
  expr = (term + op1 + expr) | term
  term = (factor + op2 + term) | factor
  factor = number | pfactor
  pfactor = lparen + expr + rparen
  op1 = '+' | '-'
  op2 = '*' | '/'
  lparen = "("
  rparen = ")"
end
```

And to use the grammar:

```julia
(node, pos, error) = parse(grammar, "5*(42+3+6+10+2)")

evaluate(node, cvalues, ::MatchRule{::number}) = float(node.value)
evaluate(node, cvalues, ::MatchRule{::expr}) = 
  length(children) == 1 ? children : eval(Expr(:call, cvalues[2], cvalues[1], cvalues[3]))
evaluate(node, cvalues, ::MatchRule{::factor}) = cvalues
evaluate(node, cvalues, ::MatchRule{::pfactor}) = cvalues
evaluate(node, cvalues, ::MatchRule{::term}) = 
  length(children) == 1 ? children : eval(Expr(:call, cvalues[2], cvalues[1], cvalues[3]))
evaluate(node, cvalues, ::MatchRule{::op1}) = symbol(node.value)
evaluate(node, cvalues, ::MatchRule{::op2}) = symbol(node.value)

result = transform(math, node, ignore=[:lparen, :rparen])

println(result) # 315.0
```

## Caveats

This code is not very well tested yet and isn't yet finished, so use at your own risk (I wrote this while on vacation). It is, without any question, a work in progress.

While I have not benchmarked any of this, the hope is that it should be relatively fast. The grammar itself is created using macros. The parsing has very little overhead and additionally has caching. That said, without any benchmarking, this is just conjecture.

Additionally, little to now error checking is performed. The macros probably need some serious review. And while there are a bunch of unit tests, they fall very short from full coverage.
