# HighPerformance_computing (CPU and GPU) NVDIA
## Cosmic Dark Matter
### 2-Point Angular Correlation

#### The calculation of three histograms of the 2-point angular correlation function for two sets of galaxies
### Input Data 
#### Two lists of N galaxy locations: real measured galaxies and synthetic evenly distributed random galaxies galactic coordinates
#### For each galaxy, real or synthetic, the list contains the galactic coordinates
     - right ascension a, in arc minutes
     - declination d, in arc minutes
#### Instructions On how to run the program
  - Compile the program using nvdia cuda
  - nvcc --gpu-architecture=sm_70 --ptxas-options=-v prog.cu -o prog -lm
  
## Final Result
To see through the ploted histogram if there are any visible differences.

The scientific measure for differences between the distributions of two equally big sets of galaxies is
   Omega(ith)(theta) = (DD(ith) - 2*DR(ith) + RR(ith))/RR(ith)
   DD(ith), DR(ith) , RR(ith) = value in histogram bin(ith)
   
   - If the omega(ith) values are closer to zero than one, in the range [-0.5,0.5], 
     then we have a random distribution of real galaxies.
   - If the Omega(ith) values are different from zero on the scale of one,
     then we have a non-random distribution of real galaxies
