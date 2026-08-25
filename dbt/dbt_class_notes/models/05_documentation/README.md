# 📖 Documentation in DBT

dbt provides a built-in documentation generator that parses descriptions, models, column definitions, tests, and sources to generate a interactive, search-friendly HTML site representing your data catalog and lineage.

---

## 1. Simple Schema Documentation
You can write descriptions directly inside your `schema.yml` file:
```yaml
models:
  - name: my_model
    description: "This is a simple model description."
```

## 2. Doc Blocks (Rich Text Documentation)
When descriptions become long, contain formatted lists, links, or equations, putting them in a YAML file gets messy. dbt resolves this via **Doc Blocks** using markdown files (`.md`).

* **How it works**:
  1. Create a `.md` file anywhere in your `models/` directory.
  2. Define a block using `{% docs block_identifier %}` and close it with `{% enddocs %}`.
  3. Reference it in your `.yml` schema file using the `doc()` function: `description: "{{ doc('block_identifier') }}"`.
* **Example md**: See [docs.md](docs.md)
* **Example yml**: See [schema.yml](schema.yml)

## 3. How to Generate and View the Documentation Site

To build the static files:
```bash
dbt docs generate
```
This inspects your project directory and writes metadata files into the `target/` folder.

To start a local server and host the generated site:
```bash
dbt docs serve
```
By default, this hosts a web interface at `http://localhost:8080/` where students can search tables, read markdown definitions, and inspect DAG models visually.
