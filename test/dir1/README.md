# `dir1`

This directory contains only valid tables. The tables are:

- `simple_entities`, only containing string values (and obviously their ids),
- `weighted_entites`, containing string values, their ids and their weight,
- `required_references.csv`, whose attribute `simple_entity` references
  `optional_references.csv` in all cases,
- `optional_references.csv`, whose attribute `simple_entity` references
  `simple_entities.csv`, or not.
