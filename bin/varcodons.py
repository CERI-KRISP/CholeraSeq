#!/usr/bin/env python


# Original author: Alberto

import sys
import csv
import numpy as np
from collections import defaultdict
from Bio import SeqIO

BASE_IDX = {'A': 1, 'C': 2, 'G': 3, 'T': 4, 'N': 0, '-': 0}
BASE_CMP = {'A': 'T', 'T': 'A', 'C': 'G', 'G': 'C'}

def revcomp(triplet):
    a = BASE_CMP[triplet[0]] if triplet[0] in BASE_CMP else triplet[0]
    b = BASE_CMP[triplet[1]] if triplet[1] in BASE_CMP else triplet[1]
    c = BASE_CMP[triplet[2]] if triplet[2] in BASE_CMP else triplet[2]
    return c + b + a

def getAnnot(s, key):
    for p in s.split(";"):
        if p.startswith(key):
            return p[len(key):]
    return "???"

class Outfile(object):
    filename = None
    stream = None

    def __init__(self, filename, fasta=None):
        self.filename = filename
        self.stream = None

    def __enter__(self):
        if self.filename:
            self.stream = open(self.filename, "w")
            return self.stream
        else:
            return sys.stdout

    def __exit__(self, exc_type, exc_val, exc_tb):
        if self.stream:
            self.stream.close()

class GeneSet(object):
    genes = None
    chromLengths = []

    def __init__(self):
        self.genes = defaultdict(dict)
        self.chromLengths = []

    def add(self, gene, geneid):
        self.genes[gene.chrom][geneid] = gene

    def parseGenes(self, gff):
        with open(gff, "r") as f:
            line1 = f.readline()
        if line1.startswith("LOCUS"):
            self.parseGB(gff)
        else:
            self.parseGFF(gff)

    def parseGFF(self, gff):
        gene = None
        ngenes = 0
        ncds = 0
        with open(gff, "r") as f:
            c = csv.reader(f, delimiter='\t')
            for row in c:
                if len(row) == 0 or row[0][0] == '#':
                    continue
                chrom = row[0]
                key = row[2]
                if key == "gene" or key == "pseudogene":
                    name = getAnnot(row[8], "Name=")
                    geneid = getAnnot(row[8], "ID=")
                    gene = Gene(chrom, name, row[6])
                    self.add(gene, geneid)
                    ngenes += 1
                elif key == "CDS":
                    parent = getAnnot(row[8], "Parent=")
                    if parent in self.genes[chrom]:
                        gene = self.genes[chrom][parent]
                        cds = CDS(int(row[3]), int(row[4]))
                        gene.addCDS(cds)
                        ncds += 1
        self.setCDS()
        sys.stderr.write("{} genes, {} CDSs\n".format(ngenes, ncds))

    def getChromLengths(self, gbfile):
        """Return a dictionary containing the length of each LOCUS from a Genbank file."""
        lengths = {}
        with open(gbfile, "r") as f:
            for line in f:
                if line.startswith("LOCUS"):
                    line = line.split()
                    lengths[line[1]] = int(line[2])
                    self.chromLengths.append((line[1], int(line[2])))
        return lengths

    def findChromAtPosition(self, pos):
        for ch in self.chromLengths:
            if pos <= ch[1]:
                return ch[0]
            else:
                pos = pos - ch[1]

    def parseGB(self, gbfile):
        ngenes = 0
        ncds = 0
        offset = 0

        lengths = self.getChromLengths(gbfile)

        f = SeqIO.parse(gbfile, "genbank")
        for rec in f:
            chrom = rec.name
            sys.stderr.write("Chrom = {}, offset = {}\n".format(chrom, offset))
            for ft in rec.features:
                if ft.type == 'CDS':
                    geneid = ft.qualifiers['locus_tag'][0]
                    if 'gene' in ft.qualifiers:
                        gene_name = ft.qualifiers['gene'][0]
                    else:
                        gene_name = geneid
                    strand = "+" if ft.strand == 1 else "-"
                    gene = Gene(chrom, gene_name, strand)
                    self.add(gene, geneid)
                    ngenes += 1
                    locType = ft.location.__class__.__name__
                    if locType == "FeatureLocation":
                        cds = CDS(ft.location.start + offset, ft.location.end + offset)
                        gene.addCDS(cds)
                        ncds += 1
                    else:
                        for fl in ft.location.parts:
                            cds = CDS(fl.start + offset, fl.end + offset)
                            gene.addCDS(cds)
                            ncds += 1
            offset += lengths[chrom]

        self.setCDS()
        sys.stderr.write("{} genes, {} CDSs\n".format(ngenes, ncds))
        for chrom in self.genes:
            sys.stderr.write("  {}:  {} genes\n".format(chrom, len(self.genes[chrom])))

    def setCDS(self):
        for chrom in self.genes:
            for gene in self.genes[chrom].values():
                gene.setFrames()

    def dump(self):
        for chrom in self.genes:
            sys.stdout.write("{}\n".format(chrom))
            for gene in self.genes[chrom].values():
                if len(gene.codingseqs) > 0:
                    sys.stdout.write("  {} {}\n".format(gene.name, gene.strand))
                    for cds in gene.codingseqs:
                        sys.stdout.write("    {} ({})\t{} ({})\t{}\t{}\n".format(cds.start, cds.frame1, cds.end, \
                            cds.frame2, 1 + cds.end - cds.start, cds.offset))
                    sys.stdout.write("\n")

    def findCDSatpos(self, chrom, pos):
        result = []
        #print(self.genes[chrom][:10])
        for gene in self.genes[chrom].values():
            #print((gene.name, gene.codingseqs))
            for cds in gene.codingseqs:
                #print((cds.start, pos, cds.end))
                if cds.start <= pos <= cds.end:
                    result.append(cds)
        return result

class Gene(object):
    chrom = ""
    name = ""
    strand = ""
    codingseqs = []

    def __init__(self, chrom, name, strand):
        self.chrom = chrom
        self.name = name
        self.strand = strand
        self.codingseqs = []

    def addCDS(self, cds):
        self.codingseqs.append(cds)
        cds.gene = self

    def setFrames(self):
        fr = 0
        offset = 0
        if self.strand == "+":
            for cds in self.codingseqs:
                cds.frame1 = fr
                fr = fr + (cds.end - cds.start) % 3
                cds.frame2 = fr
                fr = (fr + 1) % 3
                cds.offset = offset
                offset += 1 + cds.end - cds.start
        else:
            for cds in self.codingseqs:
                cds.frame2 = fr
                fr = fr + (cds.end - cds.start) % 3
                cds.frame1 = fr
                fr = (fr + 1) % 3
                cds.offset = offset
                offset += 1 + cds.end - cds.start

class CDS(object):
    start = 0
    end = 0
    strand = ""
    frame1 = 0
    frame2 = 0
    gene = None
    offset = 0

    def __init__(self, start, end):
        #sys.stderr.write("** from gb: {} {}\n".format(start, end))
        self.start = start + 1
        self.end = end

    def tripletStart(self, pos):
        """Return the start position of a triplet in this cds given its coordinate."""
        if self.gene.strand == "+":
            fr = self.frame1 + (pos - self.start) % 3
            return pos - fr
        else:
            fr = self.frame2 + (self.end - pos) % 3
            return pos + fr - 2

fakeCDS = CDS(-1,-1)
fakeCDS.gene = Gene('', '', '')


class SNP(object):
    chrom = ""
    pos = 0
    cds = None
    tripletn = 0

    def __init__(self, chrom, pos, cds):
        self.chrom = chrom
        self.pos = pos
        self.cds = cds

    def tripletn(self, cds):
        pSt = int(((cds.offset + self.pos - cds.start) / 3)+1)
        if cds.gene.strand == "+":
            cSt = pSt
        else:
            cSt = int(((cds.end + cds.offset - self.pos) / 3)+1)
        return {'pStrand':pSt, 'cdsStrand':cSt}



class Reference(object):
    chrom = ""
    genelist = None
    bases = []
    nbases = 0                  # length of sequences
    baseArray = None            # array of base counts
    snpPositions = []           # polymorphic positions
    snps = []

    def __init__(self, genelist):
        #self.chrom = chrom
        self.genelist = genelist
        self.bases = []
        self.snpPositions = []
        self.snps = []

    def readReference(self, f):
        """Read a reference sequence from stream `f' and store it in the `bases' attribute as a list of bases."""
        f.readline()            # skip header
        self.nbases = 0
        for line in f:
            if line[0] == '>':
                break
            for ch in line:
                ch = ch.upper()
                if ch in BASE_IDX:
                    self.bases.append(ch)
                    self.nbases += 1
        sys.stderr.write("{} bases in alignment\n1 sequence".format(self.nbases))
        self.baseArray = np.zeros((self.nbases, 5), dtype=np.int16)
        bp = 0
        for b in self.bases:
            self.baseArray[bp, BASE_IDX[b]] = 1
            bp += 1

    def readAlignment(self, filename):
        nseq = 1
        nsnp = 0
        pos = 0

        with open(filename, "r") as f:
            self.readReference(f)
            nseq += 1
            while True:
                line = f.readline()
                if not line:
                    break
                if line[0] == '>':
                    pos = 0
                    nseq += 1
                    sys.stderr.write("\r{} sequences".format(nseq))
                    continue
                for ch in line:
                    ch = ch.upper()
                    try:
                        if ch in BASE_IDX:
                            self.baseArray[pos, BASE_IDX[ch]] += 1
                            pos += 1
                        elif ch == "\n":
                            pass
                        else:
                            sys.stderr.write("[{}]".format(ch))
                    except IndexError:
                        sys.stderr.write("pos={}, ch={}, line={}\n".format(pos, ch, line))
                        sys.stderr.write(BASE_IDX[ch])

        sys.stderr.write("\r{} sequences read.\nIdentifying variable positions.\n".format(nseq))
        # self.writeMatrix("matrix.txt")
        for pos in range(self.nbases):
            nonz = 0
            for i in range(1, 5):
                if self.baseArray[pos, i] > 0:
                    nonz += 1
            if nonz > 1:
                self.snpPositions.append(pos+1)
                nsnp += 1
                sys.stderr.write("\r{} variable positions found".format(nsnp))
        sys.stderr.write("\r{} variable positions found.\n".format(nsnp))

    def writeMatrix(self, filename):
        with open(filename, "w") as out:
            for i in range(self.nbases):
                out.write(str(i) + "\t")
                for j in range(5):
                    out.write(str(self.baseArray[i, j]) + "\t")
                out.write("\n")

    def filterInformative(self, minall, mincov):
        fp = []
        sys.stderr.write(f"Scanning {len(self.snpPositions)} positions to determine PI SNPs.\n")
        for pos in self.snpPositions:
            ngood = 0
            totbase = 0
            total = 0
            for i in range(5):
                c = self.baseArray[pos-1, i]
                #sys.stderr.write(f"{c} ")
                total += c
                if i > 0:
                    totbase += c
                    if c >= minall:
                        ngood += 1
            #sys.stderr.write(f"\n{pos}: {ngood} {totbase} {total}\n")
            if (ngood > 1) and ((totbase / total) > mincov):
                fp.append(pos)
        self.snpPositions = fp
        sys.stderr.write("{} informative positions found.\n".format(len(fp)))

    def makeSNPs(self, codons):
        for pos in self.snpPositions:
            chrom = self.genelist.findChromAtPosition(pos)
            cds = self.genelist.findCDSatpos(chrom, pos)
            if cds:
                S = SNP(chrom, pos, cds)
                self.snps.append(S)
            elif codons is False:
                S = SNP(chrom, pos, [fakeCDS])
                self.snps.append(S)
        if codons:
            sys.stderr.write("{} SNPs in CDSs found.\n".format(len(self.snps)))

    def SNPsToFasta(self, filename, out):
        hdr = ""
        bases = []
        with open(filename, "r") as f:
            for line in f:
                if line[0] == '>':
                    if bases:
                        self.seqToSNPs(hdr, bases, out)
                    hdr = line
                    bases = []
                else:
                    for ch in line:
                        if ch in "ATGCN-":
                            bases.append(ch)
        self.seqToSNPs(hdr, bases, out)

    def seqToSNPs(self, hdr, bases, out):
        out.write(hdr)
        for snp in self.snps:
            b = bases[snp.pos-1]
            out.write(b)
        out.write("\n")

    def SNPsToTriplets(self, filename, out):
        hdr = ""
        bases = []
        with open(filename, "r") as f:
            for line in f:
                if line[0] == '>':
                    if bases:
                        self.seqToTriplets(hdr, bases, out)
                    hdr = line
                    bases = []
                else:
                    for ch in line:
                        if ch in "ATGCN-":
                            bases.append(ch)
        self.seqToTriplets(hdr, bases, out)



    def seqToTriplets(self, hdr, bases, out):
        out.write(hdr)
        for snp in self.snps:
            for cds in snp.cds:
                tstart = cds.tripletStart(snp.pos)
                triplet = bases[(tstart-1):tstart+2]
                if cds.gene.strand == "-":
                    triplet = revcomp(triplet)
                out.write("".join(triplet))
        out.write("\n")

    def writeSNPs(self, filename):
        with open(filename, "w") as out:
            out.write("Chrom\tPosition\tGene\tCodingStrand\tTripletInPlusStrand\tTripletInCodingStrand\n")
            for snp in self.snps:
                for cds in snp.cds:
                    indTrplt = snp.tripletn(cds)
                    if cds.gene.name:
                        out.write("\t".join([snp.chrom, str(snp.pos), cds.gene.name, cds.gene.strand, \
                            str(indTrplt['pStrand']), str(indTrplt['cdsStrand'])]) + "\n")
                    else:
                        out.write("\t".join([snp.chrom, str(snp.pos), 'N/A', 'N/A', 'N/A', 'N/A']) + "\n")

class Main(object):
    gff = None
    chrom = None
    fasta = None
    reportfile = None
    outfile = None
    informative = False         # Filter for informative SNPs
    minCov = 0
    minAll = 0
    codons = False

    def usage(self):
        sys.stdout.write("""varcodons.py - Convert alignment to triplets at variable sites.

Usage: varcodons.py [options...]

where options are:

  -g G | GFF or GenBank file containing gene annotations (required).
  -f F | Alignment in FASTA format (required).
  -c C | Chromosome name.
  -o O | Name of output file (default: standard output).
  -r R | Name of report file containing list of variable positions (default: no report).
  -i   | If specified, filter informative SNPs only. A SNP is considered informative
         if it meets the conditions specified by -d and -n. Default: {}.
  -d D | Fraction of bases at variable position that are not `N' or `-'. Default: {}.
  -n N | Both alleles should be seen at least N times. Default: {}.
  -a   | If specified, outputs codons instead of SNPs.

""".format(self.informative, self.minCov, self.minAll))

    def parseArgs(self, args):
        import argparse
        parser = argparse.ArgumentParser(
            description="varcodons.py - Convert alignment to triplets at variable sites.",
            formatter_class=argparse.RawTextHelpFormatter
        )
        parser.add_argument('-g', '--gff', dest='gff', required=True, help='GFF or GenBank file containing gene annotations (required).')
        parser.add_argument('-f', '--fasta', dest='fasta', required=True, help='Alignment in FASTA format (required).')
        parser.add_argument('-c', '--chrom', dest='chrom', help='Chromosome name.')
        parser.add_argument('-o', '--outfile', dest='outfile', help='Name of output file (default: standard output).')
        parser.add_argument('-r', '--reportfile', dest='reportfile', help='Name of report file containing list of variable positions (default: no report).')
        parser.add_argument('-i', '--informative', dest='informative', action='store_true', help='Filter informative SNPs only.')
        parser.add_argument('-d', '--minCov', dest='minCov', type=float, default=0, help="Fraction of bases at variable position that are not 'N' or '-'.")
        parser.add_argument('-n', '--minAll', dest='minAll', type=int, default=0, help='Both alleles should be seen at least N times.')
        parser.add_argument('-a', '--codons', dest='codons', action='store_true', help='Outputs codons instead of SNPs.')

        parsed = parser.parse_args(args)

        self.gff = parsed.gff
        self.fasta = parsed.fasta
        self.chrom = parsed.chrom
        self.outfile = parsed.outfile
        self.reportfile = parsed.reportfile
        self.informative = parsed.informative
        self.minCov = parsed.minCov
        self.minAll = parsed.minAll
        self.codons = parsed.codons

        # If -i is specified, override minCov and minAll as in original logic
        if self.informative:
            if self.minCov == 0:
                self.minCov = 0.7
            if self.minAll == 0:
                self.minAll = 2

        return self.gff and self.fasta

    def run(self):
        GS = GeneSet()
        GS.parseGenes(self.gff)
        #GS.dump()
        R = Reference(GS)
        R.readAlignment(self.fasta)
        if self.informative:
            R.filterInformative(self.minAll, self.minCov)
        R.makeSNPs(self.codons)
        if self.reportfile:
            R.writeSNPs(self.reportfile)
        with Outfile(self.outfile, self.fasta) as out:
            if self.codons:
                R.SNPsToTriplets(self.fasta, out)
            else:
                R.SNPsToFasta(self.fasta, out)


def main(args):
    M = Main()
    if M.parseArgs(args):
        M.run()
    else:
        M.usage()

if __name__ == "__main__":
    main(sys.argv[1:])
