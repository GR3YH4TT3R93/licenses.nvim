(subquery
    "(" @delimiter
    ")" @delimiter @sentinel) @container

(invocation
    "(" @delimiter
    ")" @delimiter @sentinel) @container

(list
    "(" @delimiter
    ")" @delimiter @sentinel) @container

(where
  "(" @delimiter
  ")" @delimiter @sentinel) @container

(binary_expression
  "(" @delimiter
  ")" @delimiter @sentinel
  ) @container

; The following can cause problems with (((())))
(term
  "(" @delimiter
  ; ("(" ")")* ; to fix _some_ problems, this can be uncommented
  ")" @delimiter @sentinel
  ) @container

