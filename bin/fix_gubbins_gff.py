#!/usr/bin/env python3
"""Make a Gubbins recombination GFF safe for mask_gubbins_aln.py.

A record is kept as-is only if it passes the SAME test the masking script applies:
at least 9 tab-separated columns, integer start/end (columns 4/5), and
taxa="..." (with both quotes) in column 9. Otherwise:
  - if it is a branch to a single sample in the alignment (node="X->SAMPLE"),
    taxa="SAMPLE" is restored and the record kept;
  - else it is dropped with a warning (line number + the raw line).
'##' header lines are kept. Gubbins has been seen writing records truncated after
node="Node_7->SRR2815085.fasta"; and blank lines - both crash the masking script."""
import re, sys
gff_in, gff_out, aln = sys.argv[1:4]
taxa_re = re.compile(r'taxa="([^"]*)"')          # identical to mask_gubbins_aln.py
node_re = re.compile(r'node="[^"]*->([^"]+)"')
taxa = {l[1:].split()[0] for l in open(aln) if l.startswith('>')}

def usable(cols):
    if len(cols) < 9: return False
    try: int(cols[3]); int(cols[4])
    except ValueError: return False
    return taxa_re.search(cols[8]) is not None

kept = repaired = dropped = 0
with open(gff_out, 'w') as out:
    for n, line in enumerate(open(gff_in), 1):
        if line.startswith('##'):
            out.write(line); continue
        cols = line.rstrip('\n').split('\t')
        if usable(cols):
            out.write(line); kept += 1; continue
        m = node_re.search(cols[8]) if len(cols) >= 9 else None
        ints_ok = len(cols) >= 9 and cols[3].strip().isdigit() and cols[4].strip().isdigit()
        if m and ints_ok and m.group(1) in taxa:
            cols[8] = taxa_re.sub('', cols[8]).rstrip(';') + ';taxa="' + m.group(1) + '";'
            out.write('\t'.join(cols) + '\n'); repaired += 1
            sys.stderr.write(f"WARNING: line {n}: repaired record without usable taxa= (branch to {m.group(1)}), {cols[3]}-{cols[4]}\n")
        else:
            dropped += 1
            sys.stderr.write(f"WARNING: line {n}: dropped unusable record: {line.rstrip(chr(10))[:300]!r}\n")
sys.stderr.write(f"fix_gubbins_gff: {kept} kept, {repaired} repaired, {dropped} dropped\n")
