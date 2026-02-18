markdown
**Panorama CGRA**

**Document by :-**

(Abhishek Neogi, PhD Scholar IIT Guwahati under the guidance of Prof. Dr. Satyajit Das)

**Panorama** is a fast and scalable compiler designed to map complex loop kernels onto CGRAs. It uses a "divide-and-conquer" approach by partitioning a large **Data-Flow Graph (DFG)** into smaller clusters using spectral clustering, which are then mapped onto physical Processing Element (PE) clusters.

RS Paper : [https://dl.acm.org/doi/10.1145/3489517.3530429](https://dl.acm.org/doi/10.1145/3489517.3530429)

### 1. File Directory Structure

The repository is typically organized as follows:

*   **src/**: Contains the core Python logic for DFG clustering (`dfg_clustering.py`), ILP mapping (`cluster_mapping.py`), and the entry script (`run_example.py`).
*   **data/**: Stores input benchmarks (like the edn DFG).
*   **data/results/**: The output directory where the compiler saves generated DFG images (`.png`), graph files (`.gexf`, `.dot`), and mapping results.

### 2. Required Packages & Environment

To avoid "dependency hell" between modern visualization tools and the older math logic in Panorama, use these specific versions.

| **Package** | **Version** | **Installation Command** |
| :---: | :---: | :---: |
| **Python** | 3.8+ | `sudo apt install python3 python-is-python3` |
| **NumPy** | 1.22.x | `pip install "numpy>=1.20,<1.24"` |
| **NetworkX** | 2.8.x | `pip install "networkx<3.0"` |
| **Scikit-Learn** | Latest | `pip install scikit-learn` |
| **Matplotlib** | Latest | `pip install matplotlib` |
| **Pydot** | Latest | `pip install pydot` |
| **Graphviz** | System | `sudo apt install graphviz` |
| **Gurobi** | 11.0+ | `pip install gurobipy` (Requires academic license) |

### 3. Step-by-Step Installation & Fixes

**Step 1: System Preparation**

Ensure your system recognizes `python3` as the default `python` command.

```bash
sudo apt update
sudo apt install python-is-python3 graphviz build-essential

````

**Step 2: Install Python Libraries**

Install the stack, ensuring **NetworkX** is downgraded to avoid the "decorator" and "to\_numpy\_matrix" errors.

``` bash
pip install "numpy>=1.20" "networkx<3.0" scikit-learn matplotlib pydot gurobipy

```

**Step 3: Source Code Patching (Critical)**

Because you are using modern NumPy, you must fix the `np.matrix` error manually.

1.  Open `src/dfg_clustering.py`.
2.  **Fix 1:** Add `import numpy as np` at the very top of the file.
3.  **Fix 2:** Change `adj_mat_dfg = nx.to_numpy_matrix(G)` to `adj_mat_dfg = nx.to_numpy_array(G)`.
4.  **Fix 3:** Wrap the fit call: change `scdfg.fit(adj_mat_dfg)` to `scdfg.fit(np.asarray(adj_mat_dfg))`.

**Step 4: Gurobi Path Configuration**

If `gurobipy` is not found, add these lines to your `~/.bashrc5`:

``` bash
export GUROBI_HOME="/opt/gurobi/linux64"
export PATH="${PATH}:${GUROBI_HOME}/bin"
export LD_LIBRARY_PATH="${LD_LIBRARY_PATH}:${GUROBI_HOME}/lib"
export PYTHONPATH="${PYTHONPATH}:${GUROBI_HOME}/lib/python3.8/site-packages"

```

*Run `source ~/.bashrc` to apply.*

### 4\. Troubleshooting Log

| **Error Encountered**                   | **Cause**                                                            | **Solution**                                                                              |
| :-------------------------------------: | :------------------------------------------------------------------: | :---------------------------------------------------------------------------------------: |
| `TypeError: np.matrix is not supported` | NumPy 1.20+ deprecated `np.matrix`.                                  | Change `to_numpy_matrix` to `to_numpy_array` and use `np.asarray()` in the `.fit()` call. |
| `FileNotFoundError: cdfg.gexf`          | The first stage (clustering) crashed, so the file was never saved.   | Fixing the NumPy error allows the script to finish and save the file.                     |
| `bash: !: event not found`              | Bash interprets `!` as a history command.                            | Avoid `!` in terminal strings or use single quotes: `'Gurobi is visible'`.                |
| `Model is infeasible`                   | Constraints (like nodes per cluster) are too tight for the DFG size. | Increase CGRA size (e.g., use `8 8` instead of `4 4`) or reduce the cluster count.        |
| **Terminal Hanging**                    | Gurobi is performing an exhaustive search on a complex DFG.          | Set a time limit in `cluster_mapping.py`: `m.Params.TimeLimit = 60`.                      |

### 5\. How to Run

  * **To run the standard benchmark on a 4x4 CGRA with 10 clusters:**
    
    Go to Bash
    
    `cd Panorama-CGRA/src`
    
    Then `$ python dfg_clustering.py <path_to_xml> <num_clusters> <affinity_type>`
    
    (`python dfg_clustering.py ../data/morpher_dfgs/edn/jpegdct_POST_LN111_PartPred_DFG_forclustering.xml 10 precomputed`)
    
    Automated command given : `python run_example.py edn 10 1 1 4 4`

  * Check `data/results/` for the generated DFG images and mapping logs and `cdfg.gexf` file.

  * Now copy the `.cdfg` file to `src` folder for mapping.
    
    Run `$ python cluster_mapping.py <C1> <C2> <Rows> <Cols>`
    
    `$ python cluster_mapping.py 1 1 4 4`
    
    **Model Infeasible Error :** If model is infeasible then inc the size of CGRA but not much.

**Terms to understand :**

  * **What is Clustering (`num_clusters`)?**
    
    Clustering is the "Divide and Conquer" step. Mapping 461 nodes (like in your K-means DFG) onto a CGRA all at once is mathematically too hard for a computer to solve quickly.
    
      * **The Goal:** The compiler groups related operations together into "clusters".
      * **Argument:** The `num_clusters` argument (e.g., 10) tells the tool how many groups to create.
      * **The Trade-off:**
          * Fewer Clusters: Makes mapping easier but might overcrowd a single PE.
          * **More Clusters: Spreads the work out but increases "routing cost" (the distance data must travel between clusters).**

  * **What is C1 and C2**: These are "weights" for the Gurobi solver.
    
      * **C1**: Usually represents the importance of minimizing the **routing distance** between PEs.
      * **C2**: Usually represents the importance of minimizing the **total execution time** (latency).
      * Using `1 1` tells the tool to treat both goals as equally important.

  * **What is Affinity (`affinity_type`)?**
    
    "Affinity" is a mathematical term used in **Spectral Clustering** to describe how "close" or "related" two nodes are in the graph.
    
      * **precomputed**: This is the default argument you use. It tells the script to build its own "Affinity Matrix" based directly on the connections in your DFG. If Node A sends data to Node B, they have high affinity and should stay in the same cluster.
      * **Other Types**: Types like `nearest_neighbors` use different math to decide which nodes belong together, which can sometimes fix the "Infeasible" errors if the default clustering is poorly balanced.

**Program Flow :**

**Morpher (Frontend):** C Code —\> XML DFG.

**PANORAMA (Backend):** XML DFG —\> Clustered DFG —\> Physical Mapping

**MORPHER**

**DOWNLOAD SRC FOLDER :** [Panorama CGRA](https://drive.google.com/drive/folders/12LSxxAGlrtYthGS9-xMyiLMxNXAIfKng?usp=sharing)

**(If you Morpher\_Generator in src directory is empty)**

**Downloading the full project (Morpher) including nested submodules require cloning of remaining submodules from github.** A standard `git clone` leaves submodule folders (like Morpher\_DFG\_Generator) empty; the recursive flag ensures all components are downloaded.

``` bash
$ cd ~/panorama
$ git submodule update --init --recursive

```

Then you will get to see many directories inside it. Now we need to build the Morpher. Morpher requires specific headers to compile C code into LLVM IR and the JSON library to structure the DFG data.

**NOTE : Must Read the README file \!\!\!\!**

``` bash
# Install JSON library for DFG generation
$ sudo apt update
$ sudo apt install nlohmann-json3-dev
$ clang --version # (clang should be of version 10)

# Install multiarch headers to fix "bits/libc-header-start.h not found" error while
$ sudo apt install gcc-multilib g++-multilib

```

**Now Building the Morpher :**

``` bash
$ cd ~/panorama/src/panorama_with_morpher/Morpher_DFG_Generator
$ mkdir -p build && cd build
$ cmake ..
$ make all

```

Go inside `$ cd benchmarks/morpher_benchmarks`

Now while executing **array\_add.c** program (in testbench file) using command from Morpher\_DFG\_Generator directory

**`$ ./run_pass.sh benchmarks/morpher_benchmarks/array_add/array_add array_add`**

**(Note**: DO NOT WRITE .C AS EXTENSION OF C FILE. Replace main with the exact name of the function in `array_add.c` that contains the loop you wish to map.)

**Error Faced**: `libSkeletonPass.so: cannot open shared object file.`

  * **Resolution**: This occurred because the build produced `libdfggenPass.so` instead of `libSkeletonPass.so`. The solution was to update the `run_pass.sh` script to point to the correct file in `build/src/`.

The file name is actually :- “ `libdfggenPass.so` ” instead of `libSkeletion.so` in `build/src`.

Hence we need to change path in `run_pass.sh`

**Updated run\_pass.sh :**

``` bash
clang -D CGRA_COMPILER -target i386-unknown-linux-gnu -c -emit-llvm -O2 -fno-tree-vectorize -fno-inline -fno-unroll-loops $1.c -S -o $1.ll
opt -gvn -mem2reg -memdep -memcpyopt -lcssa -loop-simplify -licm -loop-deletion -indvars -simplifycfg -mergereturn -indvars $1.ll -o $1_gvn.ll
#opt -load ~/manycore/cgra_dfg/buildeclipse/skeleton/libSkeletonPass.so -fn $1 -ln $2 -ii $3 -skeleton integer_fft_gvn.ll -S -o integer_fft_gvn_instrument.ll
opt -load ./build/src/libdfggenPass.so -fn $2 -skeleton $1_gvn.ll -S -o $1_gvn_instrument.ll -nobanks ${3:-2}  -banksize ${4:-2048}
clang -target i386-unknown-linux-gnu -c -emit-llvm -S ./src/instrumentation/instrumentation.cpp -o instrumentation.ll
#-------------------------------------------------------------------------#
#run_pass will automatically run the fix_xml.py file
# Identify the generated XML file name
# Note: Based on your pass logic, it is typically [application]_PartPredDFG.xml
GENERATED_XML="${2}_PartPredDFG.xml"
# Step 1: Trigger the fix script
if [ -f "$GENERATED_XML" ]; then
    echo "Fixing XML bugs for $GENERATED_XML..."
    python3 fix_xml.py "$GENERATED_XML"
else
    echo "Error: $GENERATED_XML not found, skipping fix."
fi

```

(Do not change the flag “`-skeleton`” , as the `src/dfggenPass.cpp` expects flag as `-skeleton` and not `dfggen`)

Make sure to make `run_pass.sh` executable (precaution):
`$ cd ~/panorama/src/panorama_with_morpher/Morpher_DFG_Generator`
`$ chmod +x run_pass.sh`

After doing, you can execute `array_add.c` program using the command :
**`$ ./run_pass.sh benchmarks/morpher_benchmarks/array_add/array_add array_add`**

Expected output :
IT SHOULD COUNT DFG NODE COUNT.

Now you will see many files have been created in `Morpher_DFG_Generator`. Go to `.xml` file and check the xml file.

Also check the `.dot` file using the command `xdot <filename.dot>`

  * **\*\*If the .xml file opens (in browser) successfully then congratulations 🎉🎉🎉, half of the job is done \!\!\*\***
    
    Then **create a new directory inside `/panorama/data/morpher_dfgs`** name it anything as it will be required while mapping using
    
    `$ python run_example.py array_add 4 1 1 4 4`

  * **\*\*If the .xml file is producing an error while opening, then things are there to worry about.\*\***
    
    **Faulty .xml File**
    Expected faults like :
    
    .XML file contains a code snippet. Here the error is after ALAP argument, there is no space given for BB, and similarly no space between BB and Const. Which does create problem.
    
    ``` xml
    </MutexBB>
     10 <DFG count="20">
     11 <Node idx="11" ASAP="0" ALAP="0"BB=""CONST="4094">
     12 <OP>LOADB</OP>
     13 <BasePointerName size="1">loopstart</BasePointerName>
     14 <Inputs>
    
    ```
    
    If you see a section named `<mutex>` then xml file need some correction. Remove that section using the `fix_xml.py` python script given below. (NOTE: WE WILL HAVE TO INCLUDE `<mutex>` later on)
    
    Also some tags are not properly opened and closed, which creates this type of error :
    
    **ERROR : This page contains the following errors:**
    `error on line 101 at column 11: Opening and ending tag mismatch: Node line 97 and Outputs`
    
    **Below is a rendering of the page up to the first error.**
    
    Hence the solution of all these problems is to edit then xml generation file or just patch the output xml file using a python script in regular expression.
    
    [fix\_xml.py script](https://drive.google.com/file/d/1DVkdUehERDwP9NtNE6fdvE7ffPjTOE5V/view?usp=sharing)
    
    Command to run : `$ python3 fix_xml <xml_filename>`
    
    Expected output : you should see a file with suffix as `....*fixed.xml`

**Map a XML file :**

Congratulations 🎉 that you have come so far. Generating a successful xml file is a great milestone ⛰️.

Now we will map this xml file. To do it using `run_pass.sh` script

**`./run_pass.sh benchmarks/morpher_benchmarks/array_add/array_add array_add`**

Src folder : [Panorama CGRA](https://drive.google.com/drive/folders/12LSxxAGlrtYthGS9-xMyiLMxNXAIfKng?usp=sharing)

Download the above folder

This documentation summarizes the debugging process and specific code patches applied to integrate the **Panorama framework** with the **Morpher CGRA Mapper**.

**Running the morpher using run\_panorama\_with\_morpher.py**

First go to `Morpher_CGRA_Mapper` directory :

`cd ~/panorama/src/panorama_with_morpher/Morpher_CGRA_Mapper$`

Then check if there is any `build` folder available, if yes you can proceed to execute `run_panorama_with_morpher.py`. Else we have to first build the `Morpher_CGRA_Mapper`.

**1) Building the mapper directories :**

``` bash
mkdir -p build && cd build
cmake ..
# (After applying cmake, make sure you have all the requirements completed before make)
make

```

**2) Correcting run\_panorama\_with\_morpher.py file :**

**2.1)** Focus on variable `DFG_GEN_HOME` and `MAPPER_HOME`

Now scroll down to line 45-47 something….

Make sure its `os.chdir(DFG_GEN_HOME)` and not `DGF_GEN_KERNEL`, else it will throw an error.

**2.2)** Come to if else part, in “else” section it should correctly get the benchmarks file according to the application you want to run. It should be :-

(NOTE :- THESE ARE PYTHON SCRIPTS, CAREFUL IN INDENTATION)

``` python
else………….
benchmark_path = 'benchmarks/morpher_benchmarks/' + application + '/' + application
os.system('./run_pass.sh %s %s' % (benchmark_path, target_function))

  #USE THE FIXED XML FILE :-
  mapper_xml = application + '_PartPredDFG_mapper_ready.xml'
#else section ends here
cluster_xml = application + '_PartPredDFG_cluster_ready.xml'

if os.path.exists(mapper_xml) and os.path.exists(cluster_xml):
  # Use the CLUSTER-READY file for the clustering step
  os.system('cp ' + cluster_xml + ' ' + RESULTS_PWD + 'DFG_forclustering.xml')
  # Use the MAPPER-READY file for the final mapping step
  os.system('cp ' + mapper_xml + ' ' + RESULTS_PWD + 'DFG.xml')
else:
  print("Error: Fixed XML files were not generated!")
  sys.exit(1)

```

**2.3) Change the build path in “Running Morpher\_CGRA\_Mapper” section**

Nearly line \~90

``` python
os.chdir(RESULTS_PWD)
.
.
.
os.system(MAPPER_HOME+'/build/src/cgra_xml_mapper -m %s -d DFG.xml -j %s -s %s -l %s -u %s -a %s -i %s -w %s -v %s > log.txt ' % (maxIter,MAPPER_HOME+'/json_arch/clustered_archs/'+arch_desc, skip_inter_or_intra, open_set_limit,RESULTS_PWD+'../'+summary_log, entry_id, initII, maxIterTime, RESULTS_PWD+'compact_summary.log'))

```

**Here in original code, there will be a different name used instead of build (ending with \_spr). So edit that long name, and make it “/build/”**

**2.4) Remove “&” character in above code snippet before \> log.txt**

If this ‘**&**’ symbol is not removed then the process gets forcefully terminate the ILP mapping process. Hence producing an error.

**Tried to run using the following common :**

``` bash
python run_panorama_with_morpher.py \
  array_add \
  array_add \
  precomputed \
  4 1 1 2 2 \
  stdnoc_2x2tiles_2x2PEs.json \
  1000 0 100 1 \
  summary.log \
  1 600

```

### 1\. Architecture Port Definition Patch

**Issue: Port Mismatch Assertion**

The mapper crashed with `Assertion 'false' failed at Module.cpp:491`. The DFG required ports I1, I2, and P, but the hardware JSON lacked these specific virtual names.

**Solution: JSON Update**

**Location:** \`\~/panorama/src/panorama\_with\_morpher/Morpher\_CGRA\_Mapper/json\_arch/clustered\_arch

