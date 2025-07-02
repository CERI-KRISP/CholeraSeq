#!/usr/bin/env python

# Original author: Alberto

import sys
import csv
import os.path
from Bio import Seq, SeqIO

SPIKE = [21563, 25384]
SPIKELEN = 3821

def index_pathname(filename):
    return filename + ".fx"

class Cleaner(object):
    infile = None
    outfile = "/dev/stdout"
    badfile = None
    badstream = None
    reportfile = None
    min_length = 0
    n_frac = 0
    n_stretch = None
    remgaps = False
    wantedfile = None
    wanted = None
    musthavedate = False
    partialmatch = []
    exclude = False             # If True, strings in partialmatch are excluded
    remdup = False
    filepos = 0
    maxseqs = 0                 # Maximum number of sequences to process
    startseq = None             # Number of first sequence to process
    doindex = False

    def parseArgs(self, args):
        if "-h" in args or "--help" in args:
            return False
        self.partialmatch = []
        prev = ""
        for a in args:
            if prev == "-l":
                self.min_length = int(a)
                prev = ""
            elif prev == "-f":
                self.n_frac = float(a)
                prev = ""
            elif prev == "-b":
                self.badfile = a
                prev = ""
            elif prev == "-r":
                self.reportfile = a
                prev = ""
            elif prev == "-n":
                self.n_stretch = int(a)
                prev = ""
            elif prev == "-w":
                self.wantedfile = a
                prev = ""
            elif prev == "-p":
                self.partialmatch = [a]
                prev = ""
            elif prev == "-x":
                self.partialmatch = [a]
                self.exclude = True
                prev = ""
            elif prev == "-P":
                with open(a, "r") as f:
                    for line in f:
                        self.partialmatch.append(line.strip())
                prev = ""
            elif prev == "-s":
                self.filepos = int(a)
                prev = ""
            elif prev == "-S":
                self.startseq = int(a)
                prev = ""
            elif prev == "-m":
                self.maxseqs = int(a)
                prev = ""
            elif a in ["-l", "-f", "-b", "-r", "-n", "-w", "-p", "-P", "-x", "-s", "-S", "-m"]:
                prev = a
            elif a == "-i":
                self.doindex = True
            elif a == "-g":
                self.remgaps = True
            elif a == "-d":
                self.musthavedate = True
            elif a == "-u":
                self.remdup = True
            elif self.infile is None:
                self.infile = a
                if self.infile == "-":
                    self.infile = "/dev/stdin"
            else:
                self.outfile = a
        return self.infile

    def usage(self):
        sys.stdout.write("""Usage: seq_cleaner.py [options] input.fasta [output.fasta]

Filter sequences in the input FASTA file on the basis of minimum length, and maximum N frequency.

The following options select which sequences to write to the output:

  -l L | Only output sequences with length greater then or equal to L.
  -f F | Only output sequences with a fraction of valid bases (ie, not N or -) larger than F (range: 0-100).
  -w W | Only output sequences whose name is listed in file W.
  -p P | Output sequences that contain string P anywhere in the header.
  -x X | Output sequences that do NOT contain string X in the header.
  -P P | Like -p, but reads strings to match from file P.
  -d   | Only output sequences with a valid date in the header (assumes GISAID format).
  -u   | Remove duplicate sequences (base on seq name, only keeps first).

Miscellaneous output options:

  -g   | Remove all gaps from sequences.
  -n N | Remove all stretches of Ns longer than N bases.
  -b B | Write "bad" sequences to file B.
  -r R | Write report to file R.

The following options are designed to process portions of the input file:

  -i   | Create an index of the output file. All other options are ignored.
  -s S | Start processing input file at file position S.
  -S S | Start processing input file at sequence number S (1-based, requires index created with -i).
  -m M | Process at most M sequences.

""")
        return False

    def writeBad(self, seq_record):
        if self.badstream:
            SeqIO.write(seq_record, self.badstream, "fasta")

    def readWanted(self):
        if self.wantedfile:
            self.wanted = set()
            with open(self.wantedfile, "r") as f:
                c = csv.reader(f, delimiter='\t')
                for row in c:
                    if row and row[0][0] != '#':
                        self.wanted.add(row[0])
            sys.stderr.write("{} wanted sequences.\n".format(len(self.wanted)))

    def find_start_sequence(self):
        idxfile = index_pathname(self.infile)
        if not os.path.isfile(idxfile):
            sys.stderr.write("Error: -S option specified, but index file `{}' is not present - create it with -i.\n".format(idxfile))
            sys.exit(1)

        n = 0
        with open(idxfile, "rt") as f:
            for line in f:
                n += 1
                if n == self.startseq:
                    pos = int(line.rstrip("\n").split("\t")[1])
                    self.filepos = pos
                    sys.stderr.write("Starting at sequence #{}\n".format(self.startseq))
                    return
        sys.stderr.write("Error: looking for sequence # {}, but index file only contains {} sequences.\n".format(self.startseq, n))
        sys.exit(1)

    def clean(self):
        nin = nout = nshort = nmissing = 0
        seqdata = []
        seen = set()

        if self.badfile:
            self.badstream = open(self.badfile, "w")
        self.readWanted()
        if self.startseq:
            self.find_start_sequence()
        try:
            with open(self.outfile, "w") as out:
                with open(self.infile, "rt") as f:
                    if self.infile != "/dev/stdin":
                        f.seek(self.filepos)
                    for seq_record in SeqIO.parse(f, "fasta"):
                        nin += 1
                        header = seq_record.name
                        if self.remdup and header in seen:
                            continue
                        else:
                            seen.add(header)
                        if self.partialmatch:
                            if self.exclude:
                                good = True
                                for p in self.partialmatch:
                                    if p in header:
                                        good = False
                                        break
                            else:
                                good = False
                                for p in self.partialmatch:
                                    if p in header:
                                        good = True
                                        break
                            if not good:
                                continue
                        header_fields = header.split("|")
                        if len(header_fields) > 2:
                            name = header_fields[1]
                            if self.wanted and name not in self.wanted:
                                continue
                            date = header_fields[2]
                            if self.musthavedate and date == '':
                                continue
                        seq = str(seq_record.seq).upper()
                        if self.remgaps:
                            seq = seq.replace("-", "")
                            seq_record.seq = Seq.Seq(seq)
                        sl = len(seq)
                        if sl == 0:
                            sys.stderr.write("Warning: sequence {} is empty.\n".format(seq_record.name))
                            continue
                        nc = seq.count("N") + seq.count("-")
                        nspike = seq[SPIKE[0]:SPIKE[1]].count("N") + seq[SPIKE[0]:SPIKE[1]].count("-")
                        nf = 100 - 100.0*nc/sl
                        sf = 100 - 100.0*nspike/SPIKELEN
                        status = "NO"

                        if sl < self.min_length:
                            nshort += 1
                            self.writeBad(seq_record)
                        elif nf < self.n_frac:
                            nmissing += 1
                            self.writeBad(seq_record)
                        else:
                            if self.n_stretch:
                                self.remove_nstretch(seq_record)
                            SeqIO.write(seq_record, out, "fasta")
                            nout += 1
                            status = "OK"
                        seqdata.append([seq_record.name, sl, "{:.1f}".format(nf), "{:.1f}".format(sf), status])
                        if nin == self.maxseqs:
                            sys.stderr.write("Limit of {} sequences reached, terminating.\n".format(self.maxseqs))
                            break
        finally:
            if self.badstream:
                self.badstream.close()

        if self.reportfile:
            with open(self.reportfile, "w") as rep:
                rep.write("#Input sequences:\t{}\n".format(nin))
                rep.write("#Too short:\t{}\n".format(nshort))
                rep.write("#More than {}% Ns:\t{}\n".format(int(100 * self.n_frac), nmissing))
                rep.write("#Good sequences:\t{}\n".format(nout))
                rep.write("#\n")
                rep.write("#Sequence\tLen\tNfrac\tSpike\tStatus\n")
                for row in seqdata:
                    rep.write("{}\t{}\t{}\t{}\t{}\n".format(*row))
        sys.stderr.write("{} sequences read, {} written ({} filtered).\n".format(nin, nout, nin-nout))

    def remove_nstretch(self, seq_record):
        cleanbases = []
        instretch = False
        lenstretch = 0
        for b in seq_record.seq:
            if instretch:
                if b == "N":
                    lenstretch += 1
                else:
                    if lenstretch <= self.n_stretch:
                        cleanbases.append("N"*lenstretch)
                    lenstretch = 0
                    instretch = False
            else:
                if b == "N":
                    instretch = True
                    lenstretch = 1
                else:
                    cleanbases.append(b)
        seq_record.seq = Seq.Seq("".join(cleanbases))

    def write_index(self):
        indexfile = index_pathname(self.infile)
        sys.stderr.write("Writing index for `{}' to `{}'...\n".format(self.infile, indexfile))
        nseqs = 0
        with open(self.infile, "rt") as f, open(indexfile, "w") as out:
            while True:
                p = f.tell()
                line = f.readline()
                if not line:
                    break
                if line[0] == '>':
                    out.write("{}\t{}\n".format(line[1:].rstrip("\n"), p))
                    nseqs += 1
        sys.stderr.write("Done, {} sequences indexed.\n".format(nseqs))

if __name__ == "__main__":
    args = sys.argv[1:]
    C = Cleaner()
    if C.parseArgs(args):
        if C.doindex:
            C.write_index()
        else:
            C.clean()
    else:
        C.usage()
