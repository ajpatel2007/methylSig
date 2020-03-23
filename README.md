# methylSig

<!-- badges: start -->
[![Travis build status](https://travis-ci.org/sartorlab/methylSig.svg?branch=master)](https://travis-ci.org/sartorlab/methylSig)
[![Coveralls test coverage](https://coveralls.io/repos/github/sartorlab/methylSig/badge.svg)](https://coveralls.io/r/sartorlab/methylSig?branch=master)
<!-- badges: end -->

# Introduction

DNA methylation plays critical roles in gene regulation and cellular specification without altering DNA sequences. It is one of the best understood and most intensively studied epigenetic marks in mammalian cells. Treatment of DNA with sodium bisulfite deaminates unmethylated cytosines to uracil while methylated cytosines are resistant to this conversion thus allowing for the discrimination between methylated and unmethylated CpG sites. Sodium bisulfite pre-treatment of DNA coupled with next-generation sequencing has allowed DNA methylation to be studied quantitatively and genome-wide at single cytosine site resolution.

`methylSig` is a method for testing for differential methylated cytosines (DMCs) or regions (DMRs) in whole-genome bisulfite sequencing (WGBS) or reduced representation bisulfite sequencing (RRBS) experiments. `methylSig` uses a beta-binomial model to test for significant differences between groups of samples. Several options exist for either site-specific or sliding window tests, combining strands, and for variance estimation.

# Installation

`methylSig` is available on GitHub at <http://www.github.com/sartorlab/methylSig>, and the easiest way to install it is as follows:

```{r install, eval=FALSE}
devtools::install_github('sartorlab/methylSig')
```

# Usage

The basic flow of analysis with `methylSig` is to:

* Read data
* Optionally filter data by coverage and/or location
* Optionally aggregate data into regions
* Optionally filter data by coverage in a minimum number of samples per group
* Test for differential methylation

The sections below walk through each step with small test data.

## Reading Data

Methylation calls output by either [MethylDackel](https://github.com/dpryan79/MethylDackel#single-cytosine-methylation-metrics-extraction) or [Bismark](https://github.com/FelixKrueger/Bismark/tree/master/Docs#the-coverage-output-looks-like-this-tab-delimited-1-based-genomic-coords) can be read by the `bsseq::read.bismark()` function from the [`bsseq`](https://www.bioconductor.org/packages/release/bioc/html/bsseq.html) R/Bioconductor package.

This function accepts `bedGraph`s from [MethylDackel](https://github.com/dpryan79/MethylDackel#single-cytosine-methylation-metrics-extraction) and either the coverage or genome-wide cytosine reports from [Bismark](https://github.com/FelixKrueger/Bismark/tree/master/Docs#the-coverage-output-looks-like-this-tab-delimited-1-based-genomic-coords). Options to consider when reading data are:

* `colData`, a `data.frame` or `DataFrame` whose rows are samples and columns are phenotype data. The row ordering should match the ordering of files in `files`. This matrix will be needed for downstream differential methylation testing.
* `strandCollapse`, a `logical` (`TRUE`/`FALSE`) indicating whether or not to collapse +/- CpG data onto the + strand. Note, this can only be `TRUE` when the input type is the genome-wide cytosine report from Bismark. MethylDackel has an option to destrand data when methylation calls are made so that the output is already destranded. In this case, `strandCollapse` should be `FALSE`.

For all options, see the `bsseq` [reference manual](https://www.bioconductor.org/packages/release/bioc/manuals/bsseq/man/bsseq.pdf), and the [section on reading data](https://www.bioconductor.org/packages/release/bioc/vignettes/bsseq/inst/doc/bsseq.html#4_reading_data) in the package vignette.

```{r read}
files = c(
    system.file('extdata', 'bis_cov1.cov', package='methylSig'),
    system.file('extdata', 'bis_cov2.cov', package='methylSig')
)

bsseq_stranded = bsseq::read.bismark(
    files = files,
    colData = data.frame(row.names = c('test1','test2')),
    rmZeroCov = FALSE,
    strandCollapse = FALSE
)
```

The result is a `BSseq` object. Aspects of the object can be accessed via:

```{r bsseq_access}
# pData
bsseq::pData(bsseq_stranded)

# GRanges
GenomicRanges::granges(bsseq_stranded)

# Coverage matrix
bsseq::getCoverage(bsseq_stranded, type = 'Cov')

# Methylation matrix
bsseq::getCoverage(bsseq_stranded, type = 'M')
```

## Filtering Data

After data is loaded, it is good practice to filter loci that have too few or too many reads, and C-to-T and G-to-A SNPs which confound bisulfite conversion.

### By Coverage

Low coverage loci (typically those with fewer than 5 reads) should be marked because they adversely affect the variance calculation in downstream differential methylation tests. Very high coverage loci (typically those with more than 500 reads) are likely the result of PCR duplication, and should also be marked.

`MethylSig` marks such sites by setting their coverage and methylation matrix entries to 0 for each sample in which this happens. Prior to testing, these sites can be removed, see below.

```{r filter_by_coverage}
# Load data for use in the rest of the vignette
data(BS.cancer.ex, package = 'bsseqData')
bs = BS.cancer.ex[1:10000]

bs = filter_loci_by_coverage(bs, min_count = 5, max_count = 500)
```

### By Location

As noted above, locations with C-to-T and G-to-A SNPs confound bisulfite conversion in WGBS and ERRBS. Filtering them out can be accomplished by constructing a `GRanges` object with their location. For now, we leave locating such SNPs to the user.

```{r filter_by_location}
# Show locations of bs
GenomicRanges::granges(bs)

# Construct GRanges object
remove_gr = GenomicRanges::GRanges(
    seqnames = c('chr21', 'chr21', 'chr21'),
    ranges = IRanges::IRanges(
        start = c(9411552, 9411784, 9412099),
        end = c(9411552, 9411784, 9412099)
    )
)

bs = filter_loci_by_location(bs = bs, gr = remove_gr)

# Show removal
GenomicRanges::granges(bs)
```

## Aggregating Data

One way to increase the power of differential methylation testing is to aggregate the CpG-level data into regions. Regions can take two forms: tiling the entire genome by windows of a certain width or defining a set of regions such as CpG islands or gene promoters.

### By Tiling the Genome

Given that CpG methylation is strongly correlated over short genomic distances, a reasonable upper threshold might be 500bp. For the example below, in the interest of speed, we tile by larger windows.

```{r tile_by_windows}
windowed_bs = tile_by_windows(bs = bs, win_size = 10000)

# Show tiling
GenomicRanges::granges(windowed_bs)
```

### By Pre-defined Regions

It may be the case that differential methylation is only relevant at promoter regions of genes for a particular project. In this case, aggregation of methylation calls over these regions may increase power, and decrease computation time.

```{r tile_by_regions}
# Collapsed promoters on chr21 and chr22
data(promoters_gr, package = 'methylSig')

promoters_bs = tile_by_regions(bs = bs, gr = promoters_gr)
```

## Testing for Differential Methylation

`MethylSig` offers three tests for differential methylation:

1. `diff_binomial()`
2. `diff_methylsig()`
3. `diff_dss_fit()` and `diff_dss_test()`

Each returns a `GRanges` object with tested loci and the corresponding statistics and methylation levels (if applicable). See the documentation for each function for more information (`?diff_binomial`, `?diff_methylsig`, `?diff_dss_fit`, and `?diff_dss_test`).

### Filtering by Coverage in a Minimum Number of Samples

Prior to applying any test function, loci without a minimum number of samples having appropriate coverage should be removed to avoid testing loci where one sample dominates the test.

```{r filter_by_group_coverage}
# Look a the phenotype data for bs
bsseq::pData(bs)

# Require at least two samples from cancer and two samples from normal
bs = filter_loci_by_group_coverage(
    bs = bs,
    group_column = 'Type',
    c('cancer' = 2, 'normal' = 2))
```

### Binomial Test

`diff_binomial()` is a binomial test based on that in the [`methylKit`](https://bioconductor.org/packages/release/bioc/html/methylKit.html) R/Bioconductor package. This was included for benchmarking purposes in the publication. It does not take into account the variability among samples being compared.

```{r diff_binomial}
# Test cancer versus normal
diff_gr = diff_binomial(
    bs = bs,
    group_column = 'Type',
    comparison_groups = c('case' = 'cancer', 'control' = 'normal'))

diff_gr
```

### MethylSig Test

The `diff_methylsig()` is a beta-binomial test which takes into account the variability among samples being compared. It can perform group versus group comparisons with no covariates.

```{r diff_methylsig}
# Test cancer versus normal with dispersion from both groups
diff_gr = diff_methylsig(
    bs = bs,
    group_column = 'Type',
    comparison_groups = c('case' = 'cancer', 'control' = 'normal'),
    disp_groups = c('case' = TRUE, 'control' = TRUE),
    local_window_size = 0,
    t_approx = TRUE,
    n_cores = 1)

diff_gr
```

### General Models with DSS

`diff_dss_fit()` and `diff_dss_test()` are tests supporting general models, and are wrappers for functions in the [`DSS`](https://bioconductor.org/packages/release/bioc/html/DSS.html) R/Bioconductor package. We have added the ability to recover group methylation for group comparisons, or top/bottom 25 percentile methylation rates based on a continuous covariate.

The `DSS` style test is in two stages similar to tests in the `edgeR` or `limma` R/Bioconductor packages. The first stage is a fit, and the second stage is a test on a contrast.

First we add a numerical covariate to the `pData(bs)` so that we can give an example of such a test.

```{r add_numerical_covariate}
bsseq::pData(bs)$num_covariate = c(84, 96, 93, 10, 18, 9)
```

#### Model Fitting

Fit the simplest group versus group model on just the type.

```{r diff_dss_fit_simple}
diff_fit_simple = diff_dss_fit(
    bs = bs,
    design = bsseq::pData(bs),
    formula = as.formula('~ Type'))
```

Fit a paired model where cancer and normal samples are paired by patient.

```{r diff_dss_fit_paired}
# Paired-test
diff_fit_paired = diff_dss_fit(
    bs = bs,
    design = bsseq::pData(bs),
    formula = '~ Type + Pair')
```

Fit a model on the numerical covariate.

```{r diff_dss_fit_num}
# Numerical covariate test
diff_fit_num = diff_dss_fit(
    bs = bs,
    design = bsseq::pData(bs),
    formula = '~ num_covariate')
```

The result of `diff_dss_fit()` is a `list` with the following structure with elements:

* `gr`, the `GRanges` of the fit loci.
* `design`, the phenotype matrix passed via the `design` parameter.
* `formula`, the formula used in conjunction with `design` to create the model matrix.
* `X`, the result of `model.matrix` with `design` and `formula`.
* `fit`, the `beta` and `var.beta` matrices.

#### Building Contrasts

Prior to calling `diff_fit_test()`, it may help to look at the model matrix used for fitting in order to build the contrast.

```{r diff_dss_fit_model}
diff_fit_simple$X

diff_fit_paired$X

diff_fit_num$X
```

The contrast passed to `diff_fit_test()` should be a column vector or a matrix whose rows correspond to the columns of the model matrix above. See the [DSS user guide](http://bioconductor.org/packages/release/bioc/vignettes/DSS/inst/doc/DSS.html#34_dmldmr_detection_from_general_experimental_design) for more information.

```{r contrast}
# Test the simplest model for cancer vs normal
# Note, 2 rows corresponds to 2 columns in diff_fit_simple$X
simple_contrast = matrix(c(0,1), ncol = 1)

# Test the paired model for cancer vs normal
# Note, 4 rows corresponds to 4 columns in diff_fit_paired$X
paired_contrast = matrix(c(0,1,0,0), ncol = 1)

# Test the numerical covariate
num_contrast = matrix(c(0,1), ncol = 1)
```

#### Testing

The `diff_fit_test()` function enables the recovery of group methylation rates via the optional `methylation_group_column` and `methylation_groups` parameters.

The simple, group versus group, test.

```{r diff_dss_test_simple}
diff_simple_gr = diff_dss_test(
    bs = bs,
    diff_fit = diff_fit_simple,
    contrast = simple_contrast,
    methylation_group_column = 'Type',
    methylation_groups = c('case' = 'cancer', 'control' = 'normal'))

diff_simple_gr
```

The paired test.

```{r diff_dss_test_paired}
diff_paired_gr = diff_dss_test(
    bs = bs,
    diff_fit = diff_fit_paired,
    contrast = paired_contrast,
    methylation_group_column = 'Type',
    methylation_groups = c('case' = 'cancer', 'control' = 'normal'))

diff_paired_gr
```

The numerical covariate test. Note, here the `methylation_groups` parameter is omitted because there are no groups. By giving the numerical covariate column, we will group samples by the top/bottom 25 percentile over the covariate, and compute mean methylation within those groups of samples.

```{r diff_dss_test_num}
diff_num_gr = diff_dss_test(
    bs = bs,
    diff_fit = diff_fit_num,
    contrast = num_contrast,
    methylation_group_column = 'num_covariate')

diff_num_gr
```
