/*
  x = OPCam(args);

  Author: Daniel D. Lee <ddlee@seas.upenn.edu>, 05/10
  	: Stephen McGill 10/10
*/

#include <string.h>
#include "timeScalar.h"
#include "v4l2.h"
#include <lua.hpp>
#include <unistd.h>

typedef struct {
  int count;
  int select;
  double time;
  double joint[20];
} CAMERA_STATUS;

#define VIDEO_DEVICE "/dev/video0"

/* Exposed C functions to Lua */
typedef unsigned char uint8;
typedef unsigned int uint32;

CAMERA_STATUS *cameraStatus = NULL;
int init = 0;

static int lua_get_select(lua_State *L){
  lua_pushinteger(L,0);
  return 1;
}

static int lua_get_height(lua_State *L){
  lua_pushinteger(L, v4l2_get_height());
  return 1;
}

static int lua_get_width(lua_State *L){

  lua_pushinteger(L, v4l2_get_width());
  return 1;
}


static int lua_get_image(lua_State *L) {
  static int count = 0;
  int buf_num = v4l2_read_frame();
  if( buf_num < 0 ){
    //printf("RAGE!!!");
    lua_pushnumber(L,buf_num);
    return 1;
  }
  //printf("!@#$ YOU\n");
  uint32* image = (uint32*)v4l2_get_buffer(buf_num, NULL);

  // Increment the count
  count++;

  // Once our get_image returns, set the camera status
  cameraStatus->count = count;
  cameraStatus->time = time_scalar();
  cameraStatus->select = 0;
/*
  std::pair<double *, std::size_t> ret;
  ret = sensorShm->find<double>("position");
  double *p = ret.first;
  if (p != NULL) {
    for (int ji = 0; ji < 20; ji++) {
      cameraStatus->joint[ji] = p[ji];
    }
  }
*/
  // Zeros for now
  for (int ji = 0; ji < 20; ji++) {
    cameraStatus->joint[ji] = 0;
  }

  lua_pushlightuserdata(L, image);
  return 1;
}
static void turn_on_camera(){
    int res = 1;

  if (!init) {
    if ( v4l2_open(VIDEO_DEVICE) == 0){
      init = 1;
      v4l2_init( res );
      v4l2_stream_on();
			// Allocate our camera status
      cameraStatus = (CAMERA_STATUS *)malloc(sizeof(CAMERA_STATUS));
      /// TODO: free this
    }
  }
}
static void lua_take_save_images(uint32* pic) {
   	int imageSize = v4l2_get_width()*v4l2_get_height()*4;
	printf("Image width: %d height: %d\n",v4l2_get_width(), v4l2_get_height());
	static int count = 0;
	int numPics = 10;
	//uint32 * pics[numPics];
    	bool done = false;
	while(!done) {
		int buf_num = v4l2_read_frame();
		if( buf_num < 0 ){
            	    printf("RAGE!!!");
		    done = false;            
       		}else{
		    done = true;
              	    printf("\n was success\n");
                    uint32* image =(uint32*)v4l2_get_buffer(buf_num, NULL);
		    memcpy(pic,image,imageSize);
	//       	    for(int i = 0; i<imageSize; i++){
//			printf("my pixel is: %d\n", image[i]); 	
//		    }
		    printf("\n copy success\n");
        	}
	}
         //sleep(1);
	/*for (count = 0; count < numPics; count++) {
		printf("taking image #%d\n",count);
        int buf_num = v4l2_read_frame();
  		if( buf_num < 0 ){
    		printf("RAGE!!!");
    		count--;
			//ilua_pushnumber(L,buf_num);
    		//r;
  		}else{
			printf("\n was success\n");
			pics[count] = (uint32*)v4l2_get_buffer(buf_num, NULL);
		}
		sleep(1);
	}*/
//	return pics;
/*	int i = 0;
	printf("saving images\n");
	int width=v4l2_get_width();
	int height=v4l2_get_height();
	for (i = 0; i < numPics; i++){
		printf("on image %d\n", i);
        	FILE *ptr_myfile;
		char path[100];
		sprintf(path, "/home/darwin/%dtest.ppm", i);
		const char* cpath = path;
        	ptr_myfile=fopen(cpath, "wb");
		printf("Opened image file %dtest.ppm\n", i);
	//	fprintf(ptr_myfile, "P6\n%d %d\n255\n", width, height);
		int j,k;
 		for (j = 0; j < height; ++j){
 	        	for (k = 0; k < width; ++k){
  				static unsigned char color[3];
				uint32 pixel=pics[i][j*width+k];
  				color[0] = (unsigned char)(pixel&0xFF00>>8);  /*  Y */
  /*				color[1] = (unsigned char)(pixel&0xFF0000>>16);  /*  U */
  				//color[2] = (unsigned char)(pixel&0xFF);  /* V */
/*		 		fwrite(color, 1, 3, ptr_myfile);
  			}
  		}//fwrite(pics[i], 4, imageSize, ptr_myfile);
		printf("Wrote file");
		fclose(ptr_myfile);
		printf("closed file");
        }

*/
        // Once our get_image returns, set the camera status
        cameraStatus->count = count;
        cameraStatus->time = time_scalar();
        cameraStatus->select = 0;

        // Zeros for now
        for (int ji = 0; ji < 20; ji++) {
                cameraStatus->joint[ji] = 0;
        }
	return;
        //return pics;
}

static int lua_save_image(lua_State *L) {
  static int count = 0;
  //start copy
  FILE *ptr_myfile;
  ptr_myfile=fopen("test.bin","wb");
  const char* my_image = lua_tostring(L,1);
  int i = 0;
  for(i=0; i<100; i++)
	printf("%08x\n",my_image[i]);
  fwrite(&my_image, sizeof(9001), 1, ptr_myfile);
  fclose(ptr_myfile); 
  //end copy
  //Increment the count
  count++;

  // Once our get_image returns, set the camera status
  cameraStatus->count = count;
  //lua_pushlightuserdata(L, "success");
  return 1;
}
// Taken from the Naos
// TODO: this is not really working super well...
static int lua_camera_status(lua_State *L) {

  lua_createtable(L, 0, 4);

  lua_pushinteger(L, cameraStatus->count);
  lua_setfield(L, -2, "count");
  lua_pushinteger(L, cameraStatus->select);
//  lua_pushinteger(L, 0);
  lua_setfield(L, -2, "select");
  lua_pushnumber(L, cameraStatus->time);
  lua_setfield(L, -2, "time");

  lua_createtable(L, 22, 0);
  for (int i = 0; i < 22; i++) {
//    lua_pushnumber(L, cameraStatus->joint[i]);
    lua_pushnumber(L, cameraStatus->joint[i]);
    lua_rawseti(L, -2, i+1);
  }
  lua_setfield(L, -2, "joint");

  return 1;
}

static int lua_init(lua_State *L){
  int res = 1;
  v4l2_init( res );
  cameraStatus = (CAMERA_STATUS *)malloc(sizeof(CAMERA_STATUS));// Allocate our camera statu
  return 1;
}

static int lua_stop(lua_State *L){
  free( cameraStatus );
  v4l2_close();
  return 1;
}

static int lua_small_init(lua_State *L) {
	int res = 0;
	v4l2_init(res);
	cameraStatus = (CAMERA_STATUS *)malloc(sizeof(CAMERA_STATUS));// Allocate our camera statu
	return 1;
}



static int lua_stream_on(lua_State *L){
  v4l2_stream_on();
  return 1;
}

static int lua_stream_off(lua_State *L){
  v4l2_stream_off();
  return 1;
}

static int lua_set_param(lua_State *L) {
  const char *param = luaL_checkstring(L, 1);
  double value = luaL_checknumber(L, 2);

  int ret = v4l2_set_ctrl(param, value);
  lua_pushnumber(L, ret);

  return 1;
}

//Added
static int lua_set_param_id(lua_State *L) {
  double id = luaL_checknumber(L, 1);
  double value = luaL_checknumber(L, 2);

  int ret = v4l2_set_ctrl_by_id(id, value);
  lua_pushnumber(L, ret);

  return 1;
}

static int lua_get_param(lua_State *L) {
  const char *param = luaL_checkstring(L, 1);

  int value;
  double ret = v4l2_get_ctrl(param, &value);
  lua_pushnumber(L, value);

  return 1;
}

// Camera selects should be nil
static int lua_select_camera(lua_State *L) {
  int bottom = luaL_checkint(L, 1);
  return 1;
}

static int lua_select_camera_fast(lua_State *L) {
  int bottom = luaL_checkint(L, 1);
  return 1;
}

static int lua_select_camera_slow(lua_State *L) {
  int bottom = luaL_checkint(L, 1);
  return 1;
}

static int lua_selected_camera(lua_State *L) {
  lua_pushinteger(L, 0);
  return 1;
}

/* Lua Wrapper Requirements */
static const struct luaL_Reg camera_lib [] = {
  {"get_image", lua_get_image},
  {"save_image", lua_save_image},
//  {"take_save_images", lua_take_save_images}, 
  {"init", lua_init},
  {"small_init", lua_small_init},
  {"stop",lua_stop},
  {"stream_on", lua_stream_on},
  {"stream_off", lua_stream_off},
  {"get_height", lua_get_height},
  {"get_width", lua_get_width},
  {"get_select", lua_get_select},
  {"set_param", lua_set_param},
  {"get_param", lua_get_param},
  {"set_param_id", lua_set_param_id},
  {"get_camera_status", lua_camera_status},
  {"select_camera", lua_select_camera},
  {"select_camera_fast", lua_select_camera_fast},
  {"select_camera_slow", lua_select_camera_slow},
  {"get_select", lua_selected_camera},
  {NULL, NULL}
};

extern "C"
int luaopen_OPCam (lua_State *L) {
  luaL_register(L, "camera", camera_lib);

  // Resolution = 1 means VGA (640x480)
  //int res = luaL_checkint(L, 2);
  int res = 1;

  if (!init) {
    if ( v4l2_open(VIDEO_DEVICE) == 0){
      init = 1;
      v4l2_init( res );
      v4l2_stream_on();
			// Allocate our camera status
      cameraStatus = (CAMERA_STATUS *)malloc(sizeof(CAMERA_STATUS));
      /// TODO: free this
    }
  }
  return 1;
}
