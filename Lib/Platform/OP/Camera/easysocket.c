/*
 *    easysocket.c
 *    Sockets Made Easy library (implementation and examples)
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

#include "easysocket.h"

extern int errno;



int global_server_defined;                /*  We've Got A Non-Default Port */
                                          /*  and non-default server address */
int global_server_port;                   /*  The Actual TCP Port */
char global_server_addr[256];             /*  the actual tcp address */
int server_type;                          /*  Server Type (See Above) */


int readn (int fd, char* ptr, int nbytes)

/*  Reads n bytes from a file or socket.  This version */
/*  works symmetrically regardless of which the stream */
/*  came from. */

/*  fd is the file or socket descriptor. */
/*  ptr is a buffer nbytes long. */
/*  nbytes is the number of bytes we wish to read. */
/*  readn fills ptr with the data, and returns either */
/*  a read error (<0) or the number of bytes that were */
/*  actually read (if this differs from nbytes, it's because */
/*  an eof was encountered). */

    {
    int nleft, nread;
    nleft=nbytes;
    while (nleft > 0)
        {
        nread = read(fd, ptr, nleft);
        if (nread < 0) return (nread);
        else if (nread == 0) break;
        nleft -=nread;
        ptr += nread;
        }
    return (nbytes-nleft);
    }


int writen(int fd, char* ptr, int nbytes)

/*  writes n bytes to a socket or file descriptor. */
/*  works properly for both (write does not) */

/*  fd is the file or socket descriptor */
/*  ptr is the data to write, nbytes long */
/*  nbytes is the size of the data */
/*  writen returns the number of bytes actually written out */
/*  (I Believe This Is Always 0) Or A Write Error (<0). */

    {
    int nleft, nwritten;
    nleft = nbytes;
    while (nleft > 0)
        {
        nwritten = write(fd, ptr, nleft);
        if (nwritten <= 0) return(nwritten);
        nleft -=nwritten;
        ptr +=nwritten;
        }
    return (nbytes-nleft);
    }

int readline (int fd, char* ptr, int maxlen)

/*  reads into ptr maxlen bytes from a socket or file descriptor */
/*  or until encountering a '\n', whichever comes first. */
/*  '\n' is included at the end of ptr, followed by '\0' (of course). */

/*  fd is the file or socket descriptor */
/*  ptr is the data to write, maxlen bytes long */
/*  maxlen is the maximum size of the data */
/*  readn fills ptr with the data, and returns either */
/*  a read error (<0) or the number of bytes that were */
/*  actually read (if this differs from maxlen, it's because */
/*  an eof was encountered, or because a '\n' was found). */

    {
    int n, rc;
    char c;
    for (n=1;n<maxlen;n++)
        {
        if ((rc=read(fd,&c,1)) == 1)
            {
            *ptr++=c;
            if (c=='\n') break;        /*  End Of Line */
            }
        else if (rc == 0)
            {
            if (n==1) return 0;        /*  EOF, No Data Read */
            else break;                /*  EOF, Some Data Was Read */
            }
        else return -1;                /*  Error! */
        }
    *ptr = 0;
    return n;
    }
    
    
    
/* Functions for client access */


int connect_to_socket()
    /*  Connects To Remote Socket And Returns.  Returning Is As Follows: */
    
        /*     < 0            Error.  Connecting To The Socket Failed. */
        /*                     Either Die Or Try Again, Or Whatever. */
        /*     >0            Success.  Here'S The Socket File Descriptor. */
        /*                     Process The Requests.  Be Sure To Tell */
        /*                     The Server That You'Re All Done.  Remember To */
        /*                     close the socket descriptor before quitting! */
    
    {
    int                    sockfd;
	int a;
	//char offarg=1;
    struct sockaddr_in    serv_addr;

    if (!global_server_defined) 
        {global_server_port=SERV_TCP_PORT;
         strcpy(global_server_addr,SERV_HOST_ADDR);}
        
    /* Lookup Hostname */

    /*  Here We Fill In The Structure "Serv_Addr" With The Address Of The */
    /*  server that we want to connect with... */
    
    bzero((char *) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family        = AF_INET;
    serv_addr.sin_addr.s_addr    = inet_addr(global_server_addr);
    serv_addr.sin_port            = htons(global_server_port);
    
    /*  Open A TCP Socket (An Internet Stream Socket) */
    
    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) <0)
        {
        fprintf(stderr,"Client Error:  Can't open stream socket.\n");
        return -1;
        }

    if ((a=connect(sockfd, (struct sockaddr*) &serv_addr, sizeof(serv_addr))) < 0)
        {
	  fprintf(stderr,"Client Error:  Can't connect to server.\n");
	  return -1;
	  
        }
	return sockfd;    
    }
    
    
    
    
    
/* Functions for server access */

int wait_on_socket()
  /*  Waits On A Socket.  When It Gets An Incoming Request, Forks And */
  /*  Returns, So A Child Can Process The Request.  Returning Is As Follows: */
    
  /*      < 0            Error. You'Re The Parent Process, And Waiting */
  /*                     On The Socket Failed.  Either Die Or Try Again, */
  /*                     or whatever. */
  /*     > 0        Success. You'Re A Child Process; Here'S The Socket File */
  /*                     Descriptor.  Process The Requests.  When You */
  /*                     are told that you're all done, exit(0).         */
    
    {
	unsigned int clilen;
    int                        sockfd,newsockfd,childpid;
    struct sockaddr_in        cli_addr, serv_addr;
           
    if (!global_server_defined) 
        {global_server_port=SERV_TCP_PORT;
         strcpy(global_server_addr,SERV_HOST_ADDR);}
    
    /*  Open A TCP Socket (An Internet Stream Socket). */

    if ((sockfd = socket(AF_INET, SOCK_STREAM, 0)) < 0)
        {
        fprintf(stderr,"Server Error:  Can't open stream socket.\n");
        return -1;
        }
        
	int optval = 1;
	setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &optval, sizeof(optval));
	signal(SIGPIPE, SIG_IGN);
	
    
    /*  bind our local address so that the client can send to us. */
    
    bzero((char*) &serv_addr, sizeof(serv_addr));
    serv_addr.sin_family        =AF_INET;
    serv_addr.sin_addr.s_addr    =htonl(INADDR_ANY);
    serv_addr.sin_port            =htons(global_server_port);
    
	if (bind(sockfd, (struct sockaddr*) &serv_addr, sizeof(serv_addr))<0)
        {
        fprintf(stderr,"Server Error:  Can't bind to local address.\n");
        return -1;
        }
        
	listen(sockfd,5);
    
    while (1)
        {
        /*  Now We Wait For A Connection From A Client Process, And Fork */
        /*  off a child process to do stuff... */
        
        clilen = sizeof(cli_addr);
        newsockfd = accept(sockfd, (struct sockaddr *) &cli_addr, &clilen);
    
        if (newsockfd <0)
            {
            fprintf(stderr,"Server Error:  Accept error.\n");
            close(sockfd);
            return -1;
            }

        if (server_type==SERVER_TYPE_PARALLEL)
            {
            if ((childpid = fork()) <0)
                {
                fprintf(stderr,"Server Error:  Fork error.\n");
                return -1;
                }
    
            else if (childpid == 0)            /*  child process */
                {
                close (sockfd);                /*  close old socket */
                return newsockfd;            /*  process the request */
                }
    
            else close (newsockfd);            /*  parent process */
            }

        else     /*  Server_Type==SERVER_TYPE_SERIAL */
            {
            close(sockfd);
            return newsockfd;
            }
        }
    }
    



/* 

   EXAMPLES
   In all the examples below, the we'll imagine the server address is 
   "128.128.128.128" and that the port is "8067".  The client connects
   to the server, issues a "hello", and then waits for a "hi", at which
   time it disconnects.   To use these examples, make sure to set the
   server address (at least) to the numerical address of the machine on
   which you're running the server. 
  
*/

/*
The first example is a one-shot serial server.
Note that when a server closes a connection, it
takes the OS a little while to realise the socket's been closed, so the
program may fail for a few minutes, unable to get a socket binding.  Be
patient!  You could modify this with a while(1) to do a looping serial server,
but be warned that the OS won't release the socket for up to a minute
or so after the connection has been closed, so you'll get -1 errors
from the wait_on_socket. For simple stuff, it's easier just to ignore
them in a looping seerial server instead of quitting like I've done below. 
*/
