# Monoses Third-Party Setup Guide

**Date Created:** November 4, 2025  
**Purpose:** Complete setup instructions for replicating the monoses third-party dependencies on new servers

---

## Table of Contents
1. [Prerequisites](#prerequisites)
2. [Initial Setup](#initial-setup)
3. [Python Dependencies](#python-dependencies)
4. [Moses2 Source Code Modifications](#moses2-source-code-modifications)
5. [Compilation Steps](#compilation-steps)
6. [Verification](#verification)
7. [Usage Instructions](#usage-instructions)
8. [Troubleshooting](#troubleshooting)

---

## Prerequisites

### System Requirements
- Linux system with bash shell
- GCC compiler (tested with 11.4.0)
- Boost library (tested with 1.83.0)
- Python 3.6+
- Java (OpenJDK 1.8 or later)

### Environment Modules (if using module system)
```bash
module load gcc/11.4.0
module load boost/1.83.0
```

---

## Initial Setup

### 1. Clone and Download Third-Party Dependencies

```bash
cd /path/to/Translation-Without-Supervision/external/monoses
./get-third-party.sh
```

This will download:
- Moses v4.0
- FastAlign
- Phrase2vec
- VecMap
- Fairseq
- Subword-NMT
- SacreBLEU

### 2. Compile FastAlign

FastAlign should compile successfully without modifications:

```bash
cd third-party/fast_align
mkdir -p build
cd build
cmake ..
make
```

**Verify:** `./fast_align` should exist in the `build/` directory

### 3. Compile Phrase2vec

```bash
cd ../../phrase2vec
make
```

**Verify:** `./word2vec` binary should exist and be executable

### 4. Compile ZMERT (Java Tuning Module)

```bash
cd ../../..  # Back to monoses directory
cd training/tuning/zmert
make
```

**Verify:** `build/tune.jar` should exist

---

## Python Dependencies

### 1. Create and Activate Virtual Environment

```bash
cd /path/to/Translation-Without-Supervision/external/monoses
python3 -m venv venv_pytorch04
source venv_pytorch04/bin/activate
```

### 2. Install Python Packages

```bash
# Upgrade pip first
pip install --upgrade pip

# Install PyTorch (version may vary based on your CUDA version)
# For the version used in this setup:
pip install torch==1.10.2

# Install Cython (required for editdistance)
pip install Cython

# Install editdistance
pip install editdistance
```

### 3. Verify Python Packages

```bash
python -c "import torch; print('PyTorch:', torch.__version__)"
python -c "import editdistance; print('editdistance: OK')"
```

---

## Moses2 Source Code Modifications

**IMPORTANT:** Moses2 requires xmlrpc-c library for server functionality, which is not available. We need to disable server support by modifying the source code. The batch mode (used by monoses training) will still work.

### File 1: `third-party/moses/moses2/Jamfile`

**Location:** `third-party/moses/moses2/Jamfile`

#### Change 1 - Comment out ServerOptions.cpp (around line 100):
```diff
    parameters/ReorderingOptions.cpp
    parameters/ReportingOptions.cpp
    parameters/SearchOptions.cpp
-   parameters/ServerOptions.cpp
+#   parameters/ServerOptions.cpp
    parameters/SyntaxOptions.cpp
```

#### Change 2 - Comment out server source files (around line 171):
```diff
    SCFG/nbest/NBests.cpp
    SCFG/nbest/NBestColl.cpp

-	server/Server.cpp
-	server/Translator.cpp
-	server/TranslationRequest.cpp
+#	server/Server.cpp
+#	server/Translator.cpp
+#	server/TranslationRequest.cpp
	
    deps
```

#### Change 3 - Force moses2 to build without xmlrpc (around line 183):
```diff
 exe moses2 : Main.cpp moses2_lib ../probingpt//probingpt ../util//kenutil ../lm//kenlm ;
 
-if [ xmlrpc ] {
-  echo "Building Moses2" ;
-  alias programs : moses2 ;
-}
-else {
-  echo "Not building Moses2" ;
-  alias programs : ;
-}
+# Always build moses2 (server functionality disabled)
+echo "Building Moses2 without server support" ;
+alias programs : moses2 ;
+
+# if [ xmlrpc ] {
+#   echo "Building Moses2" ;
+#   alias programs : moses2 ;
+# }
+# else {
+#   echo "Not building Moses2" ;
+#   alias programs : ;
+# }
```

---

### File 2: `third-party/moses/moses2/parameters/AllOptions.h`

**Location:** `third-party/moses/moses2/parameters/AllOptions.h`

#### Change 1 - Comment out ServerOptions include (around line 16):
```diff
 #include "LMBR_Options.h"
 #include "ReportingOptions.h"
 #include "OOVHandlingOptions.h"
-#include "ServerOptions.h"
+// #include "ServerOptions.h"  // Disabled to compile without xmlrpc-c
 #include "SyntaxOptions.h"
```

#### Change 2 - Comment out server member variable (around line 34):
```diff
   LMBR_Options            lmbr;
   ReportingOptions      output;
   OOVHandlingOptions       unk;
-  ServerOptions       server;
+  // ServerOptions       server;  // Disabled to compile without xmlrpc-c
   SyntaxOptions         syntax;
```

#### Change 3 - Comment out update function (around line 45):
```diff
-  bool update(std::map<std::string,xmlrpc_c::value>const& param);
+  // bool update(std::map<std::string,xmlrpc_c::value>const& param);  // Disabled to compile without xmlrpc-c
   bool NBestDistinct() const;
```

---

### File 3: `third-party/moses/moses2/parameters/AllOptions.cpp`

**Location:** `third-party/moses/moses2/parameters/AllOptions.cpp`

#### Change 1 - Comment out server.init (around line 34):
```diff
   if (!mbr.init(param))        return false;
   if (!lmbr.init(param))       return false;
   if (!output.init(param))     return false;
   if (!unk.init(param))        return false;
-  if (!server.init(param))     return false;
+  // if (!server.init(param))     return false;  // Disabled to compile without xmlrpc-c
   if (!syntax.init(param))     return false;
```

#### Change 2 - Comment out server.update (around line 98):
```diff
   if (!mbr.update(param))        return false;
   if (!lmbr.update(param))       return false;
   if (!output.update(param))     return false;
   if (!unk.update(param))        return false;
-  if (!server.update(param))     return false;
+  // if (!server.update(param))     return false;  // Disabled to compile without xmlrpc-c
   //if (!syntax.update(param))     return false;
```

---

### File 4: `third-party/moses/moses2/Main.h`

**Location:** `third-party/moses/moses2/Main.h`

#### Change - Comment out run_as_server declaration (around line 19):
```diff
 std::istream &GetInputStream(Moses2::Parameter &params);
 void batch_run(Moses2::Parameter &params, Moses2::System &system, Moses2::ThreadPool &pool);
-void run_as_server(Moses2::System &system);
+// void run_as_server(Moses2::System &system);  // Disabled to compile without xmlrpc-c
 
 void Temp();
```

---

### File 5: `third-party/moses/moses2/Main.cpp`

**Location:** `third-party/moses/moses2/Main.cpp`

#### Change 1 - Comment out server include (around line 9):
```diff
 #include "Phrase.h"
 #include "TranslationTask.h"
 #include "MemPoolAllocator.h"
-#include "server/Server.h"
+// #include "server/Server.h"  // Disabled to compile without xmlrpc-c
 #include "legacy/InputFileStream.h"
```

#### Change 2 - Replace server thread initialization (around line 40-52):
```diff
-  //cerr << "system.numThreads=" << system.options.server.numThreads << endl;
-
-  Moses2::ThreadPool pool(system.options.server.numThreads, system.cpuAffinityOffset, system.cpuAffinityOffsetIncr);
-  //cerr << "CREATED POOL" << endl;
-
-  if (params.GetParam("server")) {
-    std::cerr << "RUN SERVER" << std::endl;
-    run_as_server(system);
-  } else {
-    std::cerr << "RUN BATCH" << std::endl;
-    batch_run(params, system, pool);
-  }
+  //cerr << "system.numThreads=" << system.options.server.numThreads << endl;
+
+  // Server functionality disabled - get thread count from --threads parameter or use default
+  const Moses2::PARAM_VEC *vec = params.GetParam("threads");
+  int numThreads = (vec && vec->size()) ? atoi(vec->at(0).c_str()) : 1;
+  if (numThreads < 1) numThreads = 1;
+  Moses2::ThreadPool pool(numThreads, system.cpuAffinityOffset, system.cpuAffinityOffsetIncr);
+  //cerr << "CREATED POOL" << endl;
+
+  if (params.GetParam("server")) {
+    std::cerr << "ERROR: Server mode disabled in this build (no xmlrpc-c support)" << std::endl;
+    return EXIT_FAILURE;
+  } else {
+    std::cerr << "RUN BATCH" << std::endl;
+    batch_run(params, system, pool);
+  }
```

#### Change 3 - Comment out run_as_server function (around line 60-64):
```diff
 ////////////////////////////////////////////////////////////////////////////////////////////////
-void run_as_server(Moses2::System &system)
-{
-  Moses2::Server server(system.options.server, system);
-  server.run(system); // actually: don't return. see Server::run()
-}
+// Server functionality disabled to compile without xmlrpc-c
+// void run_as_server(Moses2::System &system)
+// {
+//   Moses2::Server server(system.options.server, system);
+//   server.run(system); // actually: don't return. see Server::run()
+// }
```

---

## Compilation Steps

### 1. Load Required Modules

```bash
module load gcc/11.4.0
module load boost/1.83.0
```

**Note:** If your system doesn't use environment modules, ensure gcc and boost are in your PATH and the boost path is available.

### 2. Compile Moses (including moses2)

```bash
cd third-party/moses

# If using module system with boost:
export BOOST_ROOT=/path/to/boost  # Usually set by module load

# Compile moses2 (this will take several minutes)
./bjam --with-boost=$BOOST_ROOT --no-xmlrpc-c --with-mm --with-probing-pt -j4 moses2
```

**Expected output at end:** 
```
Building Moses2 without server support
...
...updated X targets...
SUCCESS
```

### 3. Copy moses2 Binary to bin Directory

```bash
# Find the compiled binary
find . -name "moses2" -type f -executable

# It should be at: moses2/bin/gcc-11.4.0/release/link-static/threading-multi/moses2

# Copy to bin directory
cp moses2/bin/gcc-*/release/link-static/threading-multi/moses2 bin/moses2
```

---

## Verification

### 1. Check All Binaries Exist

```bash
cd /path/to/Translation-Without-Supervision/external/monoses

# Moses2
ls -lh third-party/moses/bin/moses2
third-party/moses/bin/moses2 --help | head -10

# FastAlign
ls -lh third-party/fast_align/build/fast_align
third-party/fast_align/build/fast_align 2>&1 | head -5

# Phrase2vec
ls -lh third-party/phrase2vec/word2vec
third-party/phrase2vec/word2vec 2>&1 | head -5

# ZMERT
ls -lh training/tuning/zmert/build/tune.jar
```

### 2. Verify Python Environment

```bash
source venv_pytorch04/bin/activate
python -c "import torch; print('PyTorch version:', torch.__version__)"
python -c "import editdistance; editdistance.eval('test', 'test'); print('editdistance: OK')"
python -c "import sys; sys.path.insert(0, 'third-party/fairseq'); import fairseq; print('Fairseq: OK')"
deactivate
```

### 3. Check Third-Party Python Packages

```bash
ls -d third-party/vecmap
ls -d third-party/fairseq
ls -d third-party/subword-nmt
ls -d third-party/sacrebleu
```

---

## Usage Instructions

### Running Monoses Training

```bash
cd /path/to/Translation-Without-Supervision/external/monoses

# 1. Activate Python environment
source venv_pytorch04/bin/activate

# 2. Load required modules (if using module system)
module load gcc/11.4.0
module load boost/1.83.0

# 3. Run training (example from README)
python3 train.py --src SRC.MONO.TXT --src-lang SRC \
                 --trg TRG.MONO.TXT --trg-lang TRG \
                 --working MODEL-DIR

# 4. When done, deactivate environment
deactivate
```

### Important Notes

1. **Server mode is disabled:** Do not use `--server` flag with moses2. Only batch mode is supported.

2. **Thread count:** Use `--threads N` parameter to control parallelism (default is 1 if not specified).

3. **Moses2 location:** Training scripts expect moses2 at `third-party/moses/bin/moses2`

---

## Troubleshooting

### Issue: Moses2 compilation fails with "Boost not found"

**Solution:**
```bash
# Ensure boost module is loaded
module load boost/1.83.0
echo $BOOST_ROOT  # Should show path to boost

# Or manually set BOOST_ROOT
export BOOST_ROOT=/path/to/boost
```

### Issue: Python package import errors during training

**Solution:**
```bash
# Ensure virtual environment is activated
source venv_pytorch04/bin/activate

# Verify packages are installed
pip list | grep -E "torch|editdistance"
```

### Issue: Moses2 still tries to compile server files

**Solution:**
- Double-check all modifications in `moses2/Jamfile` are correctly applied
- Ensure the `#` comments are at the start of the line (no leading spaces/tabs before `#`)
- Clean and rebuild:
```bash
cd third-party/moses
./bjam --clean
./bjam --with-boost=$BOOST_ROOT --no-xmlrpc-c --with-mm --with-probing-pt -j4 moses2
```

### Issue: "libmoses2_lib.a" errors

**Solution:**
- This usually means server source files weren't properly excluded
- Verify all changes in the Jamfile, especially the server/*.cpp lines are commented out
- Look for any references to `server/` files in build output

---

## Summary of Modified Files

All modifications are marked with comments containing: `// Disabled to compile without xmlrpc-c`

| File | Purpose | Lines Modified |
|------|---------|----------------|
| `moses2/Jamfile` | Build configuration | ~100, ~171, ~183 |
| `moses2/parameters/AllOptions.h` | Header file | ~16, ~34, ~45 |
| `moses2/parameters/AllOptions.cpp` | Implementation | ~34, ~98 |
| `moses2/Main.h` | Header file | ~19 |
| `moses2/Main.cpp` | Main program | ~9, ~40-52, ~60-64 |

**Total files modified:** 5  
**Impact:** Server functionality disabled, batch mode fully functional

---

## Additional Information

### What Was Skipped

**Moses contrib/sigtest-filter:** Not compiled because it requires external SALM toolkit. This is likely optional for the monoses workflow. If needed in the future, you would need to:
1. Download SALM from http://projectile.sv.cmu.edu/research/public/tools/salm/salm.htm
2. Compile SALM
3. Compile filter-pt with `make SALMDIR=/path/to/SALM`

### Compilation Logs

Compilation logs are saved in `third-party/moses/` directory:
- `compile_moses2_v4.log` - Final successful compilation
- `compile_fast_align.log` - FastAlign compilation
- `compile_phrase2vec.log` - Phrase2vec compilation

---

## Contact & Support

If you encounter issues not covered in this guide:

1. Check the detailed summary at `third_party_setup_summary.txt`
2. Review compilation logs in `third-party/moses/compile_*.log`
3. Consult the original Moses documentation at http://www.statmt.org/moses/

**Last Updated:** November 4, 2025

