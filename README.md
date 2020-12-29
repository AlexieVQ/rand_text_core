# RandTextCore

Core for writing random text generators in Ruby.

This tool was developed after working on Twitter bots using Kate Compton's
[Tracery](https://github.com/galaxykate/tracery) through
[Cheap Bots, Done Quick!](https://cheapbotsdonequick.com/). This tool reuses
Tracery's principle of text-expansion using a grammar, but the main addition is
that the grammar is attributed and stored in a relational way (inspired by SQL):

- each grammar rule is a relation, stored in a CSV file (using semicolons _;_ as
  separators),
- each variant of a rule is a tuple of the relation,
- each attribute of the relation is an attribute of the rule.

That means the following Tracery grammar:

```json
{
    "origin": [
        "rule 1: #rule1#, rule 2: #rule2#",
        "rule 2: #rule2#, rule 1: #rule1#"
    ],

    "rule1": [
        "rule 1 variant 1",
        "rule 1 variant 2",
        "rule 1 variant 3"
 ],

    "rule2": [
        "rule 2 variant 1",
        "rule 2 variant 2",
        "rule 2 variant 3
    ]
}
```

becomes the following set of CSV tables in RandTextCore:

**`origin.csv`**:

```text
id;value
1;rule 1: {Rule1()}, rule 2: {Rule2()}
2;rule 2: {Rule2()}, rule 1: {Rule1()}
```

**`rule1.csv`**:

```text
id;value
1;rule 1 variant 1
2;rule 1 variant 2
3;rule 1 variant 3
```

**`rule2.csv`**:

```text
id;value
1;rule 2 variant 1
2;rule 2 variant 2
3;rule 2 variant 3
```
