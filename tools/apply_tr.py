import json,sys
lang,src=sys.argv[1],sys.argv[2]
S='/tmp/claude-0/-home-claude/8ca9856f-36b6-568f-8d8e-6f5aa3fff238/scratchpad'
todo=json.load(open(S+'/todo.json'))
p='/home/claude/age-of-doctrine/data/i18n/%s.json'%lang
j=json.load(open(p)); ex=j['exact']
n=0
for line in open(src,encoding='utf-8'):
    line=line.rstrip('\n')
    if '|' not in line: continue
    i,t=line.split('|',1)
    try: k=todo[int(i)]
    except: continue
    t=t.replace('\\n','\n')
    if t.strip() and k not in ex:
        ex[k]=t; n+=1
json.dump(j,open(p,'w'),ensure_ascii=False,separators=(',',':'))
print(lang,'eklendi',n,'/',len(todo))
