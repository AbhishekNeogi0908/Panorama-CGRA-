# arguments: application,target_function,cluster_algo,no_clusters,C1_init, C2_init,cgra_cluster_r, cgra_cluster_c,arch_desc, maxIter,skip_inter_or_intra, open_set_limit, entry_id,summary_log, initII,maxIterTime
# python -u run_panorama_with_morpher.py edn jpegdct metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 101 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py idctcols idctCols metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py idctrows idctRows metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py conv2D convolution2d metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py matched_filter corrFilter_1 metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py matrix_multiply matrix_multiply metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py cordic cordic metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py kmeans kmeans_01 metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py fir fir_filter metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py jpegfdct jpeg_fdct_islow metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6
# python -u run_panorama_with_morpher.py invertmat invert_matrix_general metis 9 2 2 3 3 stdnoc_3x3tiles_3x3PEs_8REGS_4PORTS_NW1.json 30 NO 0 201 pano_results.csv 0 6

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
