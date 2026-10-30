#!/usr/bin/env python3
import shutil, sys
forbidden=['codeql','joern','semgrep','infer','scan-build']
found=[x for x in forbidden if shutil.which(x)]
if found:
    print('FORBIDDEN_TOOLS_PRESENT=' + ','.join(found))
    sys.exit(1)
print('ENVIRONMENT_OK')
