## Functions

### `lines_version()`

```sql
select lines_version();
```

### `lines_debug()`

```sql
select lines_debug();
```

## Table Functions

### `lines(document, [delimeter])`

```sql
create table lines(
  contents text,
  delimeter char
);
```

```sql
select * from lines();
```

### `lines_read(path, [delimeter])`

```sql
create table lines_read(
  contents text,
  delimeter char
);
```

```sql
select * from lines_read();
```
