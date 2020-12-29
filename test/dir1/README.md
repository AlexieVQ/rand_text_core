# `dir1`

This directory contains only valid rules. The rules are:

- `simple_rule`, only containing string values (and obviously their ids),
- `weighted_rule`, containing string values, their ids and their weight,
- `required_references.csv`, whose attribute `simple_rule` references
  `simple_rule.csv` in all cases,
- `optional_references.csv`, whose attribute `simple_rule` references
  `simple_rule.csv`, or not.
