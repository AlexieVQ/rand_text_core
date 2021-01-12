# `invalid_dir1`

This directory contains rules with basic mistakes, one per rule:

- `no_id` has no `id` attribute,
- `invalid_id` has an invalid id,
- `duplicated_id` has an id which is duplicated,
- `extra_field` has a variant with an extra field,
- `missing_field` has a variant without a field,
- `empty` has no data, not even headers,
- `invalid_enum`, whose attribute `value` only accepts following values:
  - `value1`
  - `value2`
  - `value3`
  has an invalid value,
- `invalid_mult_enum` has a multiple enum attribute accepting above values, with
  an invalid value,
- `malformed_mult_enum` has a multiple enum attribute accepting above values,
  with a wrong separator,
- `null_reference` has a null required reference,
- `invalid_reference` has a reference to a non-existing variant,
- `invalid name` has a name in with a space,
- `invalid_attr_name` has an attribute with an invalid name.

This directory also has a valid rule `simple_rule` targeted by the references.
