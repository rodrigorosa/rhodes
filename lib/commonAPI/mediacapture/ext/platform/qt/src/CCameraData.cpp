#include "CCameraData.h"
#include "generated/cpp/ICamera.h"

QHash<QString, CCameraData *> CCameraData::camerasKeeper;

QMutex *CCameraData::getMutex()
{
    static QMutex mutex;
    return & mutex;
}
CCameraData::CCameraData():CameraDialogController(0)
{
    cameraType.clear();
    cameraID.clear();
}

const QString CCameraData::getCameraType() const
{
    return cameraType;
}

const QString CCameraData::getCameraID() const
{
    return cameraID;
}

const QList<QString> CCameraData::getKeys()
{
    return camerasKeeper.keys();
}

const QList<CCameraData *> CCameraData::getValues()
{
    return camerasKeeper.values();
}


const CCameraData *CCameraData::addNewCamera(QCameraInfo &info){
    CCameraData * data = new CCameraData(info);
    camerasKeeper.insert(data->getCameraID(), data);
    return data;
}


void CCameraData::cleanAll(){
QMutexLocker locker(getMutex());
    foreach (CCameraData * cameraData, camerasKeeper) {
        cameraData->deleteLater();
        camerasKeeper.clear();
    }
}

const bool CCameraData::isEmpty()
{
    return camerasKeeper.isEmpty();
}

CCameraData *CCameraData::getCameraData(QString &ID)
{
    QMutexLocker locker(getMutex());
    if(camerasKeeper.contains(ID)){return camerasKeeper.value(ID);
    }else{return nullptr;}
}


CCameraData::CCameraData(QCameraInfo &info):CameraDialogController(0){
    this->info = info;
    cameraID = QString::number(camerasKeeper.size() + 1);
    if (info.position() == QCamera::BackFace){cameraType = QString::fromStdString(rho::ICamera::CAMERA_TYPE_BACK);}
    else{cameraType = QString::fromStdString(rho::ICamera::CAMERA_TYPE_FRONT);}
}


void CCameraData::showView(rho::apiGenerator::CMethodResult &oResult)
{
    if (dialogExists()) return;
    CameraDialogBuilder * builder = new CameraDialogBuilder(this, info, oResult, getQMainWindow());
    emit builder->run();
}

QMainWindow *CCameraData::getQMainWindow()
{
    return IExecutable::getMainWindow();
}

void CCameraData::choosePicture(rho::apiGenerator::CMethodResult& oResult) {
    ImageFileNameGetter * getter = new ImageFileNameGetter(QThread::currentThread(),oResult,getQMainWindow());
    getter->run();
}

