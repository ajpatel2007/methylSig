data(BS.cancer.ex, package = 'bsseqData')

bs = filter_loci_by_group_coverage(
    bs = BS.cancer.ex,
    group_column = 'Type',
    c('cancer' = 2, 'normal' = 2))

small_test = bs[1:50]

#####################################

test_that('bs missing check', {
    expect_error(
        diff_dss_fit(),
        'Must pass bs as a BSseq object',
        fixed = TRUE
    )
})

test_that('formula missing check', {
    expect_error(
        diff_dss_fit(bs = small_test),
        'Must pass formula',
        fixed = TRUE
    )
})

#####################################

test_that('bs type check', {
    expect_error(
        diff_dss_fit(
            bs = 'blue',
            design = pData(small_test),
            formula = '~ Type'),
        'bs must be',
        fixed = TRUE
    )
})

test_that('design type check', {
    expect_error(
        diff_dss_fit(
            bs = small_test,
            design = 'hello',
            formula = '~ Type'),
        'design must be',
        fixed = TRUE
    )
})

test_that('formula type check', {
    expect_error(
        diff_dss_fit(
            bs = small_test,
            design = pData(small_test),
            formula = 100),
        'formula must be',
        fixed = TRUE
    )
})

#####################################

test_that('design message check', {
    expect_message(
        diff_dss_fit(
            bs = small_test,
            formula = '~ Type'),
        'Missing design',
        fixed = TRUE
    )
})

#####################################

test_that('Valid return character formula check', {
    diff_fit = diff_dss_fit(
        bs = small_test,
        design = pData(bs),
        formula = '~ Type')

    expect_true(is(diff_fit, 'list'))
    expect_true(all(c('gr', 'design', 'formula', 'X', 'fit') %in% names(diff_fit)))
})

test_that('Valid return formula formula check', {
    diff_fit = diff_dss_fit(
        bs = small_test,
        design = pData(bs),
        formula = as.formula('~ Type'))

    expect_true(is(diff_fit, 'list'))
    expect_true(all(c('gr', 'design', 'formula', 'X', 'fit') %in% names(diff_fit)))
})

test_that('Valid return more complex model check', {
    diff_fit = diff_dss_fit(
        bs = small_test,
        design = pData(bs),
        formula = as.formula('~ Type + Pair'))

    expect_true(is(diff_fit, 'list'))
    expect_true(all(c('gr', 'design', 'formula', 'X', 'fit') %in% names(diff_fit)))
})
