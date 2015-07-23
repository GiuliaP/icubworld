/* 
 * Copyright (C) 2015 iCub Facility - Istituto Italiano di Tecnologia
 * Author: Giulia Pasquale
 * email:  giulia.pasquale@iit.it
 * Permission is granted to copy, distribute, and/or modify this program
 * under the terms of the GNU General Public License, version 2 or any
 * later version published by the Free Software Foundation.
 *
 * A copy of the license can be found at
 * http://www.robotcub.org/icub/license/gpl.txt
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
 * Public License for more details
*/

#include <yarp/os/Network.h>
#include <yarp/os/RFModule.h>
#include <yarp/os/Time.h>
#include <yarp/os/BufferedPort.h>
#include <yarp/os/RateThread.h>
#include <yarp/os/Semaphore.h>
#include <yarp/os/RpcClient.h>
#include <yarp/os/PortReport.h>
#include <yarp/os/Stamp.h>

#include <yarp/sig/Vector.h>
#include <yarp/sig/Image.h>

#include <yarp/math/Math.h>
#include <yarp/math/Rand.h>

#include <highgui.h>
#include <cv.h>

#include <stdio.h>
#include <string>
#include <deque>
#include <algorithm>
#include <vector>
#include <iostream>
#include <fstream>
#include <list>

#include <storerThread.h>

using namespace std;
using namespace yarp;
using namespace yarp::os;
using namespace yarp::sig;
using namespace yarp::math;


    bool StorerThread::threadInit()
    {
        verbose=rf.check("verbose");

        string name=rf.find("name").asString().c_str();

        bufferSize = rf.check("BufferSize",Value(50),"Buffer Size").asInt();
        confidence_width=rf.check("confidence_width",Value(500)).asInt();
        confidence_height=rf.check("confidence_height",Value(500)).asInt();

        //Ports
        //-----------------------------------------------------------
        //input
        port_in_scores.open(("/"+name+"/scores:i").c_str());

        //output
        port_out_confidence.open(("/"+name+"/confidence:o").c_str());
        //------------------------------------------------------------

        current_class="?";
//        true_class="?";

        return true;
    }

    void StorerThread::run()
    {
        mutex.wait();
        Bottle *bot = port_in_scores.read(false);

        if(bot==NULL || bot->size()<1)
        {
            mutex.post();
            return;
        }

        string true_class = bot->pop().asString().c_str();
        scores_buffer.push_back(*bot);

        //if the scores exceed a certain threshold clear its head
        while(scores_buffer.size()>bufferSize)
            scores_buffer.pop_front();

        if(scores_buffer.size()<1)
        {
            mutex.post();
            return;
        }

        int n_classes = scores_buffer.front().size();

        vector<double> class_avg(n_classes,0.0);
        vector<int> class_votes(n_classes,0);

        for(list<Bottle>::iterator score_itr=scores_buffer.begin(); score_itr!=scores_buffer.end(); score_itr++)
        {
            double max_score=-1000.0;
            int max_idx;
            for(int class_idx=0; class_idx<n_classes; class_idx++)
            {
                double s=score_itr->get(class_idx).asList()->get(1).asDouble();
                class_avg[class_idx]+=s;
                if(s>max_score)
                {
                    max_score=s;
                    max_idx=class_idx;
                }
            }

            class_votes[max_idx]++;
        }

        double max_avg=-10000.0;
        double max_votes=-10000.0;
        int max_avg_idx;
        int max_votes_idx;
        int max_votes_sum=0;

        for(int class_idx=0; class_idx<n_classes; class_idx++)
        {
            class_avg[class_idx]=class_avg[class_idx]/n_classes;
            if(class_avg[class_idx]>max_avg)
            {
                max_avg=class_avg[class_idx];
                max_avg_idx=class_idx;
            }

            if(class_votes[class_idx]>max_votes)
            {
                max_votes=class_votes[class_idx];
                max_votes_idx=class_idx;
            }
            
            max_votes_sum+=class_votes[class_idx];
        }

        current_class=scores_buffer.front().get(max_avg_idx).asList()->get(0).asString().c_str();
        if(max_votes/scores_buffer.size()<0.2)
            current_class="?";

        cout << "Scores: " << endl;
        for (int i=0; i<n_classes; i++)
            cout << "[" << scores_buffer.front().get(i).asList()->get(0).asString().c_str() << "]: " << class_avg[i] << " "<< class_votes[i] << endl;
        cout << endl << endl;

        //plot confidence values
        if(port_out_confidence.getOutputCount()>0)
        {
            ImageOf<PixelRgb> img_conf;
            img_conf.resize(confidence_width,confidence_height);
            cvZero(img_conf.getIplImage());
            int max_height=(int)img_conf.height()*0.8;
            int min_height=img_conf.height()-20;

            int width_step=(int)img_conf.width()/n_classes;

            for(int class_idx=0; class_idx<n_classes; class_idx++)
            {
                int class_height=img_conf.height()-((int)max_height*class_votes[class_idx]/max_votes_sum);
                if(class_height>min_height)
                    class_height=min_height;

                cvRectangle(img_conf.getIplImage(),cvPoint(class_idx*width_step,class_height),cvPoint((class_idx+1)*width_step,min_height),cvScalar(155,155,255),CV_FILLED);
                cvRectangle(img_conf.getIplImage(),cvPoint(class_idx*width_step,class_height),cvPoint((class_idx+1)*width_step,min_height),cvScalar(0,0,255),3);
                
                CvFont font;
                cvInitFont(&font,CV_FONT_HERSHEY_SIMPLEX,0.6,0.6,0,2);
                
                cvPutText(img_conf.getIplImage(),scores_buffer.front().get(class_idx).asList()->get(0).asString().c_str(),cvPoint(class_idx*width_step,img_conf.height()-5),&font,cvScalar(255,255,255));
            }

            port_out_confidence.write(img_conf);
        }

        mutex.post();
    }


    bool StorerThread::set_current_class(string _current_class)
    {
        mutex.wait();
        current_class=_current_class;
        mutex.post();

        return true;
    }
    bool StorerThread::get_current_class(string &_current_class)
    {
        mutex.wait();
        _current_class=current_class;
        mutex.post();

        return true;
    }

    bool StorerThread::reset_scores()
    {
        mutex.wait();
        scores_buffer.clear();
        mutex.post();

        return true;
    }

    bool StorerThread::set_mode(int _mode)
    {
        mutex.wait();
        mode=_mode;
        mutex.post();
            
        return true;
    }
    
    bool StorerThread::set_state(int _state)
    {
        mutex.wait();
        state=_state;
        mutex.post();
            
        return true;
    }

    bool StorerThread::execReq(const Bottle &command, Bottle &reply)
    {
        switch(command.get(0).asVocab())
        {
            default:
                return false;
        }
    }

    void StorerThread::interrupt()
    {
        mutex.wait();
        port_in_scores.interrupt();
        port_out_confidence.interrupt();
        mutex.post();
        cout << "returning storer thread interrupt..." << endl;
    }

    void StorerThread::threadRelease()
    {
        mutex.wait();
        port_in_scores.close();
        port_out_confidence.close();
        mutex.post();

        cout << "returning storer thread release..." << endl;
    }