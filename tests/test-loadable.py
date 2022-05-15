import sqlite3
import unittest
import time
import os

EXT_PATH="./dist/lines0"

def connect():
  db = sqlite3.connect(":memory:")

  db.execute("create table base_functions as select name from pragma_function_list")
  db.execute("create table base_modules as select name from pragma_module_list")

  db.enable_load_extension(True)
  db.load_extension(EXT_PATH)

  db.execute("create temp table loaded_functions as select name from pragma_function_list where name not in (select name from base_functions) order by name")
  db.execute("create temp table loaded_modules as select name from pragma_module_list where name not in (select name from base_modules) order by name")

  db.row_factory = sqlite3.Row
  return db


db = connect()

class TestLines(unittest.TestCase):
  def test_funcs(self):
    funcs = list(map(lambda a: a[0], db.execute("select name from loaded_functions").fetchall()))
    self.assertEqual(funcs, [
      'lines_debug',
      'lines_version',
    ])
  def test_modules(self):
    funcs = list(map(lambda a: a[0], db.execute("select name from loaded_modules").fetchall()))
    self.assertEqual(funcs, [
      "lines_read",
    ])
  def test_lines_version(self):
    v, = db.execute("select lines_version()").fetchone()
    self.assertEqual(v, "0.0.0")

  def test_lines_debug(self):
    debug, = db.execute("select lines_debug()").fetchone()
    self.assertEqual(debug.split('\n')[0], "Version: 0.0.0")
    self.assertTrue(debug.split('\n')[1].startswith("Date: "))

  def test_lines_read(self):
    d = db.execute("select rowid, contents from lines_read(?)", ['test_files/test.txt']).fetchall()
    self.assertEqual(len(d), 3) 
    self.assertEqual(list(map(lambda x: dict(x), d)), [
      {"rowid": 0, "contents": "line1"},
      {"rowid": 1, "contents": "line numba 2"},
      {"rowid": 2, "contents": "line 3 baby"},
    ])
  
  def test_lines_read_crlf(self):
    d = db.execute("select rowid, contents from lines_read(?)", ['test_files/crlf.txt']).fetchall()
    self.assertEqual(len(d), 3) 
    self.assertEqual(list(map(lambda x: dict(x), d)), [
      {"rowid": 0, "contents": "aaa"},
      {"rowid": 1, "contents": "bbb"},
      {"rowid": 2, "contents": "ccc"},
    ])

  def test_lines_read_delim(self):
    d = db.execute("select rowid, contents from lines_read(?, ?);", ['test_files/pipe.txt', '|']).fetchall()
    self.assertEqual(len(d), 5) 
    self.assertEqual(list(map(lambda x: dict(x), d)), [
      {"rowid": 0, "contents": "a"},
      {"rowid": 1, "contents": "b"},
      {"rowid": 2, "contents": "c"},
      {"rowid": 3, "contents": "d"},
      {"rowid": 4, "contents": "yo"},
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
    d = db.execute("select count(*), contents from lines_read(?, char(10)) where rowid = 0;", ['test_files/big.txt']).fetchall()
    e2 = time.process_time()
    self.assertEqual(d[0]["count(*)"], 1) 
    self.assertEqual(d[0]["contents"], "1") 
    duration_ratio = (e2-s2) / (e1-s1)
    self.assertLess(duration_ratio, .01)
    
    d = db.execute("explain query plan select contents from lines_read(?, char(10)) where rowid = 0;", ['test_files/big.txt']).fetchall()
    
    self.assertEqual(len(d), 1)
    self.assertEqual(d[0]["id"], 2)
    self.assertEqual(d[0]["parent"], 0)
    self.assertEqual(d[0]["notused"], 0)
    self.assertEqual(d[0]["detail"], "SCAN lines_read VIRTUAL TABLE INDEX 2:")
    
  def test_lines_read_big_1line(self):
    if os.environ.get('ENV') == "CI":
      self.skipTest("Skipping large file testing on CI environments"
      )
    
    # TODO should be caught and thrown as OperationalError at sqlite_lines-level (with sqlite3_limit) and not sqlite-level
    with self.assertRaisesRegex(sqlite3.DataError, 'string or blob too big'):
      db.execute("select length(contents) from lines_read('test_files/big-line-line.txt');").fetchall()
  
if __name__ == '__main__':
    unittest.main()