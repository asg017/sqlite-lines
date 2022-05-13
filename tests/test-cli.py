import unittest
import subprocess 

class Results:
  def __init__(self, stdout, stderr):
    self.stdout = stdout
    self.stderr = stderr

def run_cli(input, args=[]):
  if type(args) is list:
    args = ["dist/sqlite-lines"] + args
  else:
    args = ["dist/sqlite-lines"] + [args]

  proc = subprocess.Popen(args, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
  stdout, stderr = proc.communicate(input.encode())
  out = stdout.decode('utf8') if type(stdout) is bytes else None
  err = stderr.decode('utf8') if type(stderr) is bytes else None
  return Results(out, err)

# 0-9
numbers = '\n'.join(list(map(lambda x: str(x), range(0, 10))))
ndjson = """{"name": "alex", "age": 100, "color": "red"}
{"name": "brian", "age": 200, "color": "red"}
{"name": "craig", "age": 300, "color": "blue"}"""
groupby = ''

class TestSqliteLinesCli(unittest.TestCase):
  def test_cli_scalar(self):
    self.assertEqual(run_cli('a', 'upper(d), hex(d)').stdout,  'A,61\n')
    self.assertEqual(run_cli('1', 'hex(d)').stdout,  '31\n')
    self.assertEqual(run_cli('{"name": "Alex"}', 'lower(d ->> "$.name")').stdout, 'alex\n')
    
  def test_cli_aggregate(self):
    self.assertEqual(run_cli(numbers, 'sum(d)').stdout, '45\n')
    self.assertEqual(run_cli(numbers, 'count(*)').stdout, '10\n')
    self.assertEqual(run_cli(ndjson, 'count(*)').stdout, '3\n')
    self.assertEqual(run_cli(ndjson, 'sum(d ->> "age")').stdout, '600\n')
  
  def test_cli_where(self):
    self.assertEqual(run_cli(numbers, ['sum(d)', 'd < 3']).stdout, '3\n')
    self.assertEqual(run_cli(ndjson, ['d ->> "name"', 'd ->> "age" > 150']).stdout, 'brian\ncraig\n')
  
  def test_cli_groupby(self):
    self.assertEqual(run_cli(ndjson, ['d ->> "color", count(*)', '1', '1']).stdout, 'blue,1\nred,2\n')

if __name__ == '__main__':
    unittest.main()