command! -buffer GitTagSummary
    \ call append(line('.') - 1, 'Summary:') | r!git-tag-summary
