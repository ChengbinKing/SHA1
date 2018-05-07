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

int main(void) {

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
	clock_t start3, finish3;
	float costtime3;
	start3= clock();
	gpu_sha1((unsigned char*)a, strlen(a), hash);
	finish3 = clock();
	costtime3 = (float)(finish3 - start3) / CLOCKS_PER_SEC;
	printf("CPU run time %f seconds\n", costtime3);
	printf("GPU2 execute result:\n");
	for (int i = 0; i < 20; i++) printf("%02x ", hash[i]);
	printf("\n");
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
