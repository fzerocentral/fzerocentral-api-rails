# Import filters and implication links from a CSV file into a database.
# The CSV is assumed to define all filters and implication links of a
# particular filter group (which is assumed to already exist).
# WARNING: The filter group's existing links/implications will be deleted
# before the import starts. (However, existing filters will not be deleted.)
#
# CSV format:
# First row:
# - game name
# - name of a chart type that uses the filter group of interest
# - filter group name
# Subsequent rows:
# - filter name goes in the first column
# - implication links go in the following columns, one link per column
# If a row defines an implication link toward filter A, filter A must be
# defined in a previous row.
#
# For example:
# F-Zero GX | Course Time | Machine
# Dread Hammer body
# Maximum Star cockpit
# Titan-G4 booster
# Gallant Star-G4 | Dread Hammer body | Maximum Star cockpit | Titan-G4 booster
#
# Requires:
# - Python 3.7+
# - psycopg2-binary (pip install psycopg2-binary)
# - tqdm (pip install tqdm)

import argparse
import csv
import getpass

import psycopg2
from tqdm import tqdm


if __name__ == '__main__':

    # Parse command line arguments.
    arg_parser = argparse.ArgumentParser(
        description=(
            "Example usage:"
            "\npython filter_import.py gx_machine_filters.csv"
            " localhost 5432 fzerocentral postgres"
        ),
    )

    arg_parser.add_argument(
        'csvfile',
        type=str,
        help="Filepath of the CSV file containing the filters")
    arg_parser.add_argument(
        'host',
        type=str,
        help="Host of the DB server (can be 'localhost' if local machine)")
    arg_parser.add_argument(
        'port',
        type=str,
        help="Port of the DB server (Postgres default is 5432)")
    arg_parser.add_argument(
        'dbname',
        type=str,
        help="Name of the database")
    arg_parser.add_argument(
        'user',
        type=str,
        help="Database user to authenticate as")

    args = arg_parser.parse_args()

    # Get filter group details, and establish which filters have implications
    # toward them
    implied_filters = set()
    with open(args.csvfile, 'r') as csvfile:
        reader = csv.reader(csvfile)
        game_name, name_of_ct_with_fg, filter_group_name = next(reader)

        for row in reader:
            implication_link_names = row[1:]
            implied_filters.update(implication_link_names)

    # Connect to an existing database
    password = getpass.getpass(f"Enter password for user {args.user}: ")
    conn = psycopg2.connect(
        f"host={args.host} port={args.port}"
        f" dbname={args.dbname}"
        f" user={args.user} password={password}")
    # Open a cursor to perform database operations
    cur = conn.cursor()

    # Get the existing filter names, so that we don't make any duplicates

    cur.execute(
        "SELECT chart_types.id FROM chart_types"
        " INNER JOIN games"
        " ON chart_types.game_id = games.id"
        " WHERE games.name = %(game_name)s"
        " AND chart_types.name = %(ct_name)s;",
        dict(game_name=game_name, ct_name=name_of_ct_with_fg)
    )
    chart_type_id = cur.fetchone()[0]

    cur.execute(
        "SELECT filter_groups.id FROM filter_groups"
        " INNER JOIN chart_type_filter_groups"
        " ON filter_groups.id = chart_type_filter_groups.filter_group_id"
        " WHERE chart_type_filter_groups.chart_type_id = %(ct_id)s"
        " AND filter_groups.name = %(fg_name)s;",
        dict(ct_id=chart_type_id, fg_name=filter_group_name),
    )
    filter_group_id = cur.fetchone()[0]

    cur.execute(
        "SELECT name, id FROM filters WHERE filter_group_id = %(fg_id)s;",
        dict(fg_id=filter_group_id),
    )
    # dict of names to ids
    existing_filters = dict(cur.fetchall())
    print(f"Existing filters: {len(existing_filters)}")

    # It's just easier to delete existing implications / links, and then
    # subsequently add them all from scratch.
    cur.execute(
        "DELETE FROM filter_implications"
        " WHERE filter_implications.implying_filter_id IN"
        " (SELECT id FROM filters WHERE filter_group_id = %(fg_id)s);",
        dict(fg_id=filter_group_id),
    )
    cur.execute(
        "DELETE FROM filter_implication_links"
        " WHERE filter_implication_links.implying_filter_id IN"
        " (SELECT id FROM filters WHERE filter_group_id = %(fg_id)s);",
        dict(fg_id=filter_group_id),
    )

    # Add filters that don't exist in the DB yet, and add links/implications

    implied_filters_by_name = dict()

    with open(args.csvfile, 'r') as csvfile:
        reader = csv.reader(csvfile)

        # Discard the first row, we don't need it now.
        next(reader)

        for row in tqdm(reader):
            name = row[0]
            implication_link_names = row[1:]

            if name in existing_filters:
                filter_id = existing_filters[name]
            else:
                # Insert filter
                if name in implied_filters:
                    usage_type = 'implied'
                else:
                    usage_type = 'choosable'

                cur.execute(
                    "INSERT INTO filters (name, filter_group_id, usage_type,"
                    " created_at, updated_at)"
                    " VALUES (%(name)s, %(fg_id)s, %(usage_type)s,"
                    " NOW(), NOW())"
                    " RETURNING id;",
                    dict(
                        name=name, fg_id=filter_group_id,
                        usage_type=usage_type,
                    ),
                )
                filter_id = cur.fetchone()[0]

            # Insert implication links and determine effective implications

            values = []
            implications = set()
            interpolations = dict(from_id=filter_id)
            for index, link_name in enumerate(implication_link_names):
                # Set up a DB insert operation which inserts all links at once
                values.append(
                    f"(%(from_id)s, %(to_id_{index})s, NOW(), NOW())")
                interpolations[f'to_id_{index}'] = \
                    implied_filters_by_name[link_name]['id']

                # Determine effective implications
                implications.add(link_name)
                implications.update(
                    implied_filters_by_name[link_name]['implications'])

            if name in implied_filters:
                # If this filter is implied by other filters, save the id and
                # implications for lookup later.
                implied_filters_by_name[name] = dict(
                    id=filter_id, implications=implications)

            if values:
                cur.execute(
                    "INSERT INTO filter_implication_links"
                    " (implying_filter_id, implied_filter_id,"
                    " created_at, updated_at)"
                    f" VALUES {', '.join(values)};",
                    interpolations,
                )

            # Insert effective implications

            values = []
            interpolations = dict(from_id=filter_id)
            for index, implication_name in enumerate(implications):
                # Set up a DB insert operation which inserts all implications
                values.append(
                    f"(%(from_id)s, %(to_id_{index})s, NOW(), NOW())")
                interpolations[f'to_id_{index}'] = \
                    implied_filters_by_name[implication_name]['id']

            if values:
                cur.execute(
                    "INSERT INTO filter_implications"
                    " (implying_filter_id, implied_filter_id,"
                    " created_at, updated_at)"
                    f" VALUES {', '.join(values)};",
                    interpolations,
                )

    # Print counts as sanity checks

    cur.execute(
        "SELECT COUNT(*) FROM filters WHERE filter_group_id = %(fg_id)s;",
        dict(fg_id=filter_group_id),
    )
    count = cur.fetchone()[0]
    print(f"Total filters after insertions: {count}")

    cur.execute(
        "SELECT COUNT(*) FROM filter_implications"
        " INNER JOIN filters"
        " ON filter_implications.implying_filter_id = filters.id"
        " WHERE filters.filter_group_id = %(fg_id)s;",
        dict(fg_id=filter_group_id),
    )
    count = cur.fetchone()[0]
    print(f"Total filter implications after insertions: {count}")

    cur.execute(
        "SELECT COUNT(*) FROM filter_implication_links"
        " INNER JOIN filters"
        " ON filter_implication_links.implying_filter_id = filters.id"
        " WHERE filters.filter_group_id = %(fg_id)s;",
        dict(fg_id=filter_group_id),
    )
    count = cur.fetchone()[0]
    print(f"Total filter implication links after insertions: {count}")

    # Make the changes to the database persistent. If you just want to test
    # without committing, replace commit with rollback.
    conn.commit()

    # Close communication with the database
    cur.close()
    conn.close()
