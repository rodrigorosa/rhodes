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

#include "common/RhoPort.h"
#undef null
#include <QDir>
#include <QQueue>
#include <QPair>

bool RemoveDirectory(QString &path, bool deleteDir)
{
    QDir aDir(path);
    bool has_err = false;
    if (aDir.exists()) {
        QFileInfoList entries = aDir.entryInfoList(QDir::NoDot | QDir::NoDotDot | QDir::Dirs | QDir::Files);
        int count = entries.size();
        for (int idx = 0; ((idx < count) && (!has_err)); idx++) {
            QFileInfo entryInfo = entries[idx];
            QString path = entryInfo.absoluteFilePath();
            if (entryInfo.isDir()) {
                has_err = RemoveDirectory(path, true);
            } else {
                QFile file(path);
                if (!file.remove())
                    has_err = true;
            }
        }
        if (deleteDir && (!aDir.rmdir(aDir.absolutePath())))
            has_err = true;
    }
    return has_err;
}

void CopyDirectory(const QString& sourceFolder,const QString& destFolder)
{
    QQueue< QPair<QString, QString> > queue;

    queue.enqueue(qMakePair(sourceFolder, destFolder));

    while (!queue.isEmpty())
    {
        QPair<QString, QString> pair = queue.dequeue();
        QDir sourceDir(pair.first);
        QDir destDir(pair.second);

        if(!sourceDir.exists())
            continue;

        if(!destDir.exists())
            destDir.mkpath(pair.second);

        QStringList files = sourceDir.entryList(QDir::Files);
        for(int i = 0; i < files.count(); i++)
        {
            QString srcName = pair.first + "/" + files.at(i);
            QString destName = pair.second + "/" + files.at(i);
            QFile::copy(srcName, destName);
        }

        QStringList dirs = sourceDir.entryList(QDir::AllDirs | QDir::NoDot | QDir::NoDotDot);
        for(int i = 0; i < dirs.count(); i++)
        {
            QString srcName = pair.first + "/" + dirs.at(i);
            QString destName = pair.second + "/" + dirs.at(i);
            queue.enqueue(qMakePair(srcName, destName));
        }
    }
}

extern "C" {

void rho_file_impl_delete_files_in_folder(const char *szFolderPath)
{
    QString path = QString::fromUtf8(szFolderPath);
    RemoveDirectory(path, false);
}

void rho_file_impl_delete_folder(const char* szFolderPath)
{
    QString path = QString::fromUtf8(szFolderPath);
    RemoveDirectory(path, true);
}

void rho_file_impl_copy_folders_content_to_another_folder(const char* szSrcFolderPath, const char* szDstFolderPath)
{
    QString src = QString::fromUtf8(szSrcFolderPath);
    QString dst = QString::fromUtf8(szDstFolderPath);
    CopyDirectory(src, dst);
}

} //extern "C"
