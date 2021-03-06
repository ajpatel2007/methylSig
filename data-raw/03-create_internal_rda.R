library(bsseq)
library(DelayedArray)
library(GenomicRanges)

################################################################################

# Use for tile_by_regions() tests
# Use for filter_loci_by_location() tests
#----[---------]---------[--------------]----[---------]--------------[---------]
gr_tiles1 = GRanges(
    seqnames = c('chr1','chr1','chr1','chr1'),
    ranges = IRanges(
        start = c(5,25,45,70),
        end = c(15,40,55,80)
    )
)

# Use for tiling tests
#----[------------------------]----[----------------------------------]----[----]
gr_tiles2 = GRanges(
    seqnames = c('chr1','chr1','chr1'),
    ranges = IRanges(
        start = c(5,35,75),
        end = c(30,70,80)
    )
)

# Use for tiling tests
# Use for filter_loci_by_location() tests (expect an error from removing all)
#----[--------------------------------------------------------------------------]
gr_tiles3 = GRanges(
    seqnames = c('chr1'),
    ranges = IRanges(
        start = c(5),
        end = c(80)
    )
)

# Use for tiling tests
# Use for filter_loci_by_location() tests
#----[--------------]------------------------------------------------------------
gr_tiles4 = GRanges(
    seqnames = c('chr1'),
    ranges = IRanges(
        start = c(5),
        end = c(20)
    )
)

# Use for tiling tests
# Use for filter_loci_by_location() tests (expect nothing filtered)
#----[---]-----------------------------------------------------------------------
gr_tiles5 = GRanges(
    seqnames = c('chr1'),
    ranges = IRanges(
        start = c(5),
        end = c(9)
    )
)

#[-----------------------][-----------------------][-----------------------][-----------------------][]
seqlengths = c('chr1' = 101)
win25_stranded_gr = GenomicRanges::tileGenome(
    seqlengths = seqlengths,
    tilewidth = 25,
    cut.last.tile.in.chrom = TRUE)

#[-----------------------][-----------------------][-----------------------][-----------------------]
seqlengths = c('chr1' = 100)
win25_destranded_gr = GenomicRanges::tileGenome(
    seqlengths = seqlengths,
    tilewidth = 25,
    cut.last.tile.in.chrom = TRUE)

#[-----------------------][-----------------------][---]
#[-----------------------][---]
seqlengths = c('chr1' = 55, 'chr2' = 35)
win25_multichrom_gr = GenomicRanges::tileGenome(
    seqlengths = seqlengths,
    tilewidth = 25,
    cut.last.tile.in.chrom = TRUE)

################################################################################
# gr_tiles1
################################################################################

#----[---------]---------[--------------]----[---------]--------------[---------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 coverage
#         5              30             10        0         40             1000
#          5              70             20        0                        1500
# test2 coverage
#         10             50             15        5         20             100
#          10             50             35        5                        200
#----[---------]---------[--------------]----[---------]--------------[---------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles1) coverage
#        10                     110             0                         2500
#        20                     115             10                        300

stranded_cov1 = DelayedArray::DelayedArray(matrix(c(
    10,110,0,2500,
    20,115,10,300
), ncol = 2))

#----[---------]---------[--------------]----[---------]--------------[---------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 coverage
#         5              30             10        0         40             1000
#          5              70             20        0                        1500
# test2 coverage
#         10             50             15        5         20             100
#          10             50             35        5                        200
#----[---------]---------[--------------]----[---------]--------------[---------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# filter_loci_by_location(bs = bsseq_stranded, gr = gr_tiles1) coverage
#                                        20                 40
#                                        35                 20

filter_cov1 = DelayedArray::DelayedArray(matrix(c(
    20,40,
    35,20
), ncol = 2))

#----[---------]---------[--------------]----[---------]--------------[---------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 methylation
#         4              0              9         0         35             900
#          4              5              19        0                        1400
# test2 methylation
#         9              1              14        5         15             99
#          9              5              34        5                        199
#----[---------]---------[--------------]----[---------]--------------[---------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles1) methylation
#        8                     14               0                         2300
#        18                    20               10                        298

stranded_meth1 = DelayedArray::DelayedArray(matrix(c(
    8,14,0,2300,
    18,20,10,298
), ncol = 2))

#----[---------]---------[--------------]----[---------]--------------[---------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 methylation
#         4              0              9         0         35             900
#          4              5              19        0                        1400
# test2 methylation
#         9              1              14        5         15             99
#          9              5              34        5                        199
#----[---------]---------[--------------]----[---------]--------------[---------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# filter_loci_by_location(bs = bsseq_stranded, gr = gr_tiles1) methylation
#                                        19                 35
#                                        34                 15

filter_meth1 = DelayedArray::DelayedArray(matrix(c(
    19,35,
    34,15
), ncol = 2))

bsseq_stranded_tiled1 = BSseq(
    gr = gr_tiles1,
    Cov = stranded_cov1,
    M = stranded_meth1,
    pData = data.frame(row.names = c('test1','test2')),
    sampleNames = c('test1','test2')
)

filter_loc_tiles1 = BSseq(
    gr = granges(bsseq_stranded[c(6,9)]),
    Cov = filter_cov1,
    M = filter_meth1,
    pData = data.frame(row.names = c('test1','test2')),
    sampleNames = c('test1','test2')
)

########################################

#----[---------]---------[--------------]----[---------]--------------[---------]
#---------C--------------C--------------C---------C---------C--------------C-
# test1 coverage
#         10             100            30        0         40             2500
# test2 coverage
#         20             100            50        10        20             300
#----[---------]---------[--------------]----[---------]--------------[---------]
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles1) coverage
#        10                     130             0                         2500
#        20                     150             10                        300

destranded_cov1 = DelayedArray::DelayedArray(matrix(c(
    10,130,0,2500,
    20,150,10,300
), ncol = 2))

#----[---------]---------[--------------]----[---------]--------------[---------]
#---------C--------------C--------------C---------C---------C--------------C-
# test1 methylation
#         8              5              28        0         35             2300
# test2 methylation
#         18             6              48        10        15             298
#----[---------]---------[--------------]----[---------]--------------[---------]
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles1) methylation
#        8                     14               0                         2300
#        18                    54               10                        298

destranded_meth1 = DelayedArray::DelayedArray(matrix(c(
    8,33,0,2300,
    18,54,10,298
), ncol = 2))

bsseq_destranded_tiled1 = BSseq(
    gr = gr_tiles1,
    Cov = destranded_cov1,
    M = destranded_meth1,
    pData = data.frame(row.names = c('test3','test4')),
    sampleNames = c('test3','test4')
)

################################################################################
# gr_tiles2
################################################################################

#----[------------------------]----[----------------------------------]----[----]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 coverage
#         5              30             10        0         40             1000
#          5              70             20        0                        1500
# test2 coverage
#         10             50             15        5         20             100
#          10             50             35        5                        200
#----[------------------------]----[----------------------------------]----[----]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles2) coverage
#                  110                              70                      2500
#                  120                              80                      300

stranded_cov2 = DelayedArray::DelayedArray(matrix(c(
    110,70,2500,
    120,80,300
), ncol = 2))

#----[------------------------]----[----------------------------------]----[----]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 methylation
#         4              0              9         0         35             900
#          4              5              19        0                        1400
# test2 methylation
#         9              1              14        5         15             99
#          9              5              34        5                        199
#----[------------------------]----[----------------------------------]----[----]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles2) methylation
#                  13                              63                       2300
#                  24                              73                       298

stranded_meth2 = DelayedArray::DelayedArray(matrix(c(
    13,63,2300,
    24,73,298
), ncol = 2))

bsseq_stranded_tiled2 = BSseq(
    gr = gr_tiles2,
    Cov = stranded_cov2,
    M = stranded_meth2,
    pData = data.frame(row.names = c('test1','test2')),
    sampleNames = c('test1','test2')
)

########################################

#----[------------------------]----[----------------------------------]----[----]
#---------C--------------C--------------C---------C---------C--------------C-
# test1 coverage
#         10             100            30        0         40             2500
# test2 coverage
#         20             100            50        10        20             300
#----[------------------------]----[----------------------------------]----[----]
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles2) coverage
#                  110                              70                      2500
#                  120                              80                      300

destranded_cov2 = DelayedArray::DelayedArray(matrix(c(
    110,70,2500,
    120,80,300
), ncol = 2))

#----[------------------------]----[----------------------------------]----[----]
#---------C--------------C--------------C---------C---------C--------------C-
# test1 methylation
#         8              5              28        0         35             2300
# test2 methylation
#         18             6              48        10        15             298
#----[------------------------]----[----------------------------------]----[----]
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles2) methylation
#                  13                              63                       2300
#                  24                              73                       298

destranded_meth2 = DelayedArray::DelayedArray(matrix(c(
    13,63,2300,
    24,73,298
), ncol = 2))

bsseq_destranded_tiled2 = BSseq(
    gr = gr_tiles2,
    Cov = destranded_cov2,
    M = destranded_meth2,
    pData = data.frame(row.names = c('test3','test4')),
    sampleNames = c('test3','test4')
)

################################################################################
# gr_tiles3
################################################################################

#----[--------------------------------------------------------------------------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 coverage
#         5              30             10        0         40             1000
#          5              70             20        0                        1500
# test2 coverage
#         10             50             15        5         20             100
#          10             50             35        5                        200
#----[--------------------------------------------------------------------------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles3) coverage
#                                       2680
#                                       500
stranded_cov3 = DelayedArray::DelayedArray(matrix(c(
    2680,
    500
), ncol = 2))

#----[--------------------------------------------------------------------------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 methylation
#         4              0              9         0         35             900
#          4              5              19        0                        1400
# test2 methylation
#         9              1              14        5         15             99
#          9              5              34        5                        199
#----[--------------------------------------------------------------------------]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles3) methylation
#                                       2376
#                                       395

stranded_meth3 = DelayedArray::DelayedArray(matrix(c(
    2376,
    395
), ncol = 2))

bsseq_stranded_tiled3 = BSseq(
    gr = gr_tiles3,
    Cov = stranded_cov3,
    M = stranded_meth3,
    pData = data.frame(row.names = c('test1','test2')),
    sampleNames = c('test1','test2')
)

########################################

#----[------------------------]----[----------------------------------]----[----]
#---------C--------------C--------------C---------C---------C--------------C-
# test1 coverage
#         10             100            30        0         40             2500
# test2 coverage
#         20             100            50        10        20             300
#----[------------------------]----[----------------------------------]----[----]
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles3) coverage
#                                       2680
#                                       500

destranded_cov3 = DelayedArray::DelayedArray(matrix(c(
    2680,
    500
), ncol = 2))

#----[------------------------]----[----------------------------------]----[----]
#---------C--------------C--------------C---------C---------C--------------C-
# test1 methylation
#         8              5              28        0         35             2300
# test2 methylation
#         18             6              48        10        15             298
#----[------------------------]----[----------------------------------]----[----]
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles3) methylation
#                                       2376
#                                       395

destranded_meth3 = DelayedArray::DelayedArray(matrix(c(
    2376,
    395
), ncol = 2))

bsseq_destranded_tiled3 = BSseq(
    gr = gr_tiles3,
    Cov = destranded_cov3,
    M = destranded_meth3,
    pData = data.frame(row.names = c('test3','test4')),
    sampleNames = c('test3','test4')
)

################################################################################
# gr_tiles4
################################################################################

#----[--------------]------------------------------------------------------------
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 coverage
#         5              30             10        0         40             1000
#          5              70             20        0                        1500
# test2 coverage
#         10             50             15        5         20             100
#          10             50             35        5                        200
#----[--------------]------------------------------------------------------------
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles4) coverage
#         10
#         20
stranded_cov4 = DelayedArray::DelayedArray(matrix(c(
    10,
    20
), ncol = 2))

filter_cov4 = DelayedArray::DelayedArray(matrix(c(
    30,70,10,20,0,0,40,1000,1500,
    50,50,15,35,5,5,20,100,200
), ncol = 2))

#----[--------------]------------------------------------------------------------
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 methylation
#         4              0              9         0         35             900
#          4              5              19        0                        1400
# test2 methylation
#         9              1              14        5         15             99
#          9              5              34        5                        199
#----[--------------]------------------------------------------------------------
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles4) methylation
#         8
#         18

stranded_meth4 = DelayedArray::DelayedArray(matrix(c(
    8,
    18
), ncol = 2))

filter_meth4 = DelayedArray::DelayedArray(matrix(c(
    0,5,9,19,0,0,35,900,1400,
    1,5,14,34,5,5,15,99,199
), ncol = 2))

bsseq_stranded_tiled4 = BSseq(
    gr = gr_tiles4,
    Cov = stranded_cov4,
    M = stranded_meth4,
    pData = data.frame(row.names = c('test1','test2')),
    sampleNames = c('test1','test2')
)

filter_loc_tiles4 = BSseq(
    gr = granges(bsseq_stranded[-c(1,2)]),
    Cov = filter_cov4,
    M = filter_meth4,
    pData = data.frame(row.names = c('test1','test2')),
    sampleNames = c('test1','test2')
)

########################################

#----[--------------]------------------------------------------------------------
#---------C--------------C--------------C---------C---------C--------------C-
# test1 coverage
#         10             100            30        0         40             2500
# test2 coverage
#         20             100            50        10        20             300
#----[--------------]------------------------------------------------------------
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles4) coverage
#         10
#         20

destranded_cov4 = DelayedArray::DelayedArray(matrix(c(
    10,
    20
), ncol = 2))

#----[--------------]------------------------------------------------------------
#---------C--------------C--------------C---------C---------C--------------C-
# test1 methylation
#         8              5              28        0         35             2300
# test2 methylation
#         18             6              48        10        15             298
#----[--------------]------------------------------------------------------------
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles4) methylation
#         8
#         18

destranded_meth4 = DelayedArray::DelayedArray(matrix(c(
    8,
    18
), ncol = 2))

bsseq_destranded_tiled4 = BSseq(
    gr = gr_tiles4,
    Cov = destranded_cov4,
    M = destranded_meth4,
    pData = data.frame(row.names = c('test3','test4')),
    sampleNames = c('test3','test4')
)

################################################################################
# gr_tiles5
################################################################################

#----[---]-----------------------------------------------------------------------
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 coverage
#         5              30             10        0         40             1000
#          5              70             20        0                        1500
# test2 coverage
#         10             50             15        5         20             100
#          10             50             35        5                        200
#----[---]-----------------------------------------------------------------------
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles5) coverage
#      0
#      0
stranded_cov5 = DelayedArray::DelayedArray(matrix(c(
    0,
    0
), ncol = 2))

#----[---]-----------------------------------------------------------------------
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 methylation
#         4              0              9         0         35             900
#          4              5              19        0                        1400
# test2 methylation
#         9              1              14        5         15             99
#          9              5              34        5                        199
#----[---]-----------------------------------------------------------------------
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_regions(bs = bsseq_stranded, gr = gr_tiles5) methylation
#      0
#      0

stranded_meth5 = DelayedArray::DelayedArray(matrix(c(
    0,
    0
), ncol = 2))

bsseq_stranded_tiled5 = BSseq(
    gr = gr_tiles5,
    Cov = stranded_cov5,
    M = stranded_meth5,
    pData = data.frame(row.names = c('test1','test2')),
    sampleNames = c('test1','test2')
)

########################################

#----[---]-----------------------------------------------------------------------
#---------C--------------C--------------C---------C---------C--------------C-
# test1 coverage
#         10             100            30        0         40             2500
# test2 coverage
#         20             100            50        10        20             300
#----[---]-----------------------------------------------------------------------
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles5) coverage
#      0
#      0

destranded_cov5 = DelayedArray::DelayedArray(matrix(c(
    0,
    0
), ncol = 2))

#----[---]-----------------------------------------------------------------------
#---------C--------------C--------------C---------C---------C--------------C-
# test1 methylation
#         8              5              28        0         35             2300
# test2 methylation
#         18             6              48        10        15             298
#----[---]-----------------------------------------------------------------------
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_regions(bs = bsseq_destranded, gr = gr_tiles5) methylation
#      0
#      0

destranded_meth5 = DelayedArray::DelayedArray(matrix(c(
    0,
    0
), ncol = 2))

bsseq_destranded_tiled5 = BSseq(
    gr = gr_tiles5,
    Cov = destranded_cov5,
    M = destranded_meth5,
    pData = data.frame(row.names = c('test3','test4')),
    sampleNames = c('test3','test4')
)

filter_loc_tiles5 = bsseq_stranded

################################################################################
# win25_gr
################################################################################

#[-----------------------][-----------------------][-----------------------][-----------------------][]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 coverage
#         5              30             10        0         40             1000
#          5              70             20        0                        1500
# test2 coverage
#         10             50             15        5         20             100
#          10             50             35        5                        200
#[-----------------------][-----------------------][-----------------------][-----------------------][]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_windows(bs = bsseq_stranded, win_size = 25) coverage
#           40                     100                      1040                       1500           0
#           70                     105                      125                        200            0

stranded_cov25 = DelayedArray::DelayedArray(matrix(c(
    40,100,1040,1500,0,
    70,105,125,200,0
), ncol = 2))

#[-----------------------][-----------------------][-----------------------][-----------------------][]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# test1 methylation
#         4              0              9         0         35             900
#          4              5              19        0                        1400
# test2 methylation
#         9              1              14        5         15             99
#          9              5              34        5                        199
#[-----------------------][-----------------------][-----------------------][-----------------------][]
#---------CG-------------CG-------------CG--------CG--------C--------------CG
# tile_by_windows(bs = bsseq_stranded, win_size = 25) methylation
#           8                       33                       935                        1400          0
#           19                      58                       119                        199           0

stranded_meth25 = DelayedArray::DelayedArray(matrix(c(
    8,33,935,1400,0,
    19,58,119,199,0
), ncol = 2))

bsseq_stranded_win25 = BSseq(
    gr = win25_stranded_gr,
    Cov = stranded_cov25,
    M = stranded_meth25,
    pData = data.frame(row.names = c('test1','test2')),
    sampleNames = c('test1','test2')
)

########################################

#[-----------------------][-----------------------][-----------------------][-----------------------]
#---------C--------------C--------------C---------C---------C--------------C-
# test1 coverage
#         10             100            30        0         40             2500
# test2 coverage
#         20             100            50        10        20             300
#[-----------------------][-----------------------][-----------------------][-----------------------]
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_windows(bs = bsseq_destranded, win_size = 25) coverage
#           110                     30                      2540                        0
#           120                     60                      320                         0

destranded_cov25 = DelayedArray::DelayedArray(matrix(c(
    110,30,2540,0,
    120,60,320,0
), ncol = 2))

#[-----------------------][-----------------------][-----------------------][-----------------------]
#---------C--------------C--------------C---------C---------C--------------C-
# test1 methylation
#         8              5              28        0         35             2300
# test2 methylation
#         18             6              48        10        15             298
#[-----------------------][-----------------------][-----------------------][-----------------------]
#---------C--------------C--------------C---------C---------C--------------C-
# tile_by_windows(bs = bsseq_destranded, win_size = 25) methylation
#           13                     28                      2335                         0
#           24                     58                      313                          0

destranded_meth25 = DelayedArray::DelayedArray(matrix(c(
    13,28,2335,0,
    24,58,313,0
), ncol = 2))

bsseq_destranded_win25 = BSseq(
    gr = win25_destranded_gr,
    Cov = destranded_cov25,
    M = destranded_meth25,
    pData = data.frame(row.names = c('test3','test4')),
    sampleNames = c('test3','test4')
)

################################################################################
# win25_multichrom_gr
################################################################################

#[-----------------------][-----------------------][---]
#---------C---------C---------C
# test1 coverage / methylation
#          10        20        30
# test2 coverage / methylation
#          40        50        60
#[-----------------------][-----------------------][---]
#---------C---------C---------C

#[-----------------------][---]
#---------C
# test1 coverage / methylation
#          90
# test2 coverage / methylation
#          100
#[-----------------------][---]
#---------C

multichrom_cov25 = DelayedArray::DelayedArray(matrix(c(
    30,30,0,90,0,
    90,60,0,100,0
), ncol = 2))

multichrom_meth25 = multichrom_cov25

bsseq_multichrom_win25 = BSseq(
    gr = win25_multichrom_gr,
    Cov = multichrom_cov25,
    M = multichrom_meth25,
    pData = data.frame(row.names = c('test1','test2')),
    sampleNames = c('test1','test2')
)

################################################################################

usethis::use_data(
    gr_tiles1,
    gr_tiles2,
    gr_tiles3,
    gr_tiles4,
    gr_tiles5,
    win25_stranded_gr,
    win25_destranded_gr,
    win25_multichrom_gr,
    bsseq_stranded_tiled1,
    bsseq_destranded_tiled1,
    filter_loc_tiles1,
    bsseq_stranded_tiled2,
    bsseq_destranded_tiled2,
    bsseq_stranded_tiled3,
    bsseq_destranded_tiled3,
    bsseq_stranded_tiled4,
    bsseq_destranded_tiled4,
    filter_loc_tiles4,
    bsseq_stranded_tiled5,
    bsseq_destranded_tiled5,
    filter_loc_tiles5,
    bsseq_stranded_win25,
    bsseq_destranded_win25,
    bsseq_multichrom_win25,
    internal = TRUE,
    overwrite = TRUE)
