import unittest
import sqlite3
import sqlite_lines

class TestSqliteLinesPython(unittest.TestCase):
  def test_path(self):
    self.assertEqual(type(sqlite_lines.loadable_path()), str)
  
  def test_load(self):
    db = sqlite3.connect(':memory:')
    db.enable_load_extension(True)
    sqlite_lines.load(db)
    
    version,  = db.execute('select lines_version()').fetchone()
    self.assertEqual(version[0], "v")
    
    license_line_count = db.execute("select count(*) from lines_read(?)", ["LICENSE"]).fetchone()[0]
    self.assertEqual(license_line_count, 7)
    
  def test_load_no_read(self):
    db = sqlite3.connect(':memory:')
    db.enable_load_extension(True)
    sqlite_lines.load_no_read(db)
    version, = db.execute('select lines_version()').fetchone()
    self.assertEqual(version[0], "v")

    with self.assertRaisesRegex(sqlite3.OperationalError, "no such table: lines_read"):
      db.execute("select count(*) from lines_read(?)", ["LICENSE"]).fetchone()[0]

if __name__ == '__main__':
    unittest.main()