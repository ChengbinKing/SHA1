#include"Common1.h"
#include"cuda.h"
#include"time.h"
#include"device_launch_parameters.h"
#include"stdio.h"
#include<string>
#include"cuda_runtime.h"
#include"malloc.h"
#include<openssl\sha.h>
#include<openssl\bn.h>
#pragma comment(lib, "libeay32.lib")
#pragma comment(lib, "ssleay32.lib")
#define MAX_THREADS_PER_BLOCK 1
int main() {
	
	int n;
	printf("Please set the number of inputs\n");
	scanf("%d", &n);
	printf("Then you need to input the message\n");
	int*ilen1 = (int*)malloc(sizeof(int) * n);
	unsigned char**input = (unsigned char**)malloc(sizeof(unsigned char*) * n);
	unsigned char**hash = (unsigned char**)malloc(sizeof(unsigned char*)*n);
	char**INPUT = (char**)malloc(sizeof(char*)*n);
	for (int i = 0; i < n; i++) {
		input[i] = (unsigned char*)malloc(sizeof(unsigned char) * 512);
		hash[i] = (unsigned char*)malloc(sizeof(unsigned char) * 512);
		INPUT[i] = (char*)malloc(sizeof(char) * 1000);
	}
	BIGNUM*A = BN_new();
	printf("Random Data is preparing:\n");
	for (int i = 0; i < n; i++) {
		//scanf("%s", INPUT[i]);
		BN_rand(A, 512, 1, 0);
		INPUT[i]= BN_bn2hex(A);
		ilen1[i] = strlen(INPUT[i]);
		input[i] = (unsigned char*)INPUT[i];
		printf("%s\n", INPUT[i]);
	}
	BN_free(A);
	clock_t start1, finish1;
	float costtime;
	start1 = clock();
	for (int i = 0; i < n; i++) {
		SHA1(input[i], ilen1[i], hash[i]);
	}
	finish1 = clock();
	costtime = (float)(finish1 - start1);
	printf("OpenSSL run time %f ms\n", costtime);
	printf("OpenSSL results:\n");
	//multisha1_gpu(input, ilen1, hash,n);
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < 20; j++) {
			printf("%02x", hash[i][j]);
		}
		printf("\n");
	}
	cudaEvent_t start, stop;
	float costtime4 = 0.0;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);
	multisha1_gpu(input, ilen1, hash, n);
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&costtime4, start, stop);
	printf("GPU need time is %f ms\n", costtime4);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	printf("GPU Result:\n");
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < 20; j++) {
			printf("%02x", hash[i][j]);
		}
		printf("\n");
	}
	printf("OK\n");
	return 0;
}
