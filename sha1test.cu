#include"Common1.h"
#include"cuda.h"
#include"time.h"
#include"device_launch_parameters.h"
#include"stdio.h"
#include<string>
#include"cuda_runtime.h"
#include"malloc.h"
#include"sha.h"
#pragma comment(lib, "libeay32.lib")
#pragma comment(lib, "ssleay32.lib")
#define MAX_THREADS_PER_BLOCK 1
void in1() {
	printf("You need to input your data,first!\n");
	char*a = (char*)malloc(5000*sizeof(char));
	scanf("%s", a);
	unsigned char hash[20];
	clock_t start1, finish1;
	float costtime;
	start1 = clock();
	sha1_cpu((unsigned char*)a, strlen(a), hash);
	finish1 = clock();
	costtime = (float)(finish1 - start1)/CLOCKS_PER_SEC;
	printf("CPU run time %f seconds\n", costtime);
	printf("CPU execute result:\n");
	for (int i = 0; i < 20; i++) printf("%02x ",hash[i]);
	printf("\n");
	cudaEvent_t start, stop;
	float costtime4 = 0.0;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);
	cudaEventRecord(start, 0);
	sha1_gpu_global1((unsigned char*)a, strlen(a), hash, MAX_THREADS_PER_BLOCK);
	cudaEventRecord(stop, 0);
	cudaEventSynchronize(stop);
	cudaEventElapsedTime(&costtime4, start, stop);
	printf("GPU need time is %f seconds\n", costtime4 /1000);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);
	printf("GPU execute result:\n");
	for (int i = 0; i < 20; i++) printf("%02x ", hash[i]);
	printf("\n");
	/*clock_t start3, finish3;
	float costtime3;
	start3= clock();
	gpu_sha1((unsigned char*)a, strlen(a), hash);
	finish3 = clock();
	costtime3 = (float)(finish3 - start3) / CLOCKS_PER_SEC;
	printf("CPU run time %f seconds\n", costtime3);
	printf("GPU2 execute result:\n");
	for (int i = 0; i < 20; i++) printf("%02x ", hash[i]);
	printf("\n");*/
	clock_t start2, finish2;
	float costtime2;
	start2 = clock();//unsigned char*
	SHA1((unsigned char*)a, strlen(a), hash);
	//SHA1(b,64,hash);
	finish2 = clock();
	costtime2 = (float)(finish2 - start2) / CLOCKS_PER_SEC;
	printf("OpenSSL run time %f seconds\n", costtime2);
	printf("OpenSSL execute result:\n");
	for (int i = 0; i < 20; i++) printf("%02x ", hash[i]);
	printf("\n");
}
int main() {
	printf("You need to input your data,first!\n");
	int n = 5;
	int*ilen1 = (int*)malloc(sizeof(int) * n);
	unsigned char**input = (unsigned char**)malloc(sizeof(unsigned char*) * n);
	unsigned char**hash = (unsigned char**)malloc(sizeof(unsigned char*)*n);
	char**INPUT = (char**)malloc(sizeof(char*)*n);
	for (int i = 0; i < n; i++) {
		input[i] = (unsigned char*)malloc(sizeof(unsigned char) * 512);
		hash[i] = (unsigned char*)malloc(sizeof(unsigned char) * 512);
		INPUT[i] = (char*)malloc(sizeof(char) * 1000);
	}
	for (int i = 0; i < n; i++) {
		scanf("%s", INPUT[i]);
		ilen1[i] = strlen(INPUT[i]);
		input[i] = (unsigned char*)INPUT[i];
	}
	for (int i = 0; i < n; i++) {
		sha1_cpu(input[i], ilen1[i], hash[i]);
	}
	//multisha1_gpu(input, ilen1, hash,n);
	for (int i = 0; i < n; i++) {
		for (int j = 0; j < 20; j++) {
			printf("%02x", hash[i][j]);
		}
		printf("\n");
	}
	multisha1_gpu(input, ilen1, hash, n);

	for (int i = 0; i < n; i++) {
		for (int j = 0; j < 20; j++) {
			printf("%02x", hash[i][j]);
		}
		printf("\n");
	}
	printf("OK\n");
	return 0;
}
