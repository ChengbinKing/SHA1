# SHA1
(1)An implementation of Sha1 both in cuda and cpu. It runs sucessfully in Win10,it can also perform in Ubunutu.
What's more,it requires OpenSSL library if you want to run in Windows.

(2)The former implementation of sha1 in gpu can be seen in sha1gpu.cu

(3)If you want to run in Ubuntu,you need to delete #pragma comment(lib, "libeay32.lib") #pragma comment(lib, "ssleay32.lib").

(4) The refered command in Linux can be used as nvcc -g -G sha1gpu.cu -o sha1 -lssl -lcrypto
(5) execute ./sha1
