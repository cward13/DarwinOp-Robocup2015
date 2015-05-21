#include "easysocket.h"
#include <errno.h>
#include <string.h>
#include <fcntl.h>
#include "lua_OPCam.cpp"

#define WIDTH (640)
#define HEIGHT (480)

#define COMMAND_PICTURE (0)
#define COMMAND_LOOKUP (1)

// defined as 2^32
#define LOOKUP_TABLE_SIZE (262144) 

int main()
	{
	uint32 bufferout[WIDTH * HEIGHT];
	char bufferin[LOOKUP_TABLE_SIZE];
	
	server_type = SERVER_TYPE_SERIAL;
	int fd;
	turn_on_camera();
	while(1)
		{
		printf("i am trying to wait for a connection\n");
		fd = wait_on_socket();
		printf("i received a connection\n");
			if (fd < 0)
			{
			printf("Can't connect: %s\n", strerror(errno));
			exit(1);
			}

		// get the command
		readn(fd, bufferin, 1);
		if (bufferin[0] == COMMAND_PICTURE)
			{	
			lua_take_save_images(bufferout);	
		    lua_take_save_images(bufferout);	
			lua_take_save_images(bufferout);	
			writen(fd, (char*)bufferout, WIDTH * HEIGHT*2); // had to half to make faster
			}
		else if (bufferin[0] == COMMAND_LOOKUP)
			{
			readn(fd, bufferin, LOOKUP_TABLE_SIZE);
			int fd2 = open("/home/darwin/dev/merc/darwin/UPENN2013/Player/Data/lut_demoOP.raw", O_WRONLY | O_CREAT | O_TRUNC, 0666);
			writen(fd2, bufferin, LOOKUP_TABLE_SIZE);
			close(fd2);
			printf("Lookup Table Written\n");
			// All LOOKUP_TABLE_SIZE bytes are now in the buffer.  process them here -- Sean
			// ...
			}
		else
			{
			printf("Unknown byte received: %d\n", (int)bufferin[0]);
			}
		close(fd);
		}
	}
