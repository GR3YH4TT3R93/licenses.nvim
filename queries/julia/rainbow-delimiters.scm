(vector_expression
  "[" @delimiter
  "]" @delimiter @sentinel) @container

(matrix_expression
  "[" @delimiter
  "]" @delimiter @sentinel) @container

(parameter_list
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(argument_list
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(parenthesized_expression
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(comprehension_expression
  "[" @delimiter
  "]" @delimiter @sentinel) @container
