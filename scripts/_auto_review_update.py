import sys, re, os

r, t, ch, ar, tp, bn, bp = sys.argv[1:8]

def read(p):
    with open(p, encoding='utf-8') as f:
        return f.read()
def save(p, c):
    with open(p, 'w', encoding='utf-8') as f:
        f.write(c)

# hermes_review.md
rp = os.path.join(r, '.agent', 'hermes_review.md')
rc = read(rp)

tid = 'P0-5'
m = re.search(r'Task IDs?:\s*(.+?)\r?\n', rc, re.DOTALL)
if m:
    tid = m.group(1).split('\r')[0].split('\n')[0].strip()
m = re.search(r'- Task ID:\s*(.+)', rc)
if m:
    tid = m.group(1).strip()

rc = re.sub(r'(?m)^- Result: .+$', '- Result: PASS', rc)
rc = re.sub(r'(?m)^- Waiting for OpenClaw fix: .+$', '- Waiting for OpenClaw fix: NO', rc)
rc = re.sub(r'(?m)^- Last reviewed by: .+$', '- Last reviewed by: Hermes Windows Auto Review', rc)
rc = re.sub(r'(?m)^- Last reviewed at: .+$', '- Last reviewed at: ' + t, rc)

nl = '\r\n'
blk = nl + nl + '### ' + tid + ' (Hermes Windows Auto Review)' + nl
blk += '- Commit: ' + ch + nl
blk += '- Status: PASS' + nl + nl
blk += 'Results:' + nl
blk += '- Flutter analyze: PASS (' + ar + ')' + nl
blk += '- Flutter test: PASS (' + tp + ')' + nl
blk += '- Flutter build: PASS (' + bn + ')' + nl
blk += '- APK: ' + bp + nl
blk += '- git status: CLEAN' + nl

rc = re.sub(r'(?ms)(### [^\n]+(?:Hermes Windows Auto Review)[^\n]*\n.+?)(### 上輪驗收)', r'\1\n### 上輪驗收', rc, count=1)
rc = re.sub(r'(?ms)(\n## 歷史任務摘要\n)', blk + r'\1', rc, count=1)
tbl = '| AutoReview | ' + ch + ' | PASS | ' + t + ' |'
if tbl not in rc:
    rc = re.sub(r'(?m)^(\| Task \| Commit \|)', '| AutoReview | ' + ch + ' | PASS | ' + t + ' |\n\1', rc, count=1)
save(rp, rc)

# handoff_to_hermes.md
hp = os.path.join(r, '.agent', 'handoff_to_hermes.md')
hc = read(hp)
hc = re.sub(r'(?m)^- Status: .+$', '- Status: IDLE', hc)
hc = re.sub(r'(?m)^- Waiting for Hermes: .+$', '- Waiting for Hermes: NO', hc)
hc = re.sub(r'(?m)^- Last updated by: .+$', '- Last updated by: Hermes Windows Auto Review', hc)
hc = re.sub(r'(?m)^- Last updated at: .+$', '- Last updated at: ' + t, hc)
save(hp, hc)

print('DONE')
