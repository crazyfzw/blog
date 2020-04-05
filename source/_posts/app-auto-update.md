---
title: 轻松实现APP自动检测更新
date: 2016-08-24 22:52:01
categories:
- Android
tags:
- APP自动更新
- Android auto update 
- 应用自动检测更新
---

**概述：**为了以快速并且节约的方式让APP更新版本，通常需要在APP内增加自动检测更新新版本的功能。



## 运行截图：

![](/images/2016082401.jpg)![](/images/2016082402.jpg)![](/images/2016082403.jpg)![](/images/2016082404.jpg)  

<!--more-->

     



## 实现：4个步骤

![](/images/2016082405.png) 





### 1.在服务端放置存储版本信息的文件

  一般以json格式保存必要的信息：apk文件下载地址、版本号、更新内容

{% codeblock lang:xml %}

{
  "url":"http://crazyfzw.github.io/demo/auto-update-version/new-version-v2.0.apk",
  "versionCode":2,
  "updateMessage":"[1]新增视频弹幕功能<br/>[2]优化离线缓存功能<br/>[3]增强了稳定性"
}
{% endcodeblock %}

### 2.继承AsyncTask创建一个异步任务去下载版本信息文件

 从服务器取得版本信息，与本地apk对比版本号，判断是否有更新，若有，则以Dialog让用户选择是否更新，若用户选择更新，则调用服务去完成apk文件的下载



**CheckVersionInfoTask.java**

{% codeblock lang:java %}
/**
 * 
 */
public class CheckVersionInfoTask extends AsyncTask<Void, Void, String> {

    private static final String TAG = "CheckVersionInfoTask";
    private ProgressDialog dialog;
    private Context mContext;
    private boolean mShowProgressDialog;
    private static final String VERSION_INFO_URL = "http://crazyfzw.github.io/demo/auto-update-version/update.json";

    public CheckVersionInfoTask(Context context, boolean showProgressDialog) {
        this.mContext = context;
        this.mShowProgressDialog = showProgressDialog;

    }

    //初始化显示Dialog
    protected void onPreExecute() {
        if (mShowProgressDialog) {
            dialog = new ProgressDialog(mContext);
            dialog.setMessage(mContext.getString(R.string.check_new_version));
            dialog.show();
        }
    }

    //在后台任务(子线程)中检查服务器的版本信息
    @Override
    protected String doInBackground(Void... params) {
        return getVersionInfo(VERSION_INFO_URL);
    }


    //后台任务执行完毕后，解除Dialog并且解析return返回的结果
    @Override
    protected void onPostExecute(String result) {

        if (dialog != null && dialog.isShowing()) {
            dialog.dismiss();
        }

        if (!TextUtils.isEmpty(result)) {
            parseJson(result);
        }
    }


    /**
     * 从服务器取得版本信息
     * {
       "url":"http://crazyfzw.github.io/demo/auto-update-version/new-version-v2.0.apk",
        "versionCode":2,
       "updateMessage":"[1]新增视频弹幕功能<br/>[2]优化离线缓存功能<br/>[3]增强了稳定性"
       }
     * @return
     */
    public String getVersionInfo(String urlStr){
        HttpURLConnection uRLConnection = null;
        InputStream is = null;
        BufferedReader buffer = null;
        String result = null;
        try {
            URL url = new URL(urlStr);
            uRLConnection = (HttpURLConnection) url.openConnection();
            uRLConnection.setRequestMethod("GET");
            is = uRLConnection.getInputStream();
            buffer = new BufferedReader(new InputStreamReader(is));
            StringBuilder strBuilder = new StringBuilder();
            String line;
            while ((line = buffer.readLine()) != null) {
                strBuilder.append(line);
            }
            result = strBuilder.toString();
        } catch (Exception e) {
            Log.e(TAG, "http post error");
        } finally {
            if (buffer != null) {
                try {
                    buffer.close();
                } catch (IOException ignored) {
                }
            }
            if (is != null) {
                try {
                    is.close();
                } catch (IOException ignored) {

                }
            }
            if (uRLConnection != null) {
                uRLConnection.disconnect();
            }
        }
        return result;
    }

    /**
     *
     * @param result
     */
    private void parseJson(String result) {
        try {
            JSONObject obj = new JSONObject(result);
            String apkUrl = obj.getString("url");                 //APK下载路径
            String updateMessage = obj.getString("updateMessage");//版本更新说明
            int apkCode = obj.getInt("versionCode");              //新版APK对于的版本号

            //取得已经安装在手机的APP的版本号 versionCode
            int versionCode = getCurrentVersionCode();

            //对比版本号判断是否需要更新
            if (apkCode > versionCode) {

                    showDialog(updateMessage, apkUrl);

            } else if (mShowProgressDialog) {
                Toast.makeText(mContext, mContext.getString(R.string.there_no_new_version), Toast.LENGTH_SHORT).show();
            }

        } catch (JSONException e) {
            Log.e(TAG, "parse json error");
        }
    }

    /**
     * 取得当前版本号
     * @return
     */
    public int getCurrentVersionCode() {

            try {
                return mContext.getPackageManager().getPackageInfo(mContext.getPackageName(), 0).versionCode;
            } catch (PackageManager.NameNotFoundException ignored) {
            }
        return 0;
    }


    /**
     * 显示对话框提示用户有新版本，并且让用户选择是否更新版本
     * @param content
     * @param downloadUrl
     */
    public void showDialog(String content, final String downloadUrl) {
            AlertDialog.Builder builder = new AlertDialog.Builder(mContext);
            builder.setTitle(R.string.dialog_choose_update_title);
            builder.setMessage(Html.fromHtml(content))
                    .setPositiveButton(R.string.dialog_btn_confirm_download, new DialogInterface.OnClickListener() {
                        public void onClick(DialogInterface dialog, int id) {
                            //下载apk文件
                            goToDownloadApk(downloadUrl);
                        }
                    })
                    .setNegativeButton(R.string.dialog_btn_cancel_download, new DialogInterface.OnClickListener() {
                        public void onClick(DialogInterface dialog, int id) {
                        }
                    });

            AlertDialog dialog = builder.create();
            //点击对话框外面,对话框不消失
            dialog.setCanceledOnTouchOutside(false);
            dialog.show();
    }

    /**
     * 用intent启用DownloadService服务去下载AKP文件
     * @param downloadUrl
     */
    private void goToDownloadApk(String downloadUrl) {
        Intent intent = new Intent(mContext, DownloadApkService.class);
        intent.putExtra("apkUrl", downloadUrl);
        mContext.startService(intent);
    }
}
{% endcodeblock %}


注：其中用到的 StorageUtils.getCacheDirectory(context) 是用于取得应用在手机缓存目录


**StorageUtils.java**

{% codeblock lang:java %}

final class StorageUtils {

    private static final String TAG = "StorageUtils";
    private static final String EXTERNAL_STORAGE_PERMISSION = "android.permission.WRITE_EXTERNAL_STORAGE";

    private StorageUtils() {
    }

    /**
     * Returns application cache directory. Cache directory will be created on SD card
     * ("/Android/data/[app_package_name]/cache") if card is mounted and app has appropriate permission. Else -
     * Android defines cache directory on device's file system.
     */
    public static File getCacheDirectory(Context context) {
        File appCacheDir = null;
        if (MEDIA_MOUNTED.equals(Environment.getExternalStorageState()) && hasExternalStoragePermission(context)) {
            appCacheDir = getExternalCacheDir(context);
        }
        if (appCacheDir == null) {
            appCacheDir = context.getCacheDir();
        }
        if (appCacheDir == null) {
            Log.w(TAG, "Can't define system cache directory! The app should be re-installed.");
        }
        return appCacheDir;
    }

    private static File getExternalCacheDir(Context context) {
        File dataDir = new File(new File(Environment.getExternalStorageDirectory(), "Android"), "data");
        File appCacheDir = new File(new File(dataDir, context.getPackageName()), "cache");
        if (!appCacheDir.exists()) {
            if (!appCacheDir.mkdirs()) {
                Log.w(TAG, "Unable to create external cache directory");
                return null;
            }
            try {
                new File(appCacheDir, ".nomedia").createNewFile();
            } catch (IOException e) {
                Log.i(TAG, "Can't create \".nomedia\" file in application external cache directory");
            }
        }
        return appCacheDir;
    }

    private static boolean hasExternalStoragePermission(Context context) {
        int perm = context.checkCallingOrSelfPermission(EXTERNAL_STORAGE_PERMISSION);
        return perm == PackageManager.PERMISSION_GRANTED;
    }
}
{% endcodeblock %}


### 3.创建服务(Service)完成apk文件的下载，下载完成后调用系统的安装程序完成安装

**DownloadApkService.java**

{% codeblock lang:java%}

public class DownloadApkService extends IntentService{

    private static final int BUFFER_SIZE = 10 * 1024; //缓存大小
    private static final String TAG = "DownloadService";

    private static final int NOTIFICATION_ID = 0;
    private NotificationManager mNotifyManager;
    private NotificationCompat.Builder mBuilder;

    public DownloadApkService() {
        super("DownloadApkService");
    }

    /**
     * 在onHandleIntent中下载apk文件
     * @param intent
     */
    @Override
    protected void onHandleIntent(Intent intent) {

        //初始化通知，用于显示下载进度
        mNotifyManager = (NotificationManager) getSystemService(Context.NOTIFICATION_SERVICE);
        mBuilder = new NotificationCompat.Builder(this);
        String appName = getString(getApplicationInfo().labelRes);
        int icon = getApplicationInfo().icon;
        mBuilder.setContentTitle(appName).setSmallIcon(icon);

        String urlStr = intent.getStringExtra("apkUrl"); //从intent中取得apk下载路径

        InputStream in = null;
        FileOutputStream out = null;
        try {
            //建立下载连接
            URL url = new URL(urlStr);
            HttpURLConnection urlConnection = (HttpURLConnection) url.openConnection();
            urlConnection.setRequestMethod("GET");
            urlConnection.setDoOutput(false);
            urlConnection.setConnectTimeout(10 * 1000);
            urlConnection.setReadTimeout(10 * 1000);
            urlConnection.setRequestProperty("Connection", "Keep-Alive");
            urlConnection.setRequestProperty("Charset", "UTF-8");
            urlConnection.setRequestProperty("Accept-Encoding", "gzip, deflate");
            urlConnection.connect();

            //以文件流读取数据
            long bytetotal = urlConnection.getContentLength(); //取得文件长度
            long bytesum = 0;
            int byteread = 0;
            in = urlConnection.getInputStream();
            File dir = StorageUtils.getCacheDirectory(this); //取得应用缓存目录
            String apkName = urlStr.substring(urlStr.lastIndexOf("/") + 1, urlStr.length());//取得apK文件名
            File apkFile = new File(dir, apkName);
            out = new FileOutputStream(apkFile);
            byte[] buffer = new byte[BUFFER_SIZE];

            int limit = 0;
            int oldProgress = 0;
            while ((byteread = in.read(buffer)) != -1) {
                bytesum += byteread;
                out.write(buffer, 0, byteread);
                int progress = (int) (bytesum * 100L / bytetotal);
                // 如果进度与之前进度相等，则不更新，如果更新太频繁，则会造成界面卡顿
                if (progress != oldProgress) {
                    updateProgress(progress);
                }
                oldProgress = progress;
            }

            // 下载完成,调用installAPK开始安装文件
            installAPk(apkFile);
            Log.d("调试","download apk finish");
            mNotifyManager.cancel(NOTIFICATION_ID);

        } catch (Exception e) {
            Log.e(TAG, "download apk file error");
        } finally {
            if (out != null) {
                try {
                    out.close();
                } catch (IOException ignored) {

                }
            }
            if (in != null) {
                try {
                    in.close();
                } catch (IOException ignored) {

                }
            }
        }
    }

    /**
     * 实时更新下载进度条显示
     * @param progress
     */
    private void updateProgress(int progress) {
        //"正在下载:" + progress + "%"
        mBuilder.setContentText(this.getString(R.string.dialog_choose_update_content, progress)).setProgress(100, progress, false);
        PendingIntent pendingintent = PendingIntent.getActivity(this, 0, new Intent(), PendingIntent.FLAG_CANCEL_CURRENT);
        mBuilder.setContentIntent(pendingintent);
        mNotifyManager.notify(NOTIFICATION_ID, mBuilder.build());
    }


    /**
     * 调用系统安装程序安装下载好的apk
     * @param apkFile
     */
    private void installAPk(File apkFile) {
        Intent intent = new Intent(Intent.ACTION_VIEW);
        //如果没有设置SDCard写权限，或者没有sdcard,apk文件保存在内存中，需要授予权限才能安装
        try {
            String[] command = {"chmod", "777", apkFile.toString()}; //777代表权限 rwxrwxrwx
            ProcessBuilder builder = new ProcessBuilder(command);
            builder.start();
        } catch (IOException ignored) {
        }
        intent.setDataAndType(Uri.fromFile(apkFile), "application/vnd.android.package-archive");
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
        startActivity(intent);
    }
}

{% endcodeblock %}



### 4.最后一步，new并execute我们写好的异步任务就行了。

```
new CheckVersionInfoTask(MainActivity.this, true).execute();
```


**注：记得在AndroidManifest.xml中生明权限及注册Service哦**

```
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />

```

本案例完整源码：[https://github.com/crazyfzw/AppAutoCheckUpdate](https://github.com/crazyfzw/AppAutoCheckUpdate)



## 用到的相关知识：

异步任务AsysTask的相关用法：郭霖的Android AsyncTask完全解析，带你从源码的角度彻底理解

自动启动线程执行耗时任务并会自动停止的服务 IntentService的用法：Android理解：IntentService
