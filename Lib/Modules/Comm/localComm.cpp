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

static std::string MY_IP;
static int MY_PORT = 0;
static int my_send_fd;



static int lua_comm_connect_local(lua_State *L) {
	const char *MY_IP = luaL_checkstring(L, 1);
	int MY_PORT = luaL_checkint(L,2);
	MY_IP = MY_IP;
	MY_PORT = MY_PORT;
 	
	my_send_fd = socket(AF_INET, SOCK_DGRAM, 0);



	struct sockaddr_in dest_addr;
	bzero((char *) &dest_addr, sizeof(dest_addr));
	dest_addr.sin_family = AF_INET;
	dest_addr.sin_MY_PORT = htons(MY_PORT);
	inet_pton(AF_INET, MY_IP, &dest_addr.sin_addr);

	// connect
	int rc;
	rc = connect(my_send_fd, (struct sockaddr *) &dest_addr, sizeof(dest_addr));
	if (rc < 0) {
		perror("Could not connect!");
		exit(1);
	}
	
	return 1;
}


static int lua_comm_send_local(lua_State *L) {
	const char *data = luaL_checkstring(L, 1);
  	int size = luaL_optint(L, 2, 0);

	std::string dataStr;
	std::string contents(data, size);
	dataStr = contents;

	int ret = send(my_send_fd, dataStr.c_str(), dataStr.size(), 0);

	lua_pushinteger(L, ret);

	return 1;

}


static int lua_comm_disconnect_local(lua_State *L) {
	close(my_send_fd);
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
int luaopen_Comm (lua_State *L) {
  luaL_register(L, "MyComm", Comm_lib);

  return 1;
}


int main() {
	lua_State *L = lua_open();
	luaopen_Comm(L);
}







