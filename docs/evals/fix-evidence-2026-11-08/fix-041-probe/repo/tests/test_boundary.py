import os,pathlib,socket,unittest
BASE=pathlib.Path(os.environ["PROBE_BASE"])
class Boundary(unittest.TestCase):
 def test_read_denied(self):
  for name in ("auth","evaluator","evidence","other"):
   with self.subTest(name=name):
    with self.assertRaises(PermissionError): (BASE/name/"sentinel.txt").read_text()
 def test_write_denied(self):
  for name in ("auth","evaluator","evidence","other"):
   with self.subTest(name=name):
    with self.assertRaises(PermissionError): (BASE/name/"sentinel.txt").write_text("changed")
 def test_workspace_write(self):
  pathlib.Path("test-output.txt").write_text("ok")
 def test_network_denied(self):
  with self.assertRaises(OSError): socket.create_connection(("127.0.0.1",int(os.environ["PROBE_PORT"])),timeout=2)
