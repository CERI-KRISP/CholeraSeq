#!/usr/bin/env python

import sys
import csv
import os.path
import argparse
from Bio import Seq, SeqIO

SPIKE = [21563, 25384]
SPIKELEN = 3821

def index_pathname(filename):
    return filename + ".fx"

def parse_args():
    parser = argparse.ArgumentParser(description="Filter sequences in the input FASTA file on the basis of minimum length, and maximum N frequency.")
    parser.add_argument("infile", help="Input FASTA file")
    parser.add_argument("outfile", nargs="?", default="/dev/stdout", help="Output FASTA file (default: /dev/stdout)")
    parser.add_argument("-l", type=int, default=0, help="Only output sequences with length greater than or equal to L")
    parser.add_argument("-f", type=float, default=0, help="Only output sequences with a fraction of valid bases larger than F (range: 0-100)")
    parser.add_argument("-b", help="Write 'bad' sequences to file B")
    parser.add_argument("-r", help="Write report to file R")
    parser.add_argument("-n", type=int, help="Remove all stretches of Ns longer than N bases")
    parser.add_argument("-w", help="Only output sequences whose name is listed in file W")
    parser.add_argument("-p", help="Output sequences that contain string P anywhere in the header")
    parser.add_argument("-x", help="Output sequences that do NOT contain string X in the header")
    parser.add_argument("-P", help="Like -p, but reads strings to match from file P")
    parser.add_argument("-s", type=int, help="Start processing input file at file position S")
    parser.add_argument("-S", type=int, help="Start processing input file at sequence number S (1-based, requires index created with -i)")
    parser.add_argument("-m", type=int, help="Process at most M sequences")
    parser.add_argument("-i", action="store_true", help="Create an index of the output file. All other options are ignored")
    parser.add_argument("-g", action="store_true", help="Remove all gaps from sequences")
    parser.add_argument("-d", action="store_true", help="Only output sequences with a valid date in the header (assumes GISAID format)")
    parser.add_argument("-u", action="store_true", help="Remove duplicate sequences (base on seq name, only keeps first)")

    return parser.parse_args()

def write_bad(seq_record, badstream):
    if badstream:
        SeqIO.write(seq_record, badstream, "fasta")

def read_wanted(wantedfile):
    wanted = set()
    if wantedfile:
        with open(wantedfile, "r") as f:
            c = csv.reader(f, delimiter='\t')
            for row in c:
                if row and row[0][0] != '#':
                    wanted.add(row[0])
        sys.stderr.write("{} wanted sequences.\n".format(len(wanted)))
    return wanted

def find_start_sequence(infile, startseq):
    idxfile = index_pathname(infile)
    if not os.path.isfile(idxfile):
        sys.stderr.write("Error: -S option specified, but index file `{}' is not present - create it with -i.\n".format(idxfile))
        sys.exit(1)

    n = 0
    with open(idxfile, "rt") as f:
        for line in f:
            n += 1
            if n == startseq:
                pos = int(line.rstrip("\n").split("\t")[1])
                sys.stderr.write("Starting at sequence #{}\n".format(startseq))
                return pos
    sys.stderr.write("Error: looking for sequence # {}, but index file only contains {} sequences.\n".format(startseq, n))
    sys.exit(1)

def clean(config):
    nin = nout = nshort = nmissing = 0
    seqdata = []
    seen = set()

    if config.badfile:
        config.badstream = open(config.badfile, "w")
    config.wanted = read_wanted(config.wantedfile)
    if config.startseq:
        config.filepos = find_start_sequence(config.infile, config.startseq)
    try:
        with open(config.outfile, "w") as out:
            with open(config.infile, "rt") as f:
                if config.infile != "/dev/stdin":
                    f.seek(config.filepos)
                for seq_record in SeqIO.parse(f, "fasta"):
                    nin += 1
                    header = seq_record.name
                    if config.remdup and header in seen:
                        continue
                    else:
                        seen.add(header)
                    if config.partialmatch:
                        if config.exclude:
                            good = True
                            for p in config.partialmatch:
                                if p in header:
                                    good = False
                                    break
                        else:
                            good = False
                            for p in config.partialmatch:
                                if p in header:
                                    good = True
                                    break
                        if not good:
                            continue
                    header_fields = header.split("|")
                    if len(header_fields) > 2:
                        name = header_fields[1]
                        if config.wanted and name not in config.wanted:
                            continue
                        date = header_fields[2]
                        if config.musthavedate and date == '':
                            continue
                    seq = str(seq_record.seq).upper()
                    if config.remgaps:
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

                    if sl < config.min_length:
                        nshort += 1
                        write_bad(seq_record, config.badstream)
                    elif nf < config.n_frac:
                        nmissing += 1
                        write_bad(seq_record, config.badstream)
                    else:
                        if config.n_stretch:
                            remove_nstretch(seq_record, config.n_stretch)
                        SeqIO.write(seq_record, out, "fasta")
                        nout += 1
                        status = "OK"
                    seqdata.append([seq_record.name, sl, "{:.1f}".format(nf), "{:.1f}".format(sf), status])
                    if nin == config.maxseqs:
                        sys.stderr.write("Limit of {} sequences reached, terminating.\n".format(config.maxseqs))
                        break
    finally:
        if config.badstream:
            config.badstream.close()

    if config.reportfile:
        with open(config.reportfile, "w") as rep:
            rep.write("#Input sequences:\t{}\n".format(nin))
            rep.write("#Too short:\t{}\n".format(nshort))
            rep.write("#More than {}% Ns:\t{}\\n".format(int(100 * config.n_frac), nmissing))
            rep.write("#Good sequences:\t{}\n".format(nout))
            rep.write("#\n")
            rep.write("#Sequence\tLen\tNfrac\tSpike\tStatus\n")
            for row in seqdata:
                rep.write("{}\t{}\t{}\t{}\t{}\n".format(*row))
    sys.stderr.write("{} sequences read, {} written ({} filtered).\n".format(nin, nout, nin-nout))

def remove_nstretch(seq_record, n_stretch):
    cleanbases = []
    instretch = False
    lenstretch = 0
    for b in seq_record.seq:
        if instretch:
            if b == "N":
                lenstretch += 1
            else:
                if lenstretch <= n_stretch:
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

def write_index(infile):
    indexfile = index_pathname(infile)
    sys.stderr.write("Writing index for `{}' to `{}'...\n".format(infile, indexfile))
    nseqs = 0
    with open(infile, "rt") as f, open(indexfile, "w") as out:
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
    config = parse_args()
    if config.infile:
        if config.i:
            write_index(config.infile)
        else:
            clean(config)
    else:
        usage()
