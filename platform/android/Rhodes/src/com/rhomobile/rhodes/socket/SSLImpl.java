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

package com.rhomobile.rhodes.socket;

import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.io.OutputStream;
import java.io.RandomAccessFile;
import java.net.Socket;
import java.security.KeyManagementException;
import java.security.KeyStore;
import java.security.KeyStoreException;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.security.UnrecoverableKeyException;
import java.security.cert.Certificate;
import java.security.cert.CertificateException;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;
import java.util.ArrayList;
import java.util.List;

import javax.net.ssl.KeyManagerFactory;
import javax.net.ssl.SSLContext;
import javax.net.ssl.SSLSocket;
import javax.net.ssl.SSLSocketFactory;
import javax.net.ssl.TrustManager;
import javax.net.ssl.TrustManagerFactory;
import javax.net.ssl.X509TrustManager;

import android.util.Base64;

import com.rhomobile.rhodes.Logger;
import com.rhomobile.rhodes.RhoConf;
import com.rhomobile.rhodes.file.RhoFileApi;

import java.util.StringTokenizer;


public class SSLImpl {
	
	private static final String TAG = "SSLImplJava";
	
	private static SSLSocketFactory factory = null;
    private static SSLSocketFactory secureFactory = null;
    private static SSLSocketFactory mutualAuthFactory = null;

	
	private SSLSocket sock;

    //Used from jni
    @SuppressWarnings("unused")
    private int sockfd;

	private InputStream is;
	private OutputStream os;
	
	public native RhoSockAddr getRemoteSockAddr(int sockfd);
	
	private static class MyTrustManager implements X509TrustManager {
		
		public void checkClientTrusted(X509Certificate[] chain, String authType)
				throws CertificateException {
			// Nothing
			Logger.T(TAG, "checkClientTrusted");
		}

		public void checkServerTrusted(X509Certificate[] chain, String authType)
				throws CertificateException {
			// Nothing
			Logger.T(TAG, "checkServerTrusted");
		}

		public X509Certificate[] getAcceptedIssuers() {
			Logger.T(TAG, "getAcceptedIssuers");
			return new X509Certificate[0];
		}
		
	};
	
	private static class MySecureTrustManager implements X509TrustManager {
		private X509TrustManager mSysTrustManager;
		private X509TrustManager mCustomTrustManager;
		
		public MySecureTrustManager( X509TrustManager sysTrustManager, X509TrustManager customTrustManager ) {
			mSysTrustManager = sysTrustManager;
			mCustomTrustManager = customTrustManager;
		}

		@Override
		public void checkClientTrusted(X509Certificate[] chain, String authType) throws CertificateException {
			try {
				if ( mCustomTrustManager != null ) {
					mCustomTrustManager.checkClientTrusted(chain, authType);
				}
			} catch ( CertificateException e ) {
				if ( mSysTrustManager != null ) {
					mSysTrustManager.checkClientTrusted(chain, authType);
				}
			}
		}

		@Override
		public void checkServerTrusted(X509Certificate[] chain, String authType) throws CertificateException {
			try {
				if ( mCustomTrustManager != null ) {
					mCustomTrustManager.checkServerTrusted(chain, authType);
				}
			} catch ( CertificateException e ) {
				if ( mSysTrustManager != null ) {
					mSysTrustManager.checkServerTrusted(chain, authType);
				}
			}
			
		}

		@Override
		public X509Certificate[] getAcceptedIssuers() {
			X509Certificate ret[] = null;
			
			X509Certificate customAcceptedIssuers[] = (mCustomTrustManager!=null)?mCustomTrustManager.getAcceptedIssuers():new X509Certificate[0];
			X509Certificate sysAcceptedIssuers[] = (mSysTrustManager!=null)?mSysTrustManager.getAcceptedIssuers():new X509Certificate[0];
			
			if ( customAcceptedIssuers == null ) {
				customAcceptedIssuers = new X509Certificate[0];
			}
			
			if ( sysAcceptedIssuers == null ) {
				sysAcceptedIssuers = new X509Certificate[0];
			}
			
			int size = customAcceptedIssuers.length + sysAcceptedIssuers.length;
			
			if ( size > 0 ) {
				
		        ret = new X509Certificate[ size ];
		        
		        System.arraycopy(sysAcceptedIssuers, 0, ret, 0, sysAcceptedIssuers.length);
		        System.arraycopy(customAcceptedIssuers, 0, ret, sysAcceptedIssuers.length, customAcceptedIssuers.length);
			}
			
			return ret;
		}
		
	};
	
	private static void reportFail(String name, Exception e) {
		Logger.E(TAG, "Call of \"" + name + "\" failed: " + e.getClass().getSimpleName() + ": " + e.getMessage());
	}
    
    private static byte[] fileToBytes (File file) throws IOException {
        RandomAccessFile f = new RandomAccessFile(file, "r");
        
        try {
            long longlength = f.length();
            int length = (int) longlength;
            if (length != longlength) throw new IOException("File size >= 2 GB");
            
            byte[] data = new byte[length];
            f.readFully(data);
            return data;
        }
        finally {
            f.close();
        }
    }
	
	private static byte[] parseDERFromPEM(byte[] pem, String beginDelimiter, String endDelimiter) {
	    String data = new String(pem);
	    String[] tokens = data.split(beginDelimiter);
	    tokens = tokens[1].split(endDelimiter);
	    return Base64.decode(tokens[0],Base64.DEFAULT);
	}
    
	protected static X509Certificate generateCertificateFromDER(byte[] certBytes) throws CertificateException {
	    CertificateFactory factory = CertificateFactory.getInstance("X.509");        
	    return (X509Certificate)factory.generateCertificate(new ByteArrayInputStream(certBytes));
	}
    
    private static Certificate loadCertificate( File f ) {
        X509Certificate cert = null;
        
        Logger.I( TAG, "Loading SSL certificate from PEM file: " + f.getAbsolutePath() );
        
        try {
            
            byte[] fileBuf = fileToBytes( f );
            byte[] certBytes = parseDERFromPEM(fileBuf, "-----BEGIN CERTIFICATE-----", "-----END CERTIFICATE-----");
            cert = generateCertificateFromDER(certBytes);
            
            Logger.I( TAG, "SSL certificate loaded successfully" );

            
        } catch( IOException e ) {
            Logger.E( TAG, "Reading certificate file failed: " + e.getClass().getSimpleName() + ": " + e.getMessage() );
        } catch ( CertificateException e ) {
            Logger.E( TAG, "Certificate generation failed: " + e.getClass().getSimpleName() + ": " + e.getMessage() );
        }
        
        return cert;
    }
    
    private static List<Certificate> loadAllCertificates() {
        List<Certificate> certs = new ArrayList<Certificate>();
        
        Logger.I(TAG, "Loading all SSL certificates from config");

        
        if ( RhoConf.isExist( "CAFile" ) ) {
            
            String caFilePath = RhoConf.getString( "CAFile" );
            
            Logger.I(TAG, "CAFile found in config: loading certificate: " + caFilePath);

            File caFile = new File( caFilePath );
            
            if ( caFile.exists() ) {
                Certificate c = loadCertificate(caFile);
                if ( c != null ) {
                    certs.add( c );
                }
            } else {
                Logger.W(TAG, "CAFile config parameter exists, but file " + caFilePath + " not found." );
            }
        }
        
        if ( RhoConf.isExist( "CAPath" ) ) {
            String caFolderPath = RhoConf.getString( "CAPath" );
            
            Logger.I(TAG, "CAPath found in config: loading all certificates from " + caFolderPath);
            
            File caFolder = new File( caFolderPath );
            
            if ( caFolder.isDirectory() ) {
                File list[] = caFolder.listFiles();
                for ( File f : list ) {
                    Certificate c = loadCertificate(f);
                    if ( c != null ) {
                        certs.add( c );
                    }
                }
                
            } else {
                Logger.W(TAG, "CAPath config parameter exists, but folder " + caFolderPath + " not found." );
            }
        }
        
        Logger.I(TAG, "SSL certificates loaded: " + String.valueOf(certs.size()) );


        return certs;
    }
    
    private static SSLSocketFactory getSecureFactory() throws NoSuchAlgorithmException, KeyManagementException, CertificateException, KeyStoreException, IOException, UnrecoverableKeyException {
        Logger.I(TAG, "Creating secure SSL factory");
        
        SSLContext context = SSLContext.getInstance("TLS");
        
        // First, load all system installed certificates
        Logger.I(TAG, "Creating TrustManager for system certificates");        
        TrustManagerFactory systemTmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        systemTmf.init((KeyStore)null);        
        X509TrustManager systemTrustManager = (X509TrustManager)systemTmf.getTrustManagers()[0];

        // Create keystore for custom certificates
        KeyStore keystore = KeyStore.getInstance( KeyStore.getDefaultType() );
        keystore.load(null);
        
        List<Certificate> certs = loadAllCertificates();
        
        // Add loaded custom certificates to keystore
        if ( certs != null ) {
            for ( int i = 0; i < certs.size(); ++i ) {
                keystore.setCertificateEntry("cert-alias"+ String.valueOf(i),certs.get(i));
            }
        }
        
               
        Logger.I(TAG, "Creating TrustManager for custom certificates");        
        TrustManagerFactory tmf = TrustManagerFactory.getInstance(TrustManagerFactory.getDefaultAlgorithm());
        tmf.init(keystore);        
        X509TrustManager customTrustManager = (X509TrustManager)tmf.getTrustManagers()[0];
                
        KeyManagerFactory kmf = null;
        
        if ( RhoConf.isExist("clientSSLCertificate")) {        	
        	String clientCertPath = RhoConf.getString("clientSSLCertificate");
        	
        	Logger.I(TAG, "clientSSLCertificate is " + clientCertPath );

        	
        	if ( clientCertPath.length() > 0 ) {
                Logger.I(TAG, "Creating KeyManager for client certificates");
        		kmf = KeyManagerFactory.getInstance( KeyManagerFactory.getDefaultAlgorithm() );
        		
        		String password = "";
        		if (RhoConf.isExist("clientSSLCertificatePassword")) {
        			password = RhoConf.getString("clientSSLCertificatePassword");
        		}
        	
        		KeyStore clientKeystore = KeyStore.getInstance( "pkcs12" );
        		clientKeystore.load( RhoFileApi.open(clientCertPath), password.toCharArray() );
        		kmf.init(clientKeystore, password.toCharArray());
        	}
        }
       
        /* 
         * this really works only with first provided TrustManager, 
         * so we make our own wrapper which encapsulates both system installed and custom provided certificates
         */
        context.init( 
        		(kmf==null)?null:kmf.getKeyManagers(), 
        		new TrustManager[] { new MySecureTrustManager( systemTrustManager, customTrustManager ) }, 
        		new SecureRandom()
        );
        
        Logger.I(TAG, "Secure SSL factory initialization completed");
        
        return (SSLSocketFactory)context.getSocketFactory();

    }
    	
	private static SSLSocketFactory getFactory(boolean verify) throws NoSuchAlgorithmException, KeyManagementException, CertificateException, KeyStoreException, IOException, UnrecoverableKeyException {
		if (verify) {
			//if ( secureFactory == null ) {
				secureFactory = getSecureFactory();
			//}
           	return secureFactory;
        }
		
		if (factory == null) {
			SSLContext context = SSLContext.getInstance("TLS");
			TrustManager[] managers = {new MyTrustManager()};
			context.init(null, managers, new SecureRandom());
            factory = context.getSocketFactory();
		}
		return factory;
	}
	
	public boolean connect(int fd, boolean sslVerifyPeer, String hostname ) {
		try {
            Logger.I(TAG, "SSL connect to " + hostname);

            RhoSockAddr remote = getRemoteSockAddr(fd);
            Socket s = new RhoSocket(fd, remote);
            SSLSocketFactory f = getFactory(sslVerifyPeer);

            StringTokenizer st = new StringTokenizer( hostname, ":" );
            String host = st.nextToken();

            SSLSocket aSock = (SSLSocket)f.createSocket(s, host, remote.port, true);
            aSock.setUseClientMode(true);

            synchronized (this) {
                sock = aSock;
                os = sock.getOutputStream();
                is = sock.getInputStream();
                sockfd = fd;
            }
            return true;
		}
		catch (Exception e) {
			reportFail("connect", e);
			e.printStackTrace();
			return false;
		}
	}
	
	public void shutdown() {
		try {
			if (sock != null) {
                synchronized (this) {
                    if (sock != null) {
                        sock.close();
                        sock = null;
                        os = null;
                        is = null;

                        //TODO: check file descriptor is closed gracefully
                        sockfd = -1;
                    }
                }
			}
		}
		catch (Exception e) {
			reportFail("shutdown", e);
		}
	}
	
	public boolean send(byte[] data) {
		try {
			if (os != null) {
                OutputStream aOs = null;
                synchronized (this) {
                    if (os != null)
                        aOs = os;
                }
                if (aOs != null) {
                    aOs.write(data);
                    return true;
                }
			}
		}
		catch (Exception e) {
			reportFail("send", e);
		}
        return false;
	}
	
	public int recv(byte[] data) {
		try {
			if (is != null) {
                InputStream aIs = null;
                synchronized (this) {
                    if (is != null)
                        aIs = is;
                }
                if (aIs != null) {
                    int size = data.length;
                    int n = is.read(data, 0, size);
                    return n;
                }
			}
		}
		catch (Exception e) {
			reportFail("recv", e);
		}
        return -1;
    }

}
