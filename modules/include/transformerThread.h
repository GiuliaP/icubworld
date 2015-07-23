/* 
 * Copyright (C) 2015 iCub Facility - Istituto Italiano di Tecnologia
 * Author: Carlo Ciliberto, Giulia Pasquale
 * email:  carlo.ciliberto@iit.it giulia.pasquale@iit.it
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

#ifndef DEFINITIONS

#define                 ACK                 VOCAB3('a','c','k')
#define                 NACK                VOCAB4('n','a','c','k')

#define                 STATE_IDLE          0
#define                 STATE_OBSERVING     1

#define                 MODE_ROBOT          0
#define                 MODE_HUMAN		    1

#define                 CMD_IDLE            VOCAB4('i','d','l','e')
#define                 CMD_OBSERVE         VOCAB4('o','b','s','e')

#define                 CMD_ROBOT           VOCAB4('r','o','b','o')
#define                 CMD_HUMAN           VOCAB4('h','u','m','a')

#endif

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

#include <opencv/highgui.h>
#include <opencv/cv.h>

#include <stdio.h>
#include <string>
#include <deque>
#include <algorithm>
#include <vector>
#include <iostream>
#include <fstream>
#include <list>

using namespace std;
using namespace yarp;
using namespace yarp::os;
using namespace yarp::sig;
using namespace yarp::math;

class TransformerThread: public RateThread
{
private:

    ResourceFinder                      &rf;

    Semaphore                           mutex;

    //input
    BufferedPort<Image>                 port_in_img;
    BufferedPort<Bottle>                port_in_blobs;

    //output
    Port                                port_out_show;
    Port                                port_out_crop;
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    Port                                port_out_img;
    Port                                port_out_imginfo;
    //////////////////////////////////////////////////////////////////////////////////////////////////////
    //rpc
    RpcClient                           port_rpc_are_get_hand;

    int                                 radius_crop; 
    int                                 radius_crop_robot;
    int                                 radius_crop_human;

    //////////////////////////////////////////////////////////////////////////////////////////////////////
    ImageOf<PixelRgb>                   img_crop;
    //////////////////////////////////////////////////////////////////////////////////////////////////////

    string                              class_name;

    bool                                coding_interrupted;
    int                                 mode;
    int                                 state;
    
    double                              blink_init_time;
    double                              blink_visible_time;
    double                              blink_invisible_time;

public:
    TransformerThread(ResourceFinder &_rf) : RateThread(5), rf(_rf) { }

    bool threadInit();

    void run();
   
    void set_class(string _class);
  
    void set_mode(int _mode);
    
    void set_state(int _state);

    void get_class(string &_current_class);

    bool execReq(const Bottle &command, Bottle &reply);

    void interrupt();

    void threadRelease();

    void interruptCoding();

    void resumeCoding();
    
};
