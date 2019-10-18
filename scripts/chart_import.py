# Import charts from a YAML file into the database.
# - The relevant games and chart types are assumed to already exist.
# - Will create any charts and chart groups that don't exist yet.
#
# See charts.yaml for an example. Note that a chart can be specified as
# a hash of `name` and `type` (chart type), or as just a `name` string for
# brevity. If it's just a name string, then `common_chart_type` must be
# specified by the parent group or an ancestor group.
#
# Requires:
# - Python 3.7+
# - psycopg2-binary (pip install psycopg2-binary)
# - PyYAML (pip install PyYAML)

import argparse
import getpass

import psycopg2
import yaml


class Main:

    def visit_chart_group(
            self, group, game_name, parent_group_id, order,
            common_chart_type=None):
        group_lookup_key = (game_name, parent_group_id, group['name'])
        common_chart_type = group.get('common_chart_type', common_chart_type)

        if group_lookup_key in self.chart_groups_in_db:
            group_id = self.chart_groups_in_db[group_lookup_key]
        else:
            self.cur.execute(
                "INSERT INTO chart_groups"
                " (name, game_id, parent_group_id, order_in_parent,"
                " show_charts_together, created_at, updated_at)"
                " VALUES (%(name)s, %(game_id)s, %(parent_id)s, %(order)s,"
                " %(together)s, NOW(), NOW())"
                " RETURNING id;",
                dict(
                    name=group['name'], game_id=self.games_in_db[game_name],
                    parent_id=parent_group_id, order=order,
                    together=group.get('show_charts_together', 'false'),
                ),
            )
            group_id = self.cur.fetchone()[0]

        if 'child_groups' in group:
            for child_order, child_group in enumerate(group['child_groups'], 1):
                self.visit_chart_group(
                    child_group, game_name, group_id, child_order,
                    common_chart_type=common_chart_type)

        if 'charts' in group:
            for chart_order, chart in enumerate(group['charts'], 1):
                # `chart` can be either a dict, or just a name string.
                # See explanation at the top of the file.
                if isinstance(chart, str):
                    chart_name = chart
                    chart_type = None
                else:
                    chart_name = chart['name']
                    chart_type = chart.get('type')
                if not chart_type:
                    if not common_chart_type:
                        raise ValueError(
                            f"No chart type specified for chart {chart_name}"
                            f" of group {group['name']} (group id {group_id})")
                    chart_type = common_chart_type
                type_id = self.chart_types_in_db[(game_name, chart_type)]

                chart_lookup_key = (group_id, chart_name)

                if chart_lookup_key not in self.charts_in_db:
                    self.cur.execute(
                        "INSERT INTO charts"
                        " (name, chart_group_id, order_in_group, chart_type_id,"
                        " created_at, updated_at)"
                        " VALUES (%(name)s, %(group_id)s, %(order)s, %(type_id)s,"
                        " NOW(), NOW());",
                        dict(
                            name=chart_name, group_id=group_id,
                            order=chart_order, type_id=type_id,
                        ),
                    )

    def __init__(self, cur):
        self.cur = cur

        # Make a lookup of game name -> game id.
        self.cur.execute(
            "SELECT name, id FROM games;",
        )
        self.games_in_db = dict(cur.fetchall())

        # Make a lookup of (game name, chart type name) -> chart type id.
        self.cur.execute(
            "SELECT games.name, chart_types.name, chart_types.id"
            " FROM chart_types"
            " INNER JOIN games ON chart_types.game_id = games.id;",
        )
        self.chart_types_in_db = dict(
            ((game_name, chart_type_name), chart_type_id)
            for game_name, chart_type_name, chart_type_id in self.cur.fetchall()
        )

        # Make a lookup of (game name, parent group id, chart group name)
        # -> chart group id.
        self.cur.execute(
            "SELECT chart_groups.id, chart_groups.name,"
            " chart_groups.parent_group_id, games.name"
            " FROM chart_groups"
            " INNER JOIN games ON chart_groups.game_id = games.id;",
        )
        self.chart_groups_in_db = dict(
            ((game_name, parent_group_id, chart_group_name), chart_group_id)
            for chart_group_id, chart_group_name, parent_group_id, game_name
            in self.cur.fetchall()
        )

        # Make a lookup of (chart group id, chart name) -> chart id.
        self.cur.execute(
            "SELECT id, name, chart_group_id FROM charts;",
        )
        self.charts_in_db = dict(
            ((chart_group_id, chart_name), chart_id)
            for chart_id, chart_name, chart_group_id in self.cur.fetchall()
        )

        # Load chart data
        with open('charts.yaml', 'r') as yamlfile:
            charts_data = yaml.full_load(yamlfile)

        # Add chart groups and charts as necessary
        for game_name, game_top_level_groups in charts_data.items():
            for order, group in enumerate(game_top_level_groups, 1):
                self.visit_chart_group(group, game_name, None, order)

        # Check object counts

        print("Final counts:")

        for game_name, game_id in self.games_in_db.items():
            self.cur.execute(
                "SELECT COUNT(*) FROM chart_groups"
                " WHERE game_id = %(game_id)s;",
                dict(game_id=game_id),
            )
            group_count = self.cur.fetchone()[0]

            self.cur.execute(
                "SELECT COUNT(*) FROM charts"
                " INNER JOIN chart_groups"
                " ON charts.chart_group_id = chart_groups.id"
                " WHERE chart_groups.game_id = %(game_id)s;",
                dict(game_id=game_id),
            )
            chart_count = self.cur.fetchone()[0]

            print(f"{game_name}: {group_count} groups, {chart_count} charts")


if __name__ == '__main__':

    # Parse command line arguments.
    arg_parser = argparse.ArgumentParser(
        description=(
            "Example usage:"
            "\npython chart_import.py localhost 5432 fzerocentral postgres"
        ),
    )

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

    # Connect to the database
    password = getpass.getpass(f"Enter password for user {args.user}: ")
    conn = psycopg2.connect(
        f"host={args.host} port={args.port}"
        f" dbname={args.dbname}"
        f" user={args.user} password={password}")
    # Open a cursor to perform database operations
    cur = conn.cursor()

    Main(cur)

    # Make the changes to the database persistent. If you just want to test
    # without committing, replace commit with rollback.
    conn.commit()

    # Close communication with the database
    cur.close()
    conn.close()
