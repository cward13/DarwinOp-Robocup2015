/*
 *    easysocket.h
 *    Sockets Made Easy library (interface and instructions)
 *    by Sean Luke
 *    seanl@cs.umd.edu
 *    (sorry about the long disclaimer)
 *
 *    Disclaimer of Warranty, Limits of Liability, and Copyright Notice
 *
 *    Excepting portions as noted below, this work is copyright 1995 by
 *    Sean Luke (seanl@cs.umd.edu).
 *
 *    Permission to use, modify, and distribute this material for any purpose
 *    and without fee is hereby granted, provided that this copyright notice
 *    appear in all copies, that my name not be used in advertising or
 *    publicity pertaining to this material without my specific, prior
 *    written permission, and that you adhere to the restrictions and 
 *    agreements stated in the paragraphs following in this copyright notice.  
 *
 *    I MAKE NO REPRESENTATIONS ABOUT THE ACCURACY OR
 *    SUITABILITY OF THIS MATERIAL FOR ANY PURPOSE.  IT IS PROVIDED "AS IS"
 *    WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
 *
 *    Portions of this code are based on examples in UNIX Network Programming
 *    By W. Richard Stevens (ISBN 0-13-949876-1), and are copyright
 *    1990 by Prentice-Hall, Inc.  His code is freely available
 *    at ftp://ftp.uu.net/published/books/stevens.netprog.tar.Z
 *    To the best of my knowledge, his code is freely usable in the
 *    public domain, since it is advertised as freely available and comes
 *    with a disclaimer (following this paragraph).  However, permission
 *    to use this library is granted only if you agree to free me of any
 *    responsibility resulting from your misuse of his work, and agree
 *    to his disclaimer below.
 *    
 *    UNIX Network Programming Limits of Liability and Disclaimer of Warranty
 *
 *    The author and publisher of the book "UNIX Network Programming"
 *    have used their best efforts in preparing this software.
 *    These efforts include the development, research, and testing
 *    of the theories and programs to determine their effectiveness.
 *    The author and publisher make no warranty of any kind, express
 *    or implied, with regard to these programs or the documentation
 *    contained in the book. The author and publisher shall not be
 *    liable in any event for incidental or consequential damages in
 *    connection with, or arising out of, the furnishing, performance,
 *    or use of these programs.
 */







/*

INSTRUCTIONS


What is this library?

This library allows you to set up a simple client-server socket connection,
using UNIX file descriptors (fds).  You use the same library for both
the server side and the client side.  The server can be set up to accept
only one connection at a time, or to be a multiforked server accepting
simultaneous parallel connections.  It's your choice. To use the library,
add the easysocket.c and easysocket.h files to your code, and #include the 
easysocket.h file.


What do I need to set up to use the library?

The library needs to know the server address and thensocket port number 
you've chosen to use.  The address must be a numerical address.  You can 
hard-code the address and port by modifying the SERV_TCP_PORT and 
SERV_HOST_ADDR constants in this file, and setting global_server_defined to 
equal 0 before you call any of the functions in the library.  Or you can 
specify the address and port at run-time by placing the port in 
global_server_port, the address in global_server_addr, and setting 
global_server_defined to equal 1 before you call any of the functions in the 
library.

If you're a server, you'll also need to tell the library if you want to
be a multi-forked parallel server or an ordinary serial server.  To do this,
set server_type to equal SERVER_TYPE_PARALLEL or SERVER_TYPE_SERIAL before
you call any of the functions in the library.


How do I use the library to write a server?

Once you've set the parameters described above, call wait_on_socket() to
wait for a client to connect to you.  If you picked a serial server, this
function will return in an ordinary fashion.  If you picked a parallel server,
this function goes into an infinite loop, forking off children as clients
make connections.  Each child will return from wait_on_socket(), but the
parent never does (unless there's an error).  Make sense?

If this function returns >0, it has handed you a UNIX file descriptor 
(UNIX's equivalent of a stream pointer).  When you're done transfering
information back and forth on the descriptor, use the UNIX close() command
to close it.  If you picked a serial server, you can exit now, or loop
back into wait_on_socket() (which may take a few shots to regain the socket)
to get another connection.  If you picked a parallel server, you should
exit(0) after closing the connection.  Remember, in a parallel server,
once wait_on_socket() returned, you're a child process (unless wait_on_socket()
returned with an error), and your job in life is to process the file
descriptor from the client, and then die.


How do I use the library to write a client?

Once you've set the parameters described above, call connect_to_socket() to
hook up with the client.  If connect_to_socket returns >0,  it has handed you
a UNIX file descriptor (UNIX's equivalent of a stream pointer), representing
your connection to the server.  Send and receive stuff on this descriptor,
and then use the UNIX close() command to close the connection.


How do I use the library to read and write to the file descriptor
once I get it?

The library provides three commands:  readn(), which reads n bytes,
writen() which writes n bytes, and readline(), which reads until it
hits a newline (\n), which in UNIX is a linefeed.  The readn and writen
are "symmetric" functions; i.e., they work just like the UNIX file versions.
The standard socket read and write functions DON'T work just like them; use
the library ones instead and you'll be happier!


Where are these functions documented?

In easysocket.c, after the declaration of each function.  Check 'em out.


Do you have any examples?

Yes.  Following the implementation code in easysocket.c are three example
main() functions:

	main1() implements a serial one-shot server that waits for one
		connection, processes it, and promptly dies.

	main2() implements a looped multi-forked parallel server that
		handles any number of connections, including simultaneous
		ones.

	main3()	implements a simple one-shot client.

Make sure to set the server address to something real before running any of 'em.
You'll want to remove these examples from easysocket.c before compiling it
for a real program.

*/



#include <stdio.h>
#include <stdlib.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <sys/fcntl.h>
#include <sys/errno.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>

#define SERV_TCP_PORT 8050                   /*  A default TCP Port */
#define SERV_HOST_ADDR "localhost"     /*  default server address here */

#define SERVER_TYPE_PARALLEL 0            /*  Server Connection Is Multiuser */
#define SERVER_TYPE_SERIAL 1              /*  Server Connection Is One-Shot */


extern int global_server_defined;                /*  We've Got A Non-Default Port */
												/*  and non-default server address */
extern int global_server_port;                   /*  The Actual TCP Port */
extern char global_server_addr[256];             /*  the actual tcp address */
extern int server_type;                          /*  Server Type (See Above) */

int readn (int fd, char* ptr, int nbytes);      /*  Read N Chars, Else <0 */
int writen(int fd, char* ptr, int nbytes);      /*  Write N Chars, Else <0 */
int readline (int fd, char* ptr, int maxlen);   /*  Read A Line, Else <0 */
int connect_to_socket();                        /*  Make A Client Connection */
int wait_on_socket();                           /*  Make A Server Connection */

