/*------------------------------------------------------------------------
* (The MIT License)
* 
* Copyright (c) 2008-2011 Rhomobile, Inc.
* 
* Permission is hereby granted, free of charge, to any person obtaining a copy
* of this software and associated documentation files (the "Software"), to deal
* in the Software without restriction, including without limitation the rights
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
* copies of the Software, and to permit persons to whom the Software is
* furnished to do so, subject to the following conditions:
* 
* The above copyright notice and this permission notice shall be included in
* all copies or substantial portions of the Software.
* 
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
* THE SOFTWARE.
* 
* http://rhomobile.com
*------------------------------------------------------------------------*/

#include "stdafx.h"
#include "LogServer.h"
#include <vector>

#define DEFAULT_BUFLEN 1024
#define DEFAULT_PORT "11000"
#define DEFAULT_HOST _T("localhost")

LogServer::LogServer(TCHAR* logFilePath, TCHAR* log_port) 
	: m_logFilePath(logFilePath)
	, m_hLogFile(INVALID_HANDLE_VALUE)
	, m_logPort(log_port)
    , m_logHost(DEFAULT_HOST)
{
}

LogServer::~LogServer(void)
{
	::CloseHandle(m_hLogFile);

	closesocket(m_listenSocket);
	m_listenSocket = INVALID_SOCKET;
}

//
bool LogServer::init()
{
	USES_CONVERSION;

	addrinfo *result = NULL, hints;

	memset(&hints, 0, sizeof (hints));
	hints.ai_family   = AF_INET;
	hints.ai_socktype = SOCK_STREAM;
	hints.ai_protocol = IPPROTO_TCP;
	hints.ai_flags    = AI_PASSIVE;

	createFile();

	// Resolve the local address and port to be used by the server
	int iResult = getaddrinfo(T2A(m_logHost), T2A(m_logPort), &hints, &result);
	
	if (iResult != 0) 
	{
		printf("getaddrinfo failed: %d\n", iResult);
		return false;
	}

	// Create a SOCKET for the server to listen for client connections
	m_listenSocket = socket(result->ai_family, result->ai_socktype, result->ai_protocol);

	if (m_listenSocket == INVALID_SOCKET) {
		printf("Error at socket(): %ld\n", WSAGetLastError());
		freeaddrinfo(result);
		return false;
	}

	    // Setup the TCP listening socket
    iResult = bind( m_listenSocket, result->ai_addr, (int)result->ai_addrlen);
    if (iResult == SOCKET_ERROR) {
        printf("bind failed with error: %d\n", WSAGetLastError());
        freeaddrinfo(result);
        closesocket(m_listenSocket);
        return false;
    }

	if ( listen( m_listenSocket, SOMAXCONN ) == SOCKET_ERROR ) {
		printf( "Listen failed with error: %ld\n", WSAGetLastError() );
		closesocket(m_listenSocket);
		return false;
	}

	return true;
}

//
void LogServer::run()
{
	char recvbuf[DEFAULT_BUFLEN];
	int iResult = 0;
	int recvbuflen = DEFAULT_BUFLEN;
	SOCKET clientSocket = INVALID_SOCKET;
	recvbuf[0] = 0;

	// Accept a client socket
	clientSocket = accept(m_listenSocket, NULL, NULL);

	if (clientSocket == INVALID_SOCKET) 
	{
		printf("accept failed: %d\n", WSAGetLastError());
		closesocket(m_listenSocket);
		return;
	}

	// Receive until the peer shuts down the connection
	do 
	{
		iResult = recv(clientSocket, recvbuf, recvbuflen, 0);

		if (iResult > 0)
		{
			recvbuf[iResult - 1] = 0;
			printf("%s\n", recvbuf);
			writeToFile(recvbuf, iResult);
		}
		else if (iResult == 0)
		{
			printf("Connection closing...\n");
		}
		else 
		{
			printf("recv failed: %d\n", WSAGetLastError());
			closesocket(clientSocket);
			return;
		}

	} 
	while (iResult > 0);
}

bool LogServer::createFile()
{
	m_hLogFile = CreateFile(m_logFilePath, GENERIC_WRITE, FILE_SHARE_READ | FILE_SHARE_WRITE, NULL, 
		CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, NULL);

	if (INVALID_HANDLE_VALUE == m_hLogFile) {
		_tprintf( TEXT("Unable to open host file\n"));
		return false;
	}
	
	return true;
}

bool LogServer::writeToFile(const char* dataBuf, const int dataLen)
{
	static char crlfBuf[2] = {'\r','\n'};

	if (m_hLogFile != INVALID_HANDLE_VALUE)
	{
		char convbuf[2*DEFAULT_BUFLEN];
		int buflen = 0;
		char *src = (char*)dataBuf;
		char *dst = convbuf;

		for (int i=0; i<dataLen; ++i) {
			if (*src != '\0') {
				if (*src == '\n') {
					*(dst++) = '\r';
					++buflen;
				}
				*(dst++) = *(src++);
				++buflen;
			} else
				++src;
		}

		DWORD dwNumWritten = 0;
		if (!WriteFile(m_hLogFile, convbuf, buflen, &dwNumWritten, NULL)) {
			_tprintf( TEXT("Error !!! writing log file\n"));
			return false;
		}

		if (!WriteFile(m_hLogFile, crlfBuf, sizeof(crlfBuf), &dwNumWritten, NULL)) {
			_tprintf( TEXT("Error !!! writing log file\n"));
			return false;
		}

	}

	return true;
}