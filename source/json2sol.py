#!/usr/bin/python3

import json,sys,os,traceback,re

def main():
    if len(sys.argv) > 2:
        print(f"Usage: {sys.argv[0]} <path to json file>")
        print(f"       cat <file with paths> | {sys.argv[0]}")
        return 1
    if len(sys.argv) == 2:
        json2sol(sys.argv[1])
    else:
        for line in sys.stdin:
            json2sol(line.rstrip('\n'))

def json2sol(fn):
    if not fn.endswith(".json"):
        print(f"{fn} does not seem to be a json file, skipping")
        return 1
    dn = fn[:-5]
    if os.path.exists(dn):
        print(f"{dn} already exists, skipping {fn}")
        return 1
    with open(fn) as f:
        try:
            data = json.load(f)
        except Exception:
            print(fn)
            traceback.print_exc(file=sys.stdout)
            sys.stdout.flush()
            return 1
    os.makedirs(dn, exist_ok=True)
    assert data['status'] == '1'
    assert data['message'] == 'OK'
    results = data['result']
    assert len(results) == 1
    result = results[0]
    assert 'SourceCode' in result and result['SourceCode'] != ''
    sourceCode = result['SourceCode']
    if sourceCode.startswith('{{'):
        try:
            sources = json.loads(sourceCode[1:-1], strict=False)
        except Exception:
            print(fn)
            traceback.print_exc(file=sys.stdout)
            sys.stdout.flush()
            return 1
        assert 'language' in sources
        with open(f"{dn}/language", 'w') as f:
            f.write(sources['language'].replace('\r','')+"\n")
        assert 'settings' in sources
        with open(f"{dn}/settings", 'w') as f:
            f.write(f"{sources['settings']}\n")
        assert 'sources' in sources
        for path,content in sources['sources'].items():
            os.makedirs(f"{dn}/{os.path.dirname(path)}", exist_ok=True)
            with open(f"{dn}/{path}", 'w') as f:
                f.write(content['content'].replace('\r','')+"\n")
    elif sourceCode.startswith('{'):
        try:
            sources = json.loads(sourceCode)
        except Exception:
            print(fn)
            traceback.print_exc(file=sys.stdout)
            sys.stdout.flush()
            return 1
        for path,content in sources.items():
            os.makedirs(f"{dn}/{os.path.dirname(path)}", exist_ok=True)
            with open(f"{dn}/{path}", 'w') as f:
                f.write(content['content'].replace('\r','')+"\n")
    else:
        contractName = result.get('ContractName',os.path.basename(dn))
        if result.get('CompilerVersion','').startswith('vyper'):
            ext = 'vy'
        else:
            ext = 'sol'
        with open(f"{dn}/{contractName}.sol", 'w') as f:
                f.write(sourceCode.replace('\r','')+"\n")

if __name__ == '__main__':
    sys.exit(main())
