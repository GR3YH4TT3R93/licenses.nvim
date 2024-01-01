syn clear gitcommitSummary
syn match gitcommitSummary "^.*\%<79v." contained containedin=gitcommitFirstLine nextgroup=gitcommitOverflow contains=@Spell
