devtools::install_github("gtonkinhill/fastbaps")

library(fastbaps)
library(ape)



###Upload Afasta alignment
myAln<- import_fasta_sparse_nt(
  '/blue/salemi/share/cholera2022clinical_analyses/snippy_20221111/snippy_ww/gubbins/ww.clean.nepalRef.fasta')
myAln<- optimise_prior(myAln, type = 'optimise.symmetric')
#"Optimised hyperparameter: 0.008"
baps.hc<- fast_baps(myAln)
myClusters<- best_baps_partition(myAln, as.phylo(baps.hc))
myClustersDF<- data.frame(
  seqNames = names(myClusters), CLusterNo = myClusters,
  stringsAsFactors = FALSE)
#
#save clusters table to file if you like
write.table(x = myClustersDF,
            file = '/blue/salemi/share/cholera2022clinical_analyses/snippy_20221111/snippy_ww/gubbins/ww.clusters.tsv',
            sep = '\t', row.names = FALSE, quote = FALSE)
#
#
#Now, split by cluster.
#
library(Biostrings)
#
#Load the fasta file as dnastringset with biostrings
#
WwAln<- readDNAStringSet(
  filepath = '/blue/salemi/share/cholera2022clinical_analyses/snippy_20221111/snippy_ww/gubbins/ww.clean.nepalRef.fasta')
length(WwAln) #2141
class(myClustersDF$CLusterNo) #numeric
unique(myClustersDF$CLusterNo) #3 2 1. Cool.
#
#
##Now split the fasta files in subsets to be fed to gubbins
for(i in 1:max(myClustersDF$CLusterNo)) {
  indFa<- WwAln[names(WwAln) %in% myClustersDF[myClustersDF$CLusterNo==i, "seqNames"]]
  writeXStringSet(
    x = indFa,
    filepath = paste(
      '/blue/salemi/share/cholera2022clinical_analyses/snippy_20221111/snippy_ww/gubbins/',
      'ww.cluster.', i, '.fasta', sep = ''))
}
rm(i)



