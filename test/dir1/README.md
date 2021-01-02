# `dir1`

This directory contains only valid rules. The rules are:

- `simple_rule`, only containing string values (and obviously their ids),
- `weighted_rule`, containing string values, their ids and their weight,
- `enum_attribute`, containing the attribute `enum_attr` with the following set
  of accepted values:
  - `value1`
  - `value2`
  - `value3`
- `required_references.csv`, whose attribute `simple_rule` references
  `simple_rule.csv` in all cases,
- `optional_references.csv`, whose attribute `simple_rule` references
  `simple_rule.csv`, or not.
