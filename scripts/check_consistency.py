# /// script
# dependencies = ["pyyaml"]
# ///
"""Check that the AERIE DDL, the mCIDE CSVs, and the clifpy YAML schemas agree.

For every DDL column whose permissible values link to an mCIDE CSV, the bracketed
list in the DDL must equal the categories in that CSV. For assay_category and
assay_group, the expected list is restricted to platforms whose aerie_table is the
DDL table or "either".

Each table's YAML schema must list the DDL's columns in the same order with the
same types, carry the same permissible values, flag required, category, and group
columns consistently with its summary lists, and map assay_category to assay_group
as the mCIDE does. Exits non-zero on any mismatch.

Usage: uv run scripts/check_consistency.py [path/to/ddl.sql]
"""

import csv
import json
import re
import sys
from pathlib import Path

import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_DDL_PATH = REPO_ROOT / "ddl" / "0.1" / "AERIE0.1_MYSQL_ddl.sql"
SCHEMA_DIRECTORY = REPO_ROOT / "schemas" / "0.1"
ASSAY_CATEGORIES_PATH = "mCIDE/common/aerie_assay_categories.csv"
MCIDE_LINK_PATTERN = re.compile(r"^\[(?P<values>[^\]]*)\]\(https://github\.com/[^/]+/[^/]+/blob/[^/]+/(?P<path>mCIDE/[^)]+)\)$")
TABLE_PATTERN = re.compile(r"CREATE TABLE (\w+) \((.*?)\n\);", re.DOTALL)
COLUMN_PATTERN = re.compile(r"^\s*(\w+) (\w+) COMMENT '(.*)',?$", re.MULTILINE)


def read_mcide_rows(csv_path):
    with open(REPO_ROOT / csv_path, newline="") as csv_file:
        return list(csv.DictReader(csv_file))


def assay_rows_for_table(table_name):
    return [row for row in read_mcide_rows(ASSAY_CATEGORIES_PATH) if row["aerie_table"] in (table_name, "either")]


def expected_categories(table_name, column_name, csv_path):
    mcide_rows = read_mcide_rows(csv_path)
    if column_name == "assay_category":
        return [row["assay_category"] for row in assay_rows_for_table(table_name)]
    if column_name == "assay_group":
        groups_in_table = {row["assay_group"] for row in assay_rows_for_table(table_name)}
        return [row["assay_group"] for row in mcide_rows if row["assay_group"] in groups_in_table]
    return [row[column_name] for row in mcide_rows]


def parse_ddl(ddl_path):
    """Return {table_name: [(column_name, data_type, permissible_values or None)]} and any parse problems."""
    problems = []
    ddl_tables = {}
    for table_name, table_body in TABLE_PATTERN.findall(Path(ddl_path).read_text()):
        ddl_tables[table_name] = []
        for column_name, data_type, comment_text in COLUMN_PATTERN.findall(table_body):
            try:
                comment = json.loads(comment_text)
            except json.JSONDecodeError as error:
                problems.append(f"{table_name}.{column_name}: comment is not valid JSON ({error})")
                continue
            link_match = MCIDE_LINK_PATTERN.match(comment["permissible"])
            permissible_values = None
            if link_match:
                permissible_values = [value.strip() for value in link_match["values"].split(",")]
                mcide_values = expected_categories(table_name, column_name, link_match["path"])
                if permissible_values != mcide_values:
                    problems.append(
                        f"{table_name}.{column_name}: DDL lists {permissible_values} but {link_match['path']} gives {mcide_values}"
                    )
            ddl_tables[table_name].append((column_name, data_type, permissible_values))
    linked_column_count = sum(values is not None for columns in ddl_tables.values() for _, _, values in columns)
    if linked_column_count == 0:
        problems.append("no columns link to an mCIDE CSV; the link pattern may no longer match the DDL")
    return ddl_tables, problems


def check_yaml_schema(table_name, ddl_columns):
    schema_path = SCHEMA_DIRECTORY / f"{table_name}_schema.yaml"
    if not schema_path.exists():
        return [f"{table_name}: missing YAML schema {schema_path.relative_to(REPO_ROOT)}"]
    schema = yaml.safe_load(schema_path.read_text())
    problems = []

    ddl_signature = [(name, data_type) for name, data_type, _ in ddl_columns]
    yaml_signature = [(column["name"], column["data_type"]) for column in schema["columns"]]
    if ddl_signature != yaml_signature:
        problems.append(f"{table_name}: YAML columns {yaml_signature} differ from DDL {ddl_signature}")

    ddl_permissible = {name: values for name, _, values in ddl_columns}
    for column in schema["columns"]:
        yaml_values = [str(value) for value in column["permissible_values"]] if "permissible_values" in column else None
        if column["name"] in ddl_permissible and yaml_values != ddl_permissible[column["name"]]:
            problems.append(f"{table_name}.{column['name']}: YAML permissible_values {yaml_values} differ from DDL")

    for flag, summary_key in [("required", "required_columns"), ("is_category_column", "category_columns"),
                              ("is_group_column", "group_columns")]:
        flagged_columns = [column["name"] for column in schema["columns"] if column[flag]]
        if sorted(flagged_columns) != sorted(schema[summary_key] or []):
            problems.append(f"{table_name}: columns with {flag} {flagged_columns} differ from {summary_key} {schema[summary_key]}")

    expected_mapping = {row["assay_category"]: row["assay_group"] for row in assay_rows_for_table(table_name)}
    yaml_mapping = {str(category): group for category, group in schema["assay_category_to_group_mapping"].items()}
    if yaml_mapping != expected_mapping:
        problems.append(f"{table_name}: assay_category_to_group_mapping differs from {ASSAY_CATEGORIES_PATH}")
    return problems


if __name__ == "__main__":
    ddl_path = sys.argv[1] if len(sys.argv) > 1 else DEFAULT_DDL_PATH
    ddl_tables, problems = parse_ddl(ddl_path)
    for table_name, ddl_columns in ddl_tables.items():
        problems += check_yaml_schema(table_name, ddl_columns)
    for problem in problems:
        print(problem)
    print(f"{len(problems)} mismatch(es) across {ddl_path}, mCIDE, and {SCHEMA_DIRECTORY.relative_to(REPO_ROOT)}")
    sys.exit(1 if problems else 0)
