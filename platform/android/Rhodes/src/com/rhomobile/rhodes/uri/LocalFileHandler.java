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

package com.rhomobile.rhodes.uri;

import java.net.URISyntaxException;
import java.util.regex.Pattern;

import com.rhomobile.rhodes.LocalFileProvider;
import com.rhomobile.rhodes.Logger;

import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.webkit.URLUtil;
import android.webkit.MimeTypeMap;

public class LocalFileHandler implements UriHandler
{
    private static final String TAG = "LocalFileHandler";
    private static final Pattern mHtmlPattern = Pattern.compile(".*\\.(html|htm)$");
    private static final Pattern mImagePattern = Pattern.compile(".*\\.(jpg|jpeg|png|gif|svg)$");
    private Context ctx;
    
    public LocalFileHandler(Context c) {
        ctx = c;
    }

    private static boolean isHtmlUrl(String url) {
        Logger.T(TAG, "Looking for html extension: " + url);
        return mHtmlPattern.matcher(url).matches();
    }

    private static boolean isImageUrl(String url) {
        Logger.T(TAG, "Looking for image extension: " + url);
        return mImagePattern.matcher(url).matches();
    }

    public boolean handle(String url) throws URISyntaxException {

        if (!URLUtil.isFileUrl(url))
            return false;
        
        String noAnchorUrl = URLUtil.stripAnchor(url);
        if (isHtmlUrl(noAnchorUrl)) {
            return false;
        }

        Logger.D(TAG, "Handle URI externally: " + url);

        int intentFlags = 0;
        Uri path = Uri.parse(url);

        //Uri newUri = LocalFileProvider.overrideUri(path);
        Uri newUri = LocalFileProvider.overrideSystemUri(path);
        if(newUri != null) {
            intentFlags = Intent.FLAG_GRANT_READ_URI_PERMISSION;
            url = Uri.decode(newUri.toString());
        }
        intentFlags=Intent.FLAG_GRANT_READ_URI_PERMISSION;
        Intent intent = Intent.parseUri(url, intentFlags);
        if(newUri==null && url.contains("file://"))
       {
    	   intent.setAction(Intent.ACTION_VIEW);
    	    try{
        	   String extension = MimeTypeMap.getFileExtensionFromUrl(url);
        	   String mimeType = MimeTypeMap.getSingleton().getMimeTypeFromExtension(extension);
        	    if(mimeType!=null && mimeType.contains("image"))
        	    	intent.setDataAndType(path, "image/*");
        	    else if(mimeType!=null && mimeType.contains("audio"))
        	    	intent.setDataAndType(path, "audio/*");
				else if(mimeType!=null && mimeType.contains("video"))
        	    	intent.setDataAndType(path, "video/*");	
        	    else
        	    	intent.setDataAndType(path, "*/*");
        	   }
        	   catch(Exception ex)
        	   {
        		   Logger.E(TAG, ex.getMessage());
        		   intent.setDataAndType(path, "*/*");
        	   }
    	   
    	
   	   }
        ctx.startActivity(Intent.createChooser(intent, "Open in..."));

        return true;
    }
    
}
