import sqlite3
import unittest
import time
import os

EXT_PATH="./dist/lines0"

def connect(ext):
  db = sqlite3.connect(":memory:")

  db.execute("create table base_functions as select name from pragma_function_list")
  db.execute("create table base_modules as select name from pragma_module_list")

  db.enable_load_extension(True)
  db.load_extension(ext)

  db.execute("create temp table loaded_functions as select name from pragma_function_list where name not in (select name from base_functions) order by name")
  db.execute("create temp table loaded_modules as select name from pragma_module_list where name not in (select name from base_modules) order by name")

  db.row_factory = sqlite3.Row
  return db


db = connect(EXT_PATH)

def explain_query_plan(sql):
  return db.execute("explain query plan " + sql).fetchone()["detail"]

def execute_all(sql, args=None):
  if args is None: args = []
  results = db.execute(sql, args).fetchall()
  return list(map(lambda x: dict(x), results))

FUNCTIONS = [
  "lines_debug",
  "lines_version",
]

MODULES = [
  "lines",
  "lines_read",
]
class TestLines(unittest.TestCase):
  def test_funcs(self):
    funcs = list(map(lambda a: a[0], db.execute("select name from loaded_functions").fetchall()))
    self.assertEqual(funcs, FUNCTIONS)

  def test_modules(self):
    modules = list(map(lambda a: a[0], db.execute("select name from loaded_modules").fetchall()))
    self.assertEqual(modules, MODULES)
    
  def test_lines_version(self):
    with open("./VERSION") as f:
      version = 'v' + f.read()
    
    self.assertEqual(db.execute("select lines_version()").fetchone()[0], version)

  def test_lines_debug(self):
    debug = db.execute("select lines_debug()").fetchone()[0].split('\n')
    self.assertEqual(len(debug), 3)

    self.assertTrue(debug[0].startswith("Version: v"))
    self.assertTrue(debug[1].startswith("Date: "))
    self.assertTrue(debug[2].startswith("Source: "))
    #self.assertTrue(debug_nofs[3] == "NO FILESYSTEM")
  
  def test_lines(self):
    self.assertEqual(execute_all("select rowid, delimiter, document, line from lines(?)", ["a\nb"]), [
      {"rowid": 1, "delimiter": "\n", "document": "", "line": "a"},
      {"rowid": 2, "delimiter": "\n", "document": "", "line": "b"},
    ])
    with self.assertRaisesRegex(sqlite3.OperationalError, 'Delimiter must be 1 character long, got 2 characters'):
      self.assertEqual(execute_all("select line from lines('axxb', 'xx')"), [])

  def test_lines_read(self):
    self.assertEqual(execute_all("select rowid, path, delimiter, line from lines_read(?)", ['test_files/test.txt']), [
      {"rowid": 1, "path": "test_files/test.txt", "delimiter": "\n", "line": "line1"},
      {"rowid": 2, "path": "test_files/test.txt", "delimiter": "\n", "line": "line numba 2"},
      {"rowid": 3, "path": "test_files/test.txt", "delimiter": "\n", "line": "line 3 baby"},
    ])
    with self.assertRaisesRegex(sqlite3.OperationalError, 'Error reading notexist.txt: No such file or directory'):
      self.assertEqual(execute_all("select line from lines_read('notexist.txt')"))
  
  def test_lines_read_crlf(self):
    self.assertEqual(execute_all("select rowid, line from lines_read(?)", ['test_files/crlf.txt']), [
      {"rowid": 1, "line": "aaa"},
      {"rowid": 2, "line": "bbb"},
      {"rowid": 3, "line": "ccc"},
    ])

  def test_lines_read_delim(self):
    self.assertEqual(execute_all("select rowid, line from lines_read(?, ?);", ['test_files/pipe.txt', '|']), [
      {"rowid": 1, "line": "a"},
      {"rowid": 2, "line": "b"},
      {"rowid": 3, "line": "c"},
      {"rowid": 4, "line": "d"},
      {"rowid": 5, "line": "yo"},
    ])
  
  def test_lines_read_big(self):
    if os.environ.get('ENV') == "CI":
      self.skipTest("Skipping large file testing on CI environments"
      )
    
    s1 = time.process_time()
    d = db.execute("select count(*) as count from lines_read(?);", ['test_files/big.txt']).fetchall()
    e1 = time.process_time()
    self.assertEqual(d[0]["count"], 1000001) 

    s2 = time.process_time()
    d = db.execute("select count(*), line from lines_read(?) where rowid = 0;", ['test_files/big.txt']).fetchall()
    e2 = time.process_time()
    self.assertEqual(d[0]["count(*)"], 1) 
    self.assertEqual(d[0]["line"], "1") 
    duration_ratio = (e2-s2) / (e1-s1)
    self.assertLess(duration_ratio, .01)
    
  def test_lines_read_big_1line(self):
    if os.environ.get('ENV') == "CI":
      self.skipTest("Skipping large file testing on CI environments"
      )
    
    with self.assertRaisesRegex(sqlite3.OperationalError, 'line 1 has a size of 1001000000 bytes, but SQLITE_LIMIT_LENGTH is 1000000000'):
      execute_all("select length(line) from lines_read('test_files/big-line-line.txt');")
  
  def test_lines_query_plan(self):
    self.assertIn(
      explain_query_plan("select line from lines('') where rowid = 0;"),
      ["SCAN lines VIRTUAL TABLE INDEX 2:RP0", "SCAN TABLE lines VIRTUAL TABLE INDEX 2:RP0"]
    )
    self.assertIn(
      explain_query_plan("select line from lines('', 'a') where rowid = 0;"),
      ["SCAN lines VIRTUAL TABLE INDEX 2:RPD", "SCAN TABLE lines VIRTUAL TABLE INDEX 2:RPD"]
    )
    self.assertIn(
      explain_query_plan("select line from lines('')"),
      ["SCAN lines VIRTUAL TABLE INDEX 1:P00", "SCAN TABLE lines VIRTUAL TABLE INDEX 1:P00"]
    )

    # TODO should be "document" for lines()
    with self.assertRaisesRegex(sqlite3.OperationalError, 'path argument is required'):
      explain_query_plan("select line from lines_read")
  
  def test_lines_read_query_plan(self):
    self.assertIn(
      explain_query_plan("select line from lines_read('') where rowid = 0;"),
      ["SCAN lines_read VIRTUAL TABLE INDEX 2:RP0", "SCAN TABLE lines_read VIRTUAL TABLE INDEX 2:RP0"]

    )
    self.assertIn(
      explain_query_plan("select line from lines_read('', 'a') where rowid = 0;"),
      ["SCAN lines_read VIRTUAL TABLE INDEX 2:RPD", "SCAN TABLE lines_read VIRTUAL TABLE INDEX 2:RPD"]
    )
    self.assertIn(
      explain_query_plan("select line from lines_read('')"),
      ["SCAN lines_read VIRTUAL TABLE INDEX 1:P00", "SCAN TABLE lines_read VIRTUAL TABLE INDEX 1:P00"]
    )
    with self.assertRaisesRegex(sqlite3.OperationalError, 'path argument is required'):
      explain_query_plan("select line from lines_read")

class TestCoverage(unittest.TestCase):                                      
  def test_coverage(self):                                                      
    test_methods = [method for method in dir(TestLines) if method.startswith('test_lines')]
    funcs_with_tests = set([x.replace("test_", "") for x in test_methods])
    for func in FUNCTIONS:
      self.assertTrue(func in funcs_with_tests, f"{func} does not have cooresponding test in {funcs_with_tests}")

if __name__ == '__main__':
    unittest.main()