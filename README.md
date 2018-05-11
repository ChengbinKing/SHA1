# SHA1
An implementation of Sha1 both in cuda and cpu. It runns sucessfully in Win10,it can also perform in Ubunutu.
What's more,it requires OpenSSL library.
The implementation of sha1 in cpu is showed in cpu_sha1.cu
The former implementation of sha1 in gpu can be seen in sha1gpu.cu
Another implemenatation of sha1 in gpu is in sha1_based_on_CPU.cu. It refers to the code of cpu_sha1.cu and use cuda to implement sha1 in GPU.
In sha1_based_pn_CPU.cu, the function" void multisha1_gpu(unsigned char**input,int *ilen,unsigned char**output,int n)" can be used to deal with several data and calculate the hash value in parallel.
