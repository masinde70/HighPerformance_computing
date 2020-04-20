/*
 1.Input Data
 2.What Need to be calculated
 3.Design your threads and thread blocks
 4. Implementation on CPU and GPU
 5. Built in check points
 6. Output data
 */

 #include<stdio.h>
 #include<stdlib.h>
 #include<string.h>
 #include<math.h>
 #include<cuda.h>
 #include<cuda_runtime.h>
 #include<time.h>

 #define NumberOfELements 100000
 #define PI 3.14159265

#define CHECK(call) \
{ \
 const cudaError_t error = call; \
 if (error != cudaSuccess) \
 { \
 printf("Error: %s:%d, ", __FILE__, __LINE__); \
 printf("code:%d, reason: %s\n", error, cudaGetErrorString(error)); \
 exit(1); \
 } \
}


int line_length(FILE *input_file){
    char read_lines[100];
    int total_lines = 0;
    while(fgets(read_lines, 100, input_file) != NULL) total_lines++;
        rewind(input_file);
      return(total_lines);
}

void get_data(FILE *input_file, int n_lines, float *asc, float *decl){
     char read_lines[100];
     float right_asc, declin;
     int i=0;
      while(fgets(read_lines, 100, input_file) != NULL){
       sscanf(read_lines, "%f  %f", &right_asc, &declin);
               asc[i] = right_asc * PI/ (60 * 180);
               decl[i] = declin * PI/ (60 * 180);
               ++i;
       }

    fclose(input_file);
  }

  __global__ void histogram_calc(float *rt_rl, float *decn_rl,  float *rt_syc, float *decn_syc, float pi, unsigned long long int *histogram){
           float galxs_rdns;
           float galxs_dgrs;
           int index  = blockIdx.x * blockDim.x + threadIdx.x;

         if( index < NumberOfELements)
            for( int i = 0; i < NumberOfELements; ++i){
               galxs_rdns =  acos(sin(decn_rl[index]) * sin(decn_syc[i]) + cos(decn_rl[index]) * cos(decn_syc[i]) * cos(rt_rl[index] - rt_syc[i]));
               galxs_dgrs = galxs_rdns * (180 /pi);
             // histogram[(int)(galxs_dgrs*4)] = (histogram[(int)(galxs_dgrs*4)] + 1);
                atomicAdd(&histogram[(int)(galxs_dgrs*4)], 1);
               __syncthreads();
          }
}

int  main(int argc, char *argv[]) {
     FILE *input_file, *output_file;
     unsigned long long int *DD, *DR, *RR;
     int total_lines_r, total_lines_s;
     float *right_ascension_real, *declination_real, *right_ascension_synthetic, *declination_synthetic;
     long int sum_DD, sum_DR, sum_RR;
     float *d_DC, *d_DR, *d_RR, *d_RC;
     double omg = 0.00;
     int bin_width = 4;
     int degrees = 180;
     int num_of_bins =
        num_of_bins =  bin_width * degrees;

     time_t start, stop;


      /* Check that we have 4 command line arguments */
       if ( argc != 4 ) {
          printf("Usage: %s real_data synthetic_data output_file\n", argv[0]);
          return(0);
         }

        start = clock();

        //open real data file
         input_file = fopen(argv[1], "r");
         if (input_file == NULL){
                printf("file does not exist%s\n", argv[1]);
                return 0;
         }

        // count lines in a real file
        total_lines_r = line_length(input_file);
        //printf("%s contains %d lines\n", argv[1],  total_lines_r);

        //alocate memory for real data on host
         right_ascension_real = (float *)calloc(total_lines_r, sizeof(float));
         declination_real =  (float *)calloc(total_lines_r, sizeof(float));

         //get data
         get_data(input_file, total_lines_r, right_ascension_real, declination_real);
        //open synthetic data
        input_file = fopen(argv[2], "r");
        if (input_file == NULL){
              printf("file does not exist%s\n", argv[2]);
              return 0;
         }
         //count lines in sysnthetic file
        total_lines_s = line_length(input_file);

        // printf("%s contains %d lines\n", argv[2], total_lines_s);

         //alocate memory for the sysnthetic data on host
         right_ascension_synthetic = (float *)calloc(total_lines_s, sizeof(float));
         declination_synthetic = (float *)calloc(total_lines_s, sizeof(float));

         //get second data
        get_data(input_file, total_lines_s,right_ascension_synthetic, declination_synthetic);

        // where data is stored
        long int *host_DD;
        long int *host_DR;
        long int *host_RR;

        //Alocate memory for the host
         host_DD = (long int *)malloc((num_of_bins+1)  * sizeof(long int));
         host_DR = (long int *)malloc((num_of_bins+1) * sizeof(long int));
         host_RR = (long int *)malloc((num_of_bins+1) * sizeof(long int));
         for (int i = 0; i <= num_of_bins; ++i ) {
              host_DD[i] = 0L;
              host_DR[i] = 0L;
              host_RR[i] = 0L;
            }

        //Allocate device memory
        cudaMalloc((void **)&DD, (NumberOfELements+1)  * sizeof(unsigned long long int));
        cudaMalloc((void **)&DR, (NumberOfELements+1)  * sizeof(unsigned long long int));
        cudaMalloc((void **)&RR, (NumberOfELements+1)  * sizeof(unsigned long long int));

        cudaMalloc((void **)&d_DR, (NumberOfELements+1) * sizeof(float));
        cudaMalloc((void **)&d_DC, (NumberOfELements+1) * sizeof(float));
        cudaMalloc((void **)&d_RR, (NumberOfELements+1) * sizeof(float));
        cudaMalloc((void **)&d_RC, (NumberOfELements+1) * sizeof(float));

         //copy the data from host memory  to device memory
         cudaMemcpy(d_DR, right_ascension_real, (NumberOfELements) * sizeof(float), cudaMemcpyHostToDevice);
         cudaMemcpy(d_DC, declination_real, (NumberOfELements) * sizeof(float), cudaMemcpyHostToDevice);
         cudaMemcpy(d_RR, right_ascension_synthetic, (NumberOfELements) * sizeof(float), cudaMemcpyHostToDevice);
         cudaMemcpy(d_RC, declination_synthetic, (NumberOfELements) * sizeof(float), cudaMemcpyHostToDevice);


         //Lauch  the kernel for DD
          int blockSize = 256;
          int numBlocks = ((NumberOfELements -1) + blockSize - 1) / blockSize;
          histogram_calc <<<numBlocks, blockSize>>>(d_DR, d_DC, d_DR, d_DC,PI, DD);
          cudaDeviceSynchronize();
          //copy the results back to the host
          cudaMemcpy(host_DD, DD, num_of_bins * sizeof(long int), cudaMemcpyDeviceToHost);

          sum_DD = 0L;
          for (int i = 0; i <= (num_of_bins); ++i )
                sum_DD += host_DD[i];
            printf("histograms DD = %ld\n", sum_DD);


         //Lauch  the kernel DR
          histogram_calc <<<numBlocks, blockSize>>>(d_DR, d_DC, d_RR, d_RC,PI, DR);
          cudaDeviceSynchronize();
          //copy the results back to the host
          cudaMemcpy(host_DR, DR, num_of_bins * sizeof(long int), cudaMemcpyDeviceToHost);

          sum_DR = 0L;
          for (int i = 0; i <= num_of_bins; ++i )
                sum_DR += host_DR[i];
             printf("histograms DR = %ld\n", sum_DR);

          //Lauch  the kernel RR
          histogram_calc <<<numBlocks, blockSize>>>(d_RR, d_RC, d_RR, d_RC, PI, RR);
          //copy the results back to the host
          cudaMemcpy(host_RR, RR, num_of_bins * sizeof(long int), cudaMemcpyDeviceToHost);

          sum_RR = 0L;
          for (int i = 0; i <= num_of_bins; ++i )
                sum_RR += host_RR[i];
            printf("histograms RR = %ld\n", sum_RR);


        /* Open the output file */
        output_file = fopen(argv[3],"w");
        if ( output_file == NULL ) {
                printf("Unable to open %s\n",argv[3]);
                return(-1);
        }

       for(int i = 0; i < num_of_bins; ++i){
         if (host_RR[i] > 0 ) {
         omg = ((double)host_DD[i]/(double)(host_RR[i])) - ((2.0*host_DR[i])/(double)(host_RR[i])) + ((double)host_RR[i]/(double)(host_RR[i]));
        // omg = (double)((host_DD[i] - 2*host_DR[i] + host_RR[i])/host_RR[i]);
         printf("Omega = %6.3f\n", omg);
         fprintf(output_file, "%6.3f\n", omg);
          }
        }

        fclose(output_file);

        free(right_ascension_synthetic);
        free(declination_synthetic);
        free(right_ascension_real);
        free(declination_real);

        free(host_DD);
        free(host_DR);
        free(host_RR);

        cudaFree(DD);
        cudaFree(DR);
        cudaFree(RR);

        cudaFree(d_RR);
        cudaFree(d_RC);
        cudaFree(d_DR);
        cudaFree(d_DC);

        stop = clock();
        printf("\nExcution time = %6.1f seconds\n",
        ((double) (stop-start))/ CLOCKS_PER_SEC);
        return (0);
}
