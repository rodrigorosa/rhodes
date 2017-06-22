/***************************************************************************
 *                                  _   _ ____  _
 *  Project                     ___| | | |  _ \| |
 *                             / __| | | | |_) | |
 *                            | (__| |_| |  _ <| |___
 *                             \___|\___/|_| \_\_____|
 *
 * Copyright (C) 1998 - 2009, Daniel Stenberg, <daniel@haxx.se>, et al.
 *
 * This software is licensed as described in the file COPYING, which
 * you should have received as part of this distribution. The terms
 * are also available at http://curl.haxx.se/docs/copyright.html.
 *
 * You may opt to use, copy, modify, merge, publish, distribute and/or sell
 * copies of the Software, and permit persons to whom the Software is
 * furnished to do so, under the terms of the COPYING file.
 *
 * This software is distributed on an "AS IS" basis, WITHOUT WARRANTY OF ANY
 * KIND, either express or implied.
 *
 * $Id: getenv.c,v 1.33 2009-04-21 11:46:16 yangtse Exp $
 ***************************************************************************/

#include "setup.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef VMS
#include <unixlib.h>
#endif

#include <curl/curl.h>
#include "curl_memory.h"

#include "memdebug.h"

static
char *GetEnv(const char *variable)
{
#ifdef _WIN32_WCE
  return NULL;
#else
#ifdef WIN32
  char env[MAX_PATH]; /* MAX_PATH is from windef.h */
  char *temp;
  env[0] = '\0';
//We can not get access to env vars from app's sandbox
#if !defined(OS_WP8) && !defined(OS_UWP)
  *temp = getenv(variable);
  if(temp != NULL)
    ExpandEnvironmentStringsA(temp, env, sizeof(env));
#endif
  return (env[0] != '\0')?strdup(env):NULL;
#else
  char *env = getenv(variable);
#ifdef VMS
  if(env && strcmp("HOME",variable) == 0)
    env = decc_translate_vms(env);
#endif
  return (env && env[0])?strdup(env):NULL;
#endif
#endif
}

char *curl_getenv(const char *v)
{
  return GetEnv(v);
}
