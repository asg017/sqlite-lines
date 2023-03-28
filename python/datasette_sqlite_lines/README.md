# The `datasette-sqlite-lines` Datasette Plugin

`datasette-sqlite-lines` is a [Datasette plugin](https://docs.datasette.io/en/stable/plugins.lines) that loads the [`sqlite-lines`](https://github.com/asg017/sqlite-lines) extension in Datasette instances, allowing you to generate and work with [TODO](https://github.com/lines/spec) in SQL.

```
datasette install datasette-sqlite-lines
```

See [`docs.md`](../../docs.md) for a full API reference for the lines SQL functions.

Alternatively, when publishing Datasette instances, you can use the `--install` option to install the plugin.

```
datasette publish cloudrun data.db --service=my-service --install=datasette-sqlite-lines

```
