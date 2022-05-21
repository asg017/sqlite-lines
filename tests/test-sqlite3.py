import unittest
import subprocess 

class Results:
  def __init__(self, stdout, stderr):
    self.stdout = stdout
    self.stderr = stderr

def run_sqlite3(input):
  if type(input) is list:
    args = ["dist/sqlite3", ":memory:"] + input
  else:
    args = ["dist/sqlite3", ":memory:"] + [input]
  
  proc = subprocess.run(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
  out = proc.stdout.decode('utf8') if type(proc.stdout) is bytes else None
  err = proc.stderr.decode('utf8') if type(proc.stderr) is bytes else None
  return Results(out, err)

class TestSqliteLinesCli(unittest.TestCase):
  def test_cli_scalar(self):
    self.assertEqual(run_sqlite3('select 1').stdout,  '1\n')
    self.assertEqual(
      run_sqlite3(['select name from pragma_function_list where name like "lines_%" order by 1']).stdout,  
      "lines_debug\nlines_version\n"
    )
    self.assertEqual(
      run_sqlite3(['select name from pragma_module_list where name like "lines_%" order by 1']).stdout,  
      "lines_read\n"
    )
    self.assertEqual(
      run_sqlite3(['select rowid, line from lines_read("test_files/test.txt")']).stdout,  
      "1|line1\n2|line numba 2\n3|line 3 baby\n"
    )

    self.assertEqual(
      run_sqlite3(["""
        select name, line 
        from fsdir("test_files") 
        join lines_read(name) as lines
        where name like 'test_files/x%' and  lines.rowid = 1
        order by 1;
      """]).stdout,  
      "test_files/x2.txt|x2!\ntest_files/x1.txt|x1!\n"
    )

if __name__ == '__main__':
    unittest.main()