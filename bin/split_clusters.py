#!/usr/bin/env python3

import argparse
import csv
import sys
from pathlib import Path
from collections import defaultdict


def csv_data_to_dicts(csv_data_list):
    """Convert CSV data rows to dictionaries with cluster and id keys."""
    return [{'cluster': row[1], 'id': row[0]} for row in csv_data_list]


def read_csv_data(input_file):
    """Read CSV file and group data by cluster."""
    data = defaultdict(list)

    with open(input_file, 'r', newline='', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        # Skip header row
        next(reader, None)

        # Convert to list of dicts and group by cluster
        for row in reader:
            if len(row) >= 2:  # Ensure we have at least 2 columns
                cluster_data = {'cluster': row[1], 'id': row[0]}
                data[row[1]].append(cluster_data)

    return dict(data)


def create_cluster_str(vector_of_maps):
    """Create a string representation of cluster data."""
    return ''.join(f"{item['id']}\n" for item in vector_of_maps)


def write_cluster_txt(edn_data, cluster_id):
    """Write cluster data to a text file."""
    filename = f"cluster.{cluster_id}.csv"
    cluster_content = create_cluster_str(edn_data[cluster_id])

    with open(filename, 'w', encoding='utf-8') as f:
        f.write(cluster_content)


def separate_clusters(cluster_file):
    """Main function to separate clusters from input CSV file."""
    data = read_csv_data(cluster_file)
    cluster_ids = list(data.keys())

    for cluster_id in cluster_ids:
        write_cluster_txt(data, cluster_id)

    print(f"Created {len(cluster_ids)} cluster files from {cluster_file}")


def main():
    """Main CLI entry point."""
    parser = argparse.ArgumentParser(
        description="A utility script to separate the clusters identified by FASTBAPS"
    )

    subparsers = parser.add_subparsers(dest='command', help='Available commands')

    # CSV command with both short and long options
    csv_parser = subparsers.add_parser('csv', help='Process CSV file')
    csv_parser.add_argument('-c', '--cluster-file', required=True, help='Input CSV file')

    args = parser.parse_args()

    if args.command == 'csv':
        cluster_file = args.cluster_file
        if not Path(cluster_file).exists():
            print(f"Error: File {cluster_file} does not exist", file=sys.stderr)
            sys.exit(1)
        separate_clusters(cluster_file)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
