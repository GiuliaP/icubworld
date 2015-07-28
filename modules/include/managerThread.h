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

#ifndef DEFINITIONS

#define                 ACK                 VOCAB3('a','c','k')
#define                 NACK                VOCAB4('n','a','c','k')

#define                 STATE_IDLE          0
#define                 STATE_OBSERVING     1

#define					MODE_HUMAN			1
#define					MODE_ROBOT			0

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

#include <transformerThread.h>

using namespace std;
using namespace yarp;
using namespace yarp::os;
using namespace yarp::sig;
using namespace yarp::math;

class ManagerThread: public RateThread
{
private:

	ResourceFinder                      &rf;

	Semaphore                           mutex;

	TransformerThread                   *thr_transformer;

	//rpc are
	RpcClient                           port_rpc_are_get;
	RpcClient                           port_rpc_are_cmd;

	//rpc human
	RpcClient                           port_rpc_human;

	//output
	Port                                port_out_speech;

	double								observe_time_baseline;
	double								observe_time_transl;
	double                              observe_time_scaling;
	double								observe_time_2drot;
	double								observe_time_3drot;
	double								observe_time_scaling_tr;
	double								observe_time_2drot_tr;
	double								observe_time_3drot_tr;

	double                              single_operator_time;

	bool                                mode_human;
	int                                 state;
	bool								tracking;

	double                              reset_label_time;
	double                              curr_time;

private:

	void set_state(int _state);

	void set_mode(int _mode);

	bool speak(string speech);

	bool observe_robot();

	bool observe_human(double period, string classname, string nuisance);

	bool observe();

public:
	ManagerThread(ResourceFinder &_rf) : RateThread(10), rf(_rf) { }

	bool threadInit();

	void run();

	bool execReq(const Bottle &command, Bottle &reply);

	bool execHumanCmd(Bottle &command, Bottle &reply);

	void interrupt();

	void threadRelease();

};


class ManagerModule: public RFModule
{
protected:
	ManagerThread       *manager_thr;
	RpcServer           port_rpc_human;
	Port                port_rpc;

public:

	bool configure(ResourceFinder &rf);

	bool interruptModule();

	bool close();

	bool respond(const Bottle &command, Bottle &reply);

	double getPeriod();

	bool updateModule();

};

