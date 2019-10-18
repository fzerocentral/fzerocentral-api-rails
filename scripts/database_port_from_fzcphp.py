# Requires:
# - Python 3.7+
# - mysqlclient (pip install mysqlclient)
# - psycopg2-binary (pip install psycopg2-binary)
# - PyYAML (pip install PyYAML)
# - tqdm (pip install tqdm)

import argparse
import getpass
import re

import MySQLdb
import psycopg2
from tqdm import tqdm
import yaml


def normalize_machine_name(name, ship_misspellings):
    # Address some known misspellings in the FZC PHP database.
    if name in ship_misspellings:
        name = ship_misspellings[name]
    # Remove spaces and punctuation.
    name = re.sub(r'[^A-Za-z0-9]+', '', name)
    # Uppercase to lowercase.
    return name.lower()


if __name__ == '__main__':

    # Parse command line arguments.
    arg_parser = argparse.ArgumentParser(
        description=(
            "Example usage:"
            "\npython database_port_from_fzcphp.py"
            " localhost 3306 fzc_php root"
            " localhost 5432 fzerocentral postgres"
        ),
    )

    arg_parser.add_argument(
        'mysql_host',
        type=str,
        help="Host of the MySQL server (can be 'localhost' if local machine)")
    arg_parser.add_argument(
        'mysql_port',
        type=int,
        help="Port of the MySQL server (MySQL default is 3306)")
    arg_parser.add_argument(
        'mysql_dbname',
        type=str,
        help="Name of the MySQL database")
    arg_parser.add_argument(
        'mysql_user',
        type=str,
        help="MySQL user to authenticate as")

    arg_parser.add_argument(
        'pg_host',
        type=str,
        help="Host of the PostgreSQL server ('localhost' if local machine)")
    arg_parser.add_argument(
        'pg_port',
        type=int,
        help="Port of the PostgreSQL server (PostgreSQL default is 5432)")
    arg_parser.add_argument(
        'pg_dbname',
        type=str,
        help="Name of the PostgreSQL database")
    arg_parser.add_argument(
        'pg_user',
        type=str,
        help="PostgreSQL user to authenticate as")

    args = arg_parser.parse_args()

    # Connect to the MySQL DB
    password = getpass.getpass(
        f"Enter password for MySQL user {args.mysql_user}: ")
    mysql_conn = MySQLdb.connect(
        host=args.mysql_host, port=args.mysql_port,
        user=args.mysql_user, passwd=password,
        db=args.mysql_dbname, charset='utf8')
    mysql_cur = mysql_conn.cursor(MySQLdb.cursors.DictCursor)

    # Connect to the PostgreSQL DB
    password = getpass.getpass(
        f"Enter password for PostgreSQL user {args.pg_user}: ")
    pg_conn = psycopg2.connect(
        f"host={args.pg_host} port={args.pg_port}"
        f" dbname={args.pg_dbname}"
        f" user={args.pg_user} password={password}")
    pg_cur = pg_conn.cursor()

    # Make a lookup of (game name, chart group name 1, ..., chart group name n,
    # chart name) -> chart id in FZC Rails.

    pg_cur.execute(
        "SELECT chart_groups.id, chart_groups.name,"
        " chart_groups.parent_group_id, games.name"
        " FROM chart_groups"
        " INNER JOIN games ON chart_groups.game_id = games.id;",
    )
    fzcrails_chart_group_lookup = dict(
        (chart_group_id, (game_name, parent_group_id, chart_group_name))
        for chart_group_id, chart_group_name, parent_group_id, game_name
        in pg_cur.fetchall()
    )

    def chart_group_hierarchy_tuple(chart_group_id_):
        game_name, parent_group_id, chart_group_name = \
            fzcrails_chart_group_lookup[chart_group_id_]
        if parent_group_id:
            return chart_group_hierarchy_tuple(parent_group_id) \
                + (chart_group_name,)
        else:
            return (game_name, chart_group_name)

    pg_cur.execute(
        "SELECT id, name, chart_group_id FROM charts;",
    )
    fzcrails_chart_lookup = dict()
    for chart_id, chart_name, chart_group_id in pg_cur.fetchall():
        lookup_key = chart_group_hierarchy_tuple(chart_group_id) + (chart_name,)
        fzcrails_chart_lookup[lookup_key] = chart_id

    # Make a lookup of FZC PHP ladder / cup / course / record type
    # -> FZC Rails chart id.
    # Also a lookup of FZC PHP ladder -> filters.

    fzcphp_to_fzcrails_chart_lookup = dict()
    fzcphp_ladder_lookup = dict()

    with open('charts_from_fzcphp_ladders.yaml', 'r') as yamlfile:
        charts_from_fzcphp_ladders = yaml.full_load(yamlfile)

        for ladder, ladder_details in charts_from_fzcphp_ladders.items():
            # ladder_5 -> 5
            ladder_num = int(ladder[-1])
            game_name = ladder_details['game_name']
            filters = ladder_details.get('filters', dict())
            fzcphp_ladder_lookup[ladder_num] = dict(
                filters=filters, game_name=game_name)

            for cup_num, cup in enumerate(ladder_details['cups'], 1):

                for course_num, course_name in enumerate(cup['courses'], 1):

                    for record_type_code, record_type_name in ladder_details['record_types'].items():

                        fzcrails_chart_lookup_key = (game_name, "Cups", cup['name'], course_name, record_type_name)
                        fzcrails_chart_id = fzcrails_chart_lookup[fzcrails_chart_lookup_key]
                        fzcphp_to_fzcrails_chart_lookup[(ladder_num, cup_num, course_num, record_type_code)] = fzcrails_chart_id

    # Make a lookup of (game name, chart type name, filter group name,
    # filter name) -> filter id in FZC Rails.

    with open('ship_misspellings.yaml', 'r', encoding='utf-8') as yamlfile:
        ship_misspellings = yaml.full_load(yamlfile)

    pg_cur.execute(
        "SELECT games.name as game_name,"
        " filter_groups.name as filter_group_name,"
        " filters.name as filter_name,"
        " filters.id as filter_id"
        " FROM filters"
        " INNER JOIN filter_groups ON filters.filter_group_id = filter_groups.id"
        " INNER JOIN chart_type_filter_groups ON chart_type_filter_groups.filter_group_id = filter_groups.id"
        " INNER JOIN chart_types ON chart_types.id = chart_type_filter_groups.chart_type_id"
        " INNER JOIN games ON chart_types.game_id = games.id;"
    )
    fzcrails_filter_lookup = dict()
    for game_name, filter_group_name, filter_name, filter_id \
            in pg_cur.fetchall():
        if filter_group_name == "Machine":
            # Since machines are user-entered, normalize the machine strings
            # to get as many matches as possible.
            filter_name = normalize_machine_name(filter_name, ship_misspellings)
        fzcrails_filter_lookup[(game_name, filter_group_name, filter_name)] = \
            filter_id

    # Make a lookup of user id on FZC PHP -> user name.
    mysql_cur.execute("SELECT user_id, username FROM phpbb_users;")
    fzcphp_user_lookup = dict(
        (u['user_id'], u['username']) for u in mysql_cur.fetchall())

    # Make a lookup of user name -> user id on FZC Rails. Later we'll update
    # this if we need to add new users.
    pg_cur.execute("SELECT username, id FROM users;")
    fzcrails_user_lookup = dict(pg_cur.fetchall())

    # Get FZC PHP records.
    #
    # We'll process records in a particular FZC-PHP ladder order. The reason is
    # so we can process ladders with more specific categories first, and then
    # more general ones after. For example, if a time is found in both max
    # speed and open ladders for GX, we want to make sure we add it with max
    # speed filters.

    # TODO: We're only processing records for GX time attack for now, but
    # should cover other ladders and games later.
    ladder_order = [
        # F-Zero GX time attack: max speed, snaking, open
        5, 8, 4,
    ]

    php_records = []
    for ladder_id in ladder_order:
        mysql_cur.execute(
            "SELECT * FROM phpbb_f0_records WHERE ladder_id = %(ladder_id)s",
            dict(ladder_id=ladder_id))
        php_records.extend(mysql_cur.fetchall())

    # Create a lookup of FZC Rails records, so we don't create any duplicates.
    # This includes pre-existing FZC Rails records, as well as duplicates among
    # FZC PHP records.

    pg_cur.execute("SELECT chart_id, user_id, value, id FROM records;")
    fzcrails_record_lookup = dict(
        ((chart_id, user_id, value), record_id)
        for chart_id, user_id, value, record_id
        in pg_cur.fetchall()
    )

    # Convert FZC PHP records to FZC Rails records. Also link applicable
    # filters to the records.

    fzcphp_deleted_user_ids = set()
    unrecognized_ships = set()

    for php_record in tqdm(php_records):
        rails_record = dict()

        # value column is already the same.
        value = php_record['value']

        # last_change is the only date field on FZC PHP records, so we use
        # that, even if it's not the same as achievement date.
        achieved_at = php_record['last_change']

        # Several FZC PHP columns correspond to chart_id.
        chart_id = fzcphp_to_fzcrails_chart_lookup[(
            php_record['ladder_id'], php_record['cup_id'],
            php_record['course_id'], php_record['record_type'])]

        # Need to translate user_id across DBs.

        # Detect deleted users whose records still remain in FZC PHP.
        # We won't add these records, but we'll track the deleted user ids
        # to print after we're done.
        if php_record['user_id'] not in fzcphp_user_lookup:
            fzcphp_deleted_user_ids.add(php_record['user_id'])
            continue

        username = fzcphp_user_lookup[php_record['user_id']]

        # Create a new user in FZC Rails if needed.
        if username not in fzcrails_user_lookup:
            pg_cur.execute(
                "INSERT INTO users"
                " (username, created_at, updated_at)"
                " VALUES (%(name)s, NOW(), NOW())"
                " RETURNING id;",
                dict(
                    name=username,
                ),
            )
            fzcrails_user_lookup[username] = pg_cur.fetchone()[0]
        user_id = fzcrails_user_lookup[username]

        # See if the record exists.
        # We'll assume that same chart + same user + same time/score means
        # the same record.
        lookup_key = (chart_id, user_id, value)
        if lookup_key in fzcrails_record_lookup:
            # The record exists, so we're done here.
            continue

        # Create the record.
        pg_cur.execute(
            "INSERT INTO records"
            " (value, achieved_at, chart_id, user_id,"
            " created_at, updated_at)"
            " VALUES (%(value)s, %(achieved_at)s, %(chart_id)s,"
            " %(user_id)s, NOW(), NOW())"
            " RETURNING id;",
            dict(
                value=value, achieved_at=achieved_at,
                chart_id=chart_id, user_id=user_id,
            ),
        )
        record_id = pg_cur.fetchone()[0]

        # Set filters.

        # Filters specified in YAML
        filter_ids = []
        game_name = fzcphp_ladder_lookup[php_record['ladder_id']]['game_name']
        ladder_filters = \
            fzcphp_ladder_lookup[php_record['ladder_id']]['filters']
        for filter_group_name, filter_name in ladder_filters.items():
            filter_id = fzcrails_filter_lookup[(
                game_name, filter_group_name, filter_name)]
            filter_ids.append(filter_id)

        # Machine filters
        normalized_machine_name = normalize_machine_name(
            php_record['ship'], ship_misspellings)
        machine_lookup_key = (game_name, 'Machine', normalized_machine_name)
        if machine_lookup_key in fzcrails_filter_lookup:
            filter_id = fzcrails_filter_lookup[machine_lookup_key]
            filter_ids.append(filter_id)
        else:
            unrecognized_ships.add(php_record['ship'])

        for filter_id in filter_ids:
            pg_cur.execute(
                "INSERT INTO record_filters"
                " (record_id, filter_id, created_at, updated_at)"
                " VALUES (%(record_id)s, %(filter_id)s, NOW(), NOW());",
                dict(
                    record_id=record_id, filter_id=filter_id,
                ),
            )

    print("Final counts:")

    pg_cur.execute(
        "SELECT COUNT(*) FROM users;",
    )
    print(pg_cur.fetchone()[0], "users")

    pg_cur.execute(
        "SELECT COUNT(*) FROM records;",
    )
    print(pg_cur.fetchone()[0], "records")

    pg_cur.execute(
        "SELECT COUNT(*) FROM record_filters;",
    )
    print(pg_cur.fetchone()[0], "filter applications to records")

    if fzcphp_deleted_user_ids:
        print(
            "Deleted user ids found in FZC PHP:",
            ', '.join([str(user_id) for user_id in fzcphp_deleted_user_ids]))
    else:
        print("No deleted user ids found in FZC PHP")

    if unrecognized_ships:
        print("Unrecognized ships:", ', '.join(unrecognized_ships))
    else:
        print("No unrecognized ships")

    # Make the changes to the database persistent. If you just want to test
    # without committing, replace commit with rollback.
    pg_conn.commit()

    # Close communication with the databases
    mysql_conn.close()
    pg_cur.close()
    pg_conn.close()
