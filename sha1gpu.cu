#include"time.h"
#include <string.h>
#include <stdio.h>
#include "Common.h"
#include"cuda.h"
#include"device_launch_parameters.h"
#include <iostream>
#include <fstream>
#include<cuda_runtime.h>
#include<openssl\bn.h>
#include<openssl\sha.h>
#include"malloc.h"
#pragma comment(lib, "libeay32.lib")
#pragma comment(lib, "ssleay32.lib")
using namespace std;
class sha1gpu {
public:
	unsigned char block[64];
};
class Hash {
public:
	unsigned char hash[20];
};
#define SHA1CircularShift(bits,word) \
                ((((word) << (bits)) & 0xFFFFFFFF) | \
                ((word) >> (32-(bits))))

typedef struct {
	unsigned long total[2];     /* number of bytes processed  */
	unsigned long state[5];     /* intermediate digest state  */
	unsigned char buffer[64];   /* data block being processed */
} sha1_gpu1_context;


__constant__ static const unsigned char sha1_padding[64] =
{
	0x80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
	0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
};


/*
* Prepare SHA-1 for execution.
*/
__device__ void sha1_cpu_starts(sha1_gpu1_context* ctx)
{
	ctx->total[0] = 0;
	ctx->total[1] = 0;
	ctx->state[0] = 0x67452301;
	ctx->state[1] = 0xEFCDAB89;
	ctx->state[2] = 0x98BADCFE;
	ctx->state[3] = 0x10325476;
	ctx->state[4] = 0xC3D2E1F0;
}
__device__ unsigned long K[] =
{
	0x5A827999,
	0x6ED9EBA1,
	0x8F1BBCDC,
	0xCA62C1D6
};
__device__ static void sha1_cpu_upfoldprocess(sha1_gpu1_context *ctx, unsigned char data[64]) {
	
	int  t;                  /* Loop counter                 */
	unsigned long temp;               /* Temporary word value         */
	unsigned long W[80];              /* Word sequence                */
	unsigned long A, B, C, D, E;      /* Word buffers                 */
	A = ctx->state[0];
	B = ctx->state[1];
	C = ctx->state[2];
	D = ctx->state[3];
	E = ctx->state[4];
	unsigned long L1, L2;
	for (t = 1; t < 20; t = t + 2)
	{
	L1 = ((B&C)|((~B)&D))+E;
	L2 = ((A & SHA1CircularShift(30, B)) | ((~A) & C)) + D;
	E = C;
	D = SHA1CircularShift(30, B);
	C = SHA1CircularShift(30, A);
	if (t <= 15) {
		GET_UINT32_BE(W[t - 1], data, (t - 1) * 4);
		GET_UINT32_BE(W[t], data, t * 4);
	}
	else {
		W[t - 1] = SHA1CircularShift(1, W[t - 4] ^ W[t - 9] ^ W[t - 15] ^ W[t - 17]);
		W[t] = SHA1CircularShift(1, W[t-3] ^ W[t-8] ^ W[t-14] ^ W[t-16]);
	}
	B = SHA1CircularShift(5, A) + L1+ W[t - 1] + K[0];
	temp = SHA1CircularShift(5, B) + L2+ W[t] + K[0];
	temp &= 0xFFFFFFFF;
	A = temp;
	}
		
//(B ^ C ^ D) F2
	for (t = 21; t < 40; t = t + 2)
	{
	L1 = (B^C^D) + E;
	L2 = ((A^SHA1CircularShift(30, B)) ^ C) + D;
	E = C;
	D = SHA1CircularShift(30, B);
	C = SHA1CircularShift(30, A);
	W[t - 1] = SHA1CircularShift(1, W[t - 4] ^ W[t - 9] ^ W[t - 15] ^ W[t - 17]);
	W[t] = SHA1CircularShift(1, W[t - 3] ^ W[t - 8] ^ W[t - 14] ^ W[t - 16]);
	B = SHA1CircularShift(5, A) + L1+ W[t - 1] + K[1];
	temp = SHA1CircularShift(5, B) + L2 + W[t] + K[1];
	temp &= 0xFFFFFFFF;
	A = temp;
	}
		
//((B & C) | (B & D) | (C & D)) F3
	for (t = 41; t < 60; t = t + 2)
	{
	L1 = ((B & C) | (B & D) | (C & D)) + E;
	L2 = ((temp&SHA1CircularShift(30, B)) | (A&C) | (SHA1CircularShift(30, B)&C)) + D;
	E = C;
	D = SHA1CircularShift(30, B);
	C = SHA1CircularShift(30, A);//bcd
	W[t - 1] = SHA1CircularShift(1, W[t - 4] ^ W[t - 9] ^ W[t - 15] ^ W[t - 17]);
	W[t] = SHA1CircularShift(1, W[t - 3] ^ W[t - 8] ^ W[t - 14] ^ W[t - 16]);
	B = SHA1CircularShift(5, A) + L1 + W[t - 1] + K[2];
	temp = SHA1CircularShift(5, B) + L2+ W[t] + K[2];
	temp &= 0xFFFFFFFF;
	A = temp;
	}
		
//(B ^ C ^ D)
	for (t = 61; t < 80; t = t + 2)
	{
	L1 = (B^C^D) + E;
	L2 = ((A^SHA1CircularShift(30, B)) ^ C) + D;
	E = C;
	D = SHA1CircularShift(30, B);
	C = SHA1CircularShift(30, A);//bcd
	W[t - 1] = SHA1CircularShift(1, W[t - 4] ^ W[t - 9] ^ W[t - 15] ^ W[t - 17]);
	W[t] = SHA1CircularShift(1, W[t - 3] ^ W[t - 8] ^ W[t - 14] ^ W[t - 16]);
	B = SHA1CircularShift(5, A) + L1 + W[t - 1] + K[3];
	temp = SHA1CircularShift(5, B) + L2+ W[t] + K[3];
	temp &= 0xFFFFFFFF;
	A = temp;
	}
	//End
	ctx->state[0] += A;
	ctx->state[1] += B;
	ctx->state[2] += C;
	ctx->state[3] += D;
	ctx->state[4] += E;
}
/*
* Splits input message into blocks and processes them one by one. Also
* checks how many 0 need to be padded and processes the last, padded, block.
*/
__device__ void sha1_cpu_update(sha1_gpu1_context *ctx, unsigned char *input, int ilen)
{
	int fill;
	unsigned long left;
	if (ilen <= 0)
		return;
	left = ctx->total[0] & 0x3F;
	fill = 64 - left;
	ctx->total[0] += ilen;
	ctx->total[0] &= 0xFFFFFFFF;
	if (ctx->total[0] < (unsigned long)ilen)
		ctx->total[1]++;
	if (left && ilen >= fill) {
		memcpy((void *)(ctx->buffer + left), (void *)input, fill);
		sha1_cpu_upfoldprocess(ctx, ctx->buffer);
		input += fill;
		ilen -= fill;
		left = 0;
	}
	while (ilen >= 64) {
		sha1_cpu_upfoldprocess(ctx, input);
		input += 64;
		ilen -= 64;
	}
	if (ilen > 0) {
		memcpy((void *)(ctx->buffer + left), (void *)input, ilen);
	}
}


/*
* Process padded block and return hash to user.
*/
__device__ void sha1_cpu_finish(sha1_gpu1_context *ctx, unsigned char *output)
{
	unsigned long last, padn;
	unsigned long high, low;
	unsigned char msglen[8];


	high = (ctx->total[0] >> 29) | (ctx->total[1] << 3);
	low = (ctx->total[0] << 3);

	PUT_UINT32_BE(high, msglen, 0);
	PUT_UINT32_BE(low, msglen, 4);

	last = ctx->total[0] & 0x3F;
	padn = (last < 56) ? (56 - last) : (120 - last);

	sha1_cpu_update(ctx, (unsigned char *)sha1_padding, padn);
	sha1_cpu_update(ctx, msglen, 8);

	PUT_UINT32_BE(ctx->state[0], output, 0);
	PUT_UINT32_BE(ctx->state[1], output, 4);
	PUT_UINT32_BE(ctx->state[2], output, 8);
	PUT_UINT32_BE(ctx->state[3], output, 12);
	PUT_UINT32_BE(ctx->state[4], output, 16);
}

/*
* Execute SHA-1
*/
__device__ void sha1_cpu1(unsigned char *input, int ilen, unsigned char *output) {
	sha1_gpu1_context ctx;
	sha1_cpu_starts(&ctx);
	sha1_cpu_update(&ctx, input, ilen);
	sha1_cpu_finish(&ctx, output);
	memset(&ctx, 0, sizeof(sha1_gpu1_context));
}
__global__ void multisha1_thread(sha1gpu input[], int ilen, Hash output[], int n) {
	int i = blockIdx.x*blockDim.x + threadIdx.x;
	int i1 = blockDim.x*gridDim.x;
	for (int t = i; t < n; t = t + i1) {
		sha1_cpu1(input[t].block, ilen, output[t].hash);
	}
}
int main() {
	cudaSetDevice(0);
	cudaDeviceProp prop;
	cudaGetDeviceProperties(&prop, 0);
	int num_sm = prop.multiProcessorCount;
	printf("The num_sm of target is:%d\n", num_sm);
	dim3 ThreadperBlock(1024);
	dim3 BlockperGrid(num_sm);
	int length;
	cout << "INPUT THE SIZE" << endl;
	scanf("%d", &length);
	FILE*fp = fopen("1.txt", "w");
	BIGNUM*A = BN_new();
	for (int w = 0; w < 5; w++) {
		BN_rand(A, 256 * length, 1, 0);
		char*A1 = BN_bn2hex(A);
		fprintf(fp, "%s", A1);
	}
	cout << "Random file completed!" << endl;
	fclose(fp);
	int datablock = 5 * length;
	sha1gpu*sha1array;
	sha1array = new sha1gpu[datablock]; 
	printf("Please set the blocksize:\n");
	int blocksize; scanf("%d",&blocksize);
	char *input1=new char[blocksize+1];
	ifstream ifs;
	ifs.open("1.txt", ios::binary);
	if (!ifs) {
		cerr << "Error!" << endl;
		exit(1);
	}
	for (int i = 0; i < datablock; i++) {
		ifs.read(input1, blocksize); input1[blocksize] = '\0';
		for (int j = 0; j < blocksize; j++) {
			sha1array[i].block[j] = (unsigned char)input1[j];
		}
	}
	sha1gpu*INCUDA; Hash*hash1, *hash2;
	hash1 = new Hash[datablock];
	cudaMalloc((void**)&INCUDA, datablock * sizeof(class sha1gpu));
	cudaMemcpy(INCUDA, sha1array, datablock * sizeof(class sha1gpu), cudaMemcpyHostToDevice);
	cudaMalloc((void**)&hash2, datablock * sizeof(class Hash));
	cudaMemcpy(hash2, hash1, sizeof(class Hash)*datablock, cudaMemcpyHostToDevice);
	int allthread = datablock;
	cudaEvent_t start1;
	cudaEventCreate(&start1);
	cudaEvent_t stop1;
	cudaEventCreate(&stop1);
	cudaEventRecord(start1, NULL);
	multisha1_thread << <BlockperGrid, ThreadperBlock >> >(INCUDA, blocksize, hash2, allthread);
	cudaEventRecord(stop1, NULL);
	cudaEventSynchronize(stop1);
	float msecTotal1 = 0.0f, total;
	cudaEventElapsedTime(&msecTotal1, start1, stop1);
	total = msecTotal1 / 1000;
	cout << "GPU Runtime：" << total << "seconds" << endl;
	long r = 1 << 23; 
	FILE* fp11 = NULL;
	int nFileLen = 0;
	fp11 = fopen("1.txt", "rb");
	if (fp11 == NULL)
	{
		cout << "can't open file" << endl;
		return 0;
	}
	fseek(fp11, 0, SEEK_END);  
	nFileLen = ftell(fp11); 
	cout << "The Bytes of file is: " << nFileLen << endl;
	fclose(fp11);
	cout << "Throught：" << nFileLen *8/ total / r /blocksize<< " Gbps" << endl;
	cudaMemcpy(hash1, hash2, sizeof(class Hash)*datablock, cudaMemcpyDeviceToHost);
	FILE*fp1 = fopen("hash.txt", "w");
	for (int i = 0; i < datablock; i++) {
		for (int j = 0; j < 20; j++) {
			fprintf(fp1, "%02x", hash1[i].hash[j]);
		}
		fprintf(fp1, "\n");
	}
	unsigned char hashcpu[20];
	clock_t start, finsh;
	start = clock();
	for (int i = 0; i < datablock; i++) {
		SHA(sha1array[i].block, blocksize, hashcpu);
	}
	finsh = clock();
	float cputime = (float)(finsh - start) / 1000;
	cout << "OpenSSL execute " << cputime << "second" << endl;
	cudaFree(hash2); 
	cudaFree(INCUDA);
	BN_free(A);
	return 1;
}
