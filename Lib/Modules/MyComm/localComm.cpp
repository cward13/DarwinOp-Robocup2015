#include <iostream>
#include <string>
#include <deque>
#include "string.h"
#include <stdlib.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netdb.h>
#include <stdio.h>
#include <assert.h>

#ifdef __cplusplus
extern "C"
{
#endif
#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
#ifdef __cplusplus
}
#endif

#include <vector>
#include <algorithm>
#include <stdint.h>

static std::string IP;
static int PORT = 0;
static int send_fd;



static int lua_comm_connect_local(lua_State *L) {
	printf("hi i am trying to connecto to things, just thought i'd print something, for fun\n");
	const char *ip = luaL_checkstring(L, 1);
	int port = luaL_checkint(L,2);
	IP = ip;
	PORT = port;
        fprintf(stderr, "port is %d", PORT); 	
	send_fd = socket(AF_INET, SOCK_STREAM, 0);

	fprintf(stderr, "Opening connection on port %s:%d\n", ip,PORT);

	struct sockaddr_in dest_addr;
	bzero((char *) &dest_addr, sizeof(dest_addr));
	dest_addr.sin_family = AF_INET;
	dest_addr.sin_port = htons(PORT);
	inet_pton(AF_INET, ip, &dest_addr.sin_addr);

	// connect
	int rc;
	rc = connect(send_fd, (struct sockaddr *) &dest_addr, sizeof(dest_addr));
	if (rc < 0) {
		perror("Could not connect!");
		exit(1);
	}
	fprintf(stderr, "Connection established on FD %d\n", send_fd);

	send(send_fd, "Test", 4, 0);
	
	return 1;
}


static int lua_comm_send_local(lua_State *L) {
	const char *data = luaL_checkstring(L, 1);
  	int size = luaL_optint(L, 2, 0);

	int ret = write(send_fd, data, size);

	lua_pushinteger(L, ret);

	return 1;

}


static int lua_comm_disconnect_local(lua_State *L) {
	close(send_fd);
}


static const struct luaL_reg Comm_lib [] = {
  {"comm_connect", lua_comm_connect_local},
  {"comm_send", lua_comm_send_local},
  {"comm_disconnect", lua_comm_disconnect_local},
  {NULL, NULL}
};

#ifdef __cplusplus
extern "C"
#endif
int luaopen_MyComm (lua_State *L) {
  luaL_register(L, "MyComm", Comm_lib);

  return 1;
}


int main() {
	lua_State *L = lua_open();
	luaopen_MyComm(L);
}







