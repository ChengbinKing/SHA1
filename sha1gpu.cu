#include"cuda.h"
#include "Common1.h"
#include"device_launch_parameters.h"
#include"stdio.h"
#include"time.h"
typedef struct {
	unsigned long state[5];
} sha1_gpu_context;
typedef struct {
	float malloctime;
	float copytime;
	float kerneltime;
}time_cuda_collect;
time_cuda_collect A1 = { 0,0,0};
#define S(x,n) ((x << n) | ((x & 0xFFFFFFFF) >> (32 - n)))
#define R(t) \
	temp = extended[block_index + t -  3] ^ extended[block_index + t - 8] ^     \
		   extended[block_index + t - 14] ^ extended[block_index + t - 16]; \
	extended[block_index + t] = S(temp,1); \
//Another methods
__device__ inline unsigned long f1(unsigned long x, unsigned long y, unsigned long z) { return(z ^ (x&(y^z))); }// (x & y ) | ( ~x & z)
__device__ inline unsigned long f2(unsigned long x, unsigned long y, unsigned long z) { return(x^y^z); }
__device__ inline unsigned long f3(unsigned long x, unsigned long y, unsigned long z) { return((x&y)|(z&(x|y)));}
__device__ inline unsigned long f4(unsigned long x, unsigned long y, unsigned long z) { return(x^y^z); }
//
__constant__ unsigned long C1 = 0x5A827999;
__constant__ unsigned long C2 = 0x6Ed9EBA1;
__constant__ unsigned long C3 = 0x8F1BBCDC;
__constant__ unsigned long C4 = 0xCA62C1D6;
__device__ unsigned long SST(unsigned long x, int n) { return((x << n)|((x & 0xFFFFFFFF)>>(32 - n))); }
__device__ unsigned long p1(unsigned long a, unsigned long b, unsigned long c, unsigned long d, unsigned long x){ return(SST(a,5)+f1(b,c,d)+C1+x);  }
__device__ unsigned long p2(unsigned long a, unsigned long b, unsigned long c, unsigned long d, unsigned long x){ return(SST(a,5)+f2(b,c,d)+C2+x);   }
__device__ unsigned long p3(unsigned long a, unsigned long b, unsigned long c, unsigned long d, unsigned long x){ return(SST(a, 5) + f3(b, c, d) + C3 + x); }
__device__ unsigned long p4(unsigned long a, unsigned long b, unsigned long c, unsigned long d, unsigned long x){ return(SST(a, 5) + f4(b, c, d) + C4 + x); }
__device__ void sha1_gpu_process2(sha1_gpu_context *ctx, unsigned long W[80]) {
	unsigned long A, B, C, D, E;
	A = ctx->state[0];
	B = ctx->state[1];
	C = ctx->state[2];
	D = ctx->state[3];
	E = ctx->state[4];

	for (int t = 0; t < 16; t++) {
		if (5*t < 20) {
			E = E + p1(A, B, C, D, W[0+5*t]); B = SST(B, 30);
			D = D + p1(E, A, B, C, W[1+5*t]); A = SST(A, 30);
			C = C + p1(D, E, A, B, W[2+5*t]); E = SST(E, 30);
			B = B + p1(C, D, E, A, W[3+5*t]); D = SST(D, 30);
			A = A + p1(B, C, D, E, W[4+5*t]); C = SST(C, 30);
		}
		if ((5*t < 40)&&(5*t>=20)) {
			E = E + p2(A, B, C, D, W[0 + 5 * t]); B = SST(B, 30);
			D = D + p2(E, A, B, C, W[1 + 5 * t]); A = SST(A, 30);
			C = C + p2(D, E, A, B, W[2 + 5 * t]); E = SST(E, 30);
			B = B + p2(C, D, E, A, W[3 + 5 * t]); D = SST(D, 30);
			A = A + p2(B, C, D, E, W[4 + 5 * t]); C = SST(C, 30);
		}
		if ((5*t < 60)&&(5*t>=40)) {
			E = E + p3(A, B, C, D, W[0 + 5 * t]); B = SST(B, 30);
			D = D + p3(E, A, B, C, W[1 + 5 * t]); A = SST(A, 30);
			C = C + p3(D, E, A, B, W[2 + 5 * t]); E = SST(E, 30);
			B = B + p3(C, D, E, A, W[3 + 5 * t]); D = SST(D, 30);
			A = A + p3(B, C, D, E, W[4 + 5 * t]); C = SST(C, 30);
		}
		if ((5*t < 80)&&(5*t>=60)) {
			E = E + p4(A, B, C, D, W[0 + 5 * t]); B = SST(B, 30);
			D = D + p4(E, A, B, C, W[1 + 5 * t]); A = SST(A, 30);
			C = C + p4(D, E, A, B, W[2 + 5 * t]); E = SST(E, 30);
			B = B + p4(C, D, E, A, W[3 + 5 * t]); D = SST(D, 30);
			A = A + p4(B, C, D, E, W[4 + 5 * t]); C = SST(C, 30);
		}
	}
	//printf("%x,%x,%x,%x,%x\n", ctx->state[0], ctx->state[1], ctx->state[2], ctx->state[3], ctx->state[4]);
	ctx->state[0] += A;
	ctx->state[1] += B;
	ctx->state[2] += C;
	ctx->state[3] += D;
	ctx->state[4] += E;
}
__device__ void sha1_gpu_process(sha1_gpu_context *ctx, unsigned long W[80])
{

	__shared__ unsigned long A, B, C, D, E;
	A = ctx->state[0];
	B = ctx->state[1];
	C = ctx->state[2];
	D = ctx->state[3];
	E = ctx->state[4];
	// 4 rounds calculation defination
#define P(a,b,c,d,e,x)                                  \
{                                                       \
    e += S(a,5) + F(b,c,d) + K + x; b = S(b,30);        \
}

	//0~19 rounds corresponding function and data
#define F(x,y,z) (z ^ (x & (y ^ z)))
#define K 0x5A827999

	P(A, B, C, D, E, W[0]);
	P(E, A, B, C, D, W[1]);
	P(D, E, A, B, C, W[2]);
	P(C, D, E, A, B, W[3]);
	P(B, C, D, E, A, W[4]);
	P(A, B, C, D, E, W[5]);
	P(E, A, B, C, D, W[6]);
	P(D, E, A, B, C, W[7]);
	P(C, D, E, A, B, W[8]);
	P(B, C, D, E, A, W[9]);
	P(A, B, C, D, E, W[10]);
	P(E, A, B, C, D, W[11]);
	P(D, E, A, B, C, W[12]);
	P(C, D, E, A, B, W[13]);
	P(B, C, D, E, A, W[14]);
	P(A, B, C, D, E, W[15]);
	P(E, A, B, C, D, W[16]);
	P(D, E, A, B, C, W[17]);
	P(C, D, E, A, B, W[18]);
	P(B, C, D, E, A, W[19]);

#undef K
#undef F
	//20~39 rounds corresponding function and data
#define F(x,y,z) (x ^ y ^ z)
#define K 0x6ED9EBA1

	P(A, B, C, D, E, W[20]);
	P(E, A, B, C, D, W[21]);
	P(D, E, A, B, C, W[22]);
	P(C, D, E, A, B, W[23]);
	P(B, C, D, E, A, W[24]);
	P(A, B, C, D, E, W[25]);
	P(E, A, B, C, D, W[26]);
	P(D, E, A, B, C, W[27]);
	P(C, D, E, A, B, W[28]);
	P(B, C, D, E, A, W[29]);
	P(A, B, C, D, E, W[30]);
	P(E, A, B, C, D, W[31]);
	P(D, E, A, B, C, W[32]);
	P(C, D, E, A, B, W[33]);
	P(B, C, D, E, A, W[34]);
	P(A, B, C, D, E, W[35]);
	P(E, A, B, C, D, W[36]);
	P(D, E, A, B, C, W[37]);
	P(C, D, E, A, B, W[38]);
	P(B, C, D, E, A, W[39]);

#undef K
#undef F
	//40~59 rounds corresponding function and data
#define F(x,y,z) ((x & y) | (z & (x | y)))
#define K 0x8F1BBCDC

	P(A, B, C, D, E, W[40]);
	P(E, A, B, C, D, W[41]);
	P(D, E, A, B, C, W[42]);
	P(C, D, E, A, B, W[43]);
	P(B, C, D, E, A, W[44]);
	P(A, B, C, D, E, W[45]);
	P(E, A, B, C, D, W[46]);
	P(D, E, A, B, C, W[47]);
	P(C, D, E, A, B, W[48]);
	P(B, C, D, E, A, W[49]);
	P(A, B, C, D, E, W[50]);
	P(E, A, B, C, D, W[51]);
	P(D, E, A, B, C, W[52]);
	P(C, D, E, A, B, W[53]);
	P(B, C, D, E, A, W[54]);
	P(A, B, C, D, E, W[55]);
	P(E, A, B, C, D, W[56]);
	P(D, E, A, B, C, W[57]);
	P(C, D, E, A, B, W[58]);
	P(B, C, D, E, A, W[59]);

#undef K
#undef F
	//60~79 rounds function 
#define F(x,y,z) (x ^ y ^ z)
#define K 0xCA62C1D6

	P(A, B, C, D, E, W[60]);
	P(E, A, B, C, D, W[61]);
	P(D, E, A, B, C, W[62]);
	P(C, D, E, A, B, W[63]);
	P(B, C, D, E, A, W[64]);
	P(A, B, C, D, E, W[65]);
	P(E, A, B, C, D, W[66]);
	P(D, E, A, B, C, W[67]);
	P(C, D, E, A, B, W[68]);
	P(B, C, D, E, A, W[69]);
	P(A, B, C, D, E, W[70]);
	P(E, A, B, C, D, W[71]);
	P(D, E, A, B, C, W[72]);
	P(C, D, E, A, B, W[73]);
	P(B, C, D, E, A, W[74]);
	P(A, B, C, D, E, W[75]);
	P(E, A, B, C, D, W[76]);
	P(D, E, A, B, C, W[77]);
	P(C, D, E, A, B, W[78]);
	P(B, C, D, E, A, W[79]);

#undef K
#undef F
	// Final operation:Add this chunk's hash to result so far
	ctx->state[0] += A;
	ctx->state[1] += B;
	ctx->state[2] += C;
	ctx->state[3] += D;
	ctx->state[4] += E;

}


/*
* Process extended block in GPU,analysis: there are no existing parallel methods for 
* the inputs are closely related to the output
*/


void __global__  sha1_kernel_global(unsigned char *data, sha1_gpu_context *ctx, int total_threads, unsigned long *extended)
{
	int thread_index = threadIdx.x + blockDim.x * blockIdx.x;
	int e_index = thread_index * 80;
	int block_index = thread_index * 64;//512 byte is a block
	unsigned long temp, t;
	if (thread_index > total_threads - 1)
		return;

	/*
	* load 32 to 80 blocks
	*/
	GET_UINT32_BE(extended[e_index], data + block_index, 0);
	GET_UINT32_BE(extended[e_index + 1], data + block_index, 4);
	GET_UINT32_BE(extended[e_index + 2], data + block_index, 8);
	GET_UINT32_BE(extended[e_index + 3], data + block_index, 12);
	GET_UINT32_BE(extended[e_index + 4], data + block_index, 16);
	GET_UINT32_BE(extended[e_index + 5], data + block_index, 20);
	GET_UINT32_BE(extended[e_index + 6], data + block_index, 24);
	GET_UINT32_BE(extended[e_index + 7], data + block_index, 28);
	GET_UINT32_BE(extended[e_index + 8], data + block_index, 32);
	GET_UINT32_BE(extended[e_index + 9], data + block_index, 36);
	GET_UINT32_BE(extended[e_index + 10], data + block_index, 40);
	GET_UINT32_BE(extended[e_index + 11], data + block_index, 44);
	GET_UINT32_BE(extended[e_index + 12], data + block_index, 48);
	GET_UINT32_BE(extended[e_index + 13], data + block_index, 52);
	GET_UINT32_BE(extended[e_index + 14], data + block_index, 56);
	GET_UINT32_BE(extended[e_index + 15], data + block_index, 60);

	for (t = 16; t < 80; t++) {
		temp = extended[e_index + t - 3] ^ extended[e_index + t - 8] ^
			extended[e_index + t - 14] ^ extended[e_index + t - 16];
		extended[e_index + t] = S(temp, 1);
	}
	/* Wait for the last thread and compute intermediate hash values of extended blocks */
	__syncthreads();
	if (thread_index == total_threads - 1) {
		for (t = 0; t < total_threads; t++)
			sha1_gpu_process(ctx, (unsigned long*)&extended[t * 80]);

	}
}


void sha1_gpu_global1(unsigned char *input, unsigned long size, unsigned char *output, int proc)
{
	int total_threads;
	int blocks_per_grid;
	int threads_per_block;
	int pad, size_be;
	int total_datablocks;
	int i, k;
	unsigned char *d_message;
	unsigned long *d_extended;
	sha1_gpu_context ctx, *d_ctx;
	//Initialize the parameter
	ctx.state[0] = 0x67452301;
	ctx.state[1] = 0xEFCDAB89;
	ctx.state[2] = 0x98BADCFE;
	ctx.state[3] = 0x10325476;
	ctx.state[4] = 0xC3D2E1F0;

	pad = padding_256(size);//To pad depended on size
	threads_per_block = proc;
	blocks_per_grid = 1;
	total_datablocks = (size + pad + 8) / 64; //64;
	//printf("total_datablocks is %d\n", total_datablocks);
	//Limit the number of total_threads
	if (total_datablocks > threads_per_block)
		total_threads = threads_per_block;//In this program is 1
	else
		total_threads = total_datablocks;
	//printf("total_threads is %d\n", total_threads);
	size_be = LETOBE32(size * 8);
	/* allocate enough memory*/
	clock_t start1, finish1;
	start1 = clock();
	cudaMalloc((void**)&d_extended, proc * 80 * sizeof(unsigned long));
	cudaMalloc((void**)&d_message, size + pad + 8);
	cudaMalloc((void**)&d_ctx, sizeof(sha1_gpu_context));
	finish1 = clock();
	A1.malloctime = (finish1 - start1) / CLOCKS_PER_SEC;
	clock_t start2, finish2;
	start2 = clock();
	cudaMemcpy(d_ctx, &ctx, sizeof(sha1_gpu_context), cudaMemcpyHostToDevice);
	cudaMemcpy(d_message, input, size, cudaMemcpyHostToDevice);
	cudaMemset(d_message + size, 0x80, 1);
	cudaMemset(d_message + size + 1, 0, pad + 7);
	cudaMemcpy(d_message + size + pad + 4, &size_be, 4, cudaMemcpyHostToDevice);
	finish2 = clock();
	A1.copytime = (finish2 - start2) / CLOCKS_PER_SEC;
	/*
	* run the algorithm
	*/
	i = 0;
    k = total_datablocks / total_threads;
	clock_t start3, finish3;
	start3 = clock();
	if (k - 1 > 0) {
		for (i = 0; i < k; i++) {
			sha1_kernel_global << <total_datablocks, proc >> >(d_message + threads_per_block * i * 64,
				d_ctx, threads_per_block, d_extended);
		}
	}
	threads_per_block = total_datablocks - (i * total_threads);//remaining block
	//printf("The real threads_per_block is %d\n", threads_per_block);//total_datablocks
	sha1_kernel_global << <total_datablocks, proc >> >(d_message + total_threads * i * 64, 
		d_ctx, threads_per_block, d_extended);

	finish3 = clock();
	A1.kerneltime = (finish3 - start3) / CLOCKS_PER_SEC;
	//copy data form deivce to Host
	cudaMemcpy(&ctx, d_ctx, sizeof(sha1_gpu_context), cudaMemcpyDeviceToHost);
	//output the hash
	PUT_UINT32_BE(ctx.state[0], output, 0);
	PUT_UINT32_BE(ctx.state[1], output, 4);
	PUT_UINT32_BE(ctx.state[2], output, 8);
	PUT_UINT32_BE(ctx.state[3], output, 12);
	PUT_UINT32_BE(ctx.state[4], output, 16);
	cudaFree(d_message);
	cudaFree(d_ctx);
	cudaFree(d_extended);
	printf("malloc process needs %f seconds,copy process needs %f seconds,kernel process needs %f seconds\n", A1.malloctime, A1.copytime, A1.kerneltime);
}