# SHA1
(1)An implementation of Sha1 both in cuda and cpu. It runs sucessfully in Win10,it can also perform in Ubunutu.
What's more,it requires OpenSSL library if you want to run in Windows.

(2)The implementation of sha1 in cpu is showed in cpu_sha1.cu

(3)The former implementation of sha1 in gpu can be seen in sha1gpu.cu

(4)Another implemenatation of sha1 in gpu is in sha1_based_on_CPU.cu. It refers to the code of cpu_sha1.cu and use cuda to implement sha1 in GPU.

(5)In sha1_based_pn_CPU.cu, the function" void multisha1_gpu(unsigned char**input,int *ilen,unsigned char**output,int n)" can be used to deal with several data and calculate the hash value in parallel. You can change the value n as you want.

(6) If you want to run in Ubuntu,you need to delete #pragma comment(lib, "libeay32.lib") #pragma comment(lib, "ssleay32.lib").

(7) The refered command in Linux can be used as nvcc -g -G sha1_basd_on_CPU.cu cpu_sha1.cu sha1gpu.cu sha1test.cu -o *** -lssl -lcrypto
