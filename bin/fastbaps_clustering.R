library(fastbaps)
library(ape)

#NOTE: We could potentially optimize this using seqkit
library(Biostrings)

args = commandArgs(trailingOnly=TRUE)
refFile  = args[0] # '/blue/salemi/share/cholera2022clinical_analyses/snippy_20221111/snippy_ww/gubbins/ww.clean.nepalRef.fasta'
clusterFile  = args[1] # '/blue/salemi/share/cholera2022clinical_analyses/snippy_20221111/snippy_ww/gubbins/ww.clusters.tsv'


###Upload Afasta alignment
myAln<- import_fasta_sparse_nt(refFile)
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
            file = clusterFile,
            sep = '\t', row.names = FALSE, quote = FALSE)


#Now, split by cluster.
#
#Load the fasta file as dnastringset with biostrings

WwAln<- readDNAStringSet(
  filepath = refFile)

#NOTE: Track this information in the log file
#length(WwAln) #2141
#class(myClustersDF$CLusterNo) #numeric
#unique(myClustersDF$CLusterNo) #3 2 1. Cool.

#
##Now split the fasta files in subsets to be fed to gubbins
for(i in 1:max(myClustersDF$CLusterNo)) {
  indFa<- WwAln[names(WwAln) %in% myClustersDF[myClustersDF$CLusterNo==i, "seqNames"]]
  writeXStringSet(
    x = indFa,
    filepath = paste('ww.cluster.', i, '.fasta', sep = ''))
}

#rm(i)



