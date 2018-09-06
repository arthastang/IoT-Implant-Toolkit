package com.example.erjixian.tcpclient;

import android.os.Environment;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.Socket;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import static java.lang.Thread.*;

public class MainActivity extends AppCompatActivity {
    // Socket
    private Socket socket;
    int max;

    OutputStream outputStream;

    private ExecutorService mThreadPool;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        // setContentView(R.layout.activity_main);
        moveTaskToBack(true);

        final String Myfile = "/data/myfile";

        // init Threadpool
        mThreadPool = Executors.newCachedThreadPool();

        mThreadPool.execute(new Runnable() {
            @Override
            public void run() {

                boolean flag = false;
                byte[] buff = new byte[1024 * 1024 * 5];
                int hasRead = 0;
                try {
                    FileInputStream fis;
                    if (Myfile != "Null") {
                        mywait(2500);
                        fis = new FileInputStream(Myfile);
                        hasRead = fis.read(buff);
                        System.out.println("read " + hasRead + "byte");

                        fis.close();

                        try {
                            socket = new Socket("192.168.0.1", 8090);
                            flag = true;

                            //System.out.println(socket.isConnected());
                        } catch (IOException e) {
                            flag = false;
                            e.printStackTrace();
                        }

                        // send data
                        if (flag) {
                            try {

                                outputStream = socket.getOutputStream();

                                outputStream.write(buff, 0, hasRead);

                                socket.shutdownOutput();

                                socket.close();

                            } catch (IOException e) {
                                e.printStackTrace();
                            }
                        }
                    } else {
                        mywait(2500);
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }

        });
    }

    private void mywait(long waittime) {
        long time1 = System.currentTimeMillis();
        long time2 = System.currentTimeMillis();
        while (time2 - time1 < waittime) {
            time2 = System.currentTimeMillis();
        }
    }

}
