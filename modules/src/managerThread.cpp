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

#include <managerThread.h>

using namespace std;
using namespace yarp;
using namespace yarp::os;
using namespace yarp::sig;
using namespace yarp::math;

void ManagerThread::set_state(int _state)
{
	state =_state;
	thr_transformer->set_state(state);

}

void ManagerThread::set_mode(int _mode)
{

	mode_human = _mode;
	thr_transformer->set_mode(_mode);
}


bool ManagerThread::speak(string speech)
{
	if(port_out_speech.getOutputCount()>0)
	{
		Bottle b;
		b.addString(speech.c_str());
		port_out_speech.write(b);
		return true;
	}
	return false;

}

bool ManagerThread::observe_robot()
{
	//check if the robot is already holding an object
	Bottle command,reply;

	command.addString("get");
	command.addString("hold");
	port_rpc_are_get.write(command,reply);

	if(reply.size()==0)
		return false;

	//if the robot is not holding an object then ask the human to give one
	if(reply.get(0).asVocab()!=ACK)
	{
		reply.clear();
		command.clear();

		command.addString("expect");
		command.addString("near");
		command.addString("no_sacc");
		port_rpc_are_cmd.write(command,reply);

		if(reply.size()==0 || reply.get(0).asVocab()!=ACK)
			return false;
	}

	speak("*************************** Image acquisition started ***************************");

	//resume feature storing
	thr_transformer->resumeCoding();

	//perform the exploration of the hand
	reply.clear();
	command.clear();

	command.addString("explore");
	command.addString("hand");
	command.addString("no_sacc");
	port_rpc_are_cmd.write(command,reply);

	//interrupt feature storing
	thr_transformer->interruptCoding();

	speak("*************************** Image acquisition done ******************************");

	//just drop the object
	reply.clear();
	command.clear();

	command.addString("give");
	port_rpc_are_cmd.write(command,reply);
	if(reply.size()>0 && reply.get(0).asVocab()==ACK)
	{
		speak("Object given.");
	}
	else
	{
		speak("Cannot set ARE to 'give'.");
		return false;
	}

	command.clear();
	reply.clear();

	command.addString("home");
	port_rpc_are_cmd.write(command,reply);
	if(reply.size()>0 && reply.get(0).asVocab()==ACK)
	{
		speak("Home position reached.");
	}
	else
	{
		speak("Cannot set ARE to 'home'.");
		return false;
	}

	return true;
}

bool ManagerThread::observe_human(double period, string nuisance)
{

	Bottle cmd_are,reply_are;

	cmd_are.addString("idle");
	port_rpc_are_cmd.write(cmd_are,reply_are);

	if(reply_are.size()>0 && reply_are.get(0).asVocab()==ACK)
	{
		reply_are.clear();
		cmd_are.clear();

		cmd_are.addString("track");
		cmd_are.addString("motion");
		cmd_are.addString("no_sacc");
		port_rpc_are_cmd.write(cmd_are,reply_are);

		if(reply_are.size()>0 && reply_are.get(0).asVocab()==ACK)
		{
			speak("Begin tracking mode.");
		}
		else
		{
			speak("Cannot set ARE to 'track motion no_sacc'.");
			return false;
		}
	}
	else
	{
		speak("Cannot set ARE to 'idle'.");
		return false;
	}

	speak("I'm waiting for you to position...");

	Time::delay(single_operator_time);

	speak("*************************** Image acquisition started:" + nuisance);

	thr_transformer->resumeCoding();
	Time::delay(period);
	thr_transformer->interruptCoding();

	speak("*************************** Image acquisition done:" + nuisance);

	reply_are.clear();
	cmd_are.clear();

	cmd_are.addString("idle");
	port_rpc_are_cmd.write(cmd_are,reply_are);

	if(reply_are.size()>0 && reply_are.get(0).asVocab()==ACK)
	{
		speak("End tracking mode.");

		reply_are.clear();
		cmd_are.clear();

		cmd_are.addString("home");
		port_rpc_are_cmd.write(cmd_are,reply_are);

		if(reply_are.size()>0 && reply_are.get(0).asVocab()==ACK)
		{
			speak("Home position reached.");
		}
		else
		{
			speak("Cannot set ARE to 'home'.");
			return false;
		}
	}
	else
	{
		speak("Cannot set ARE to 'idle'.");
		return false;
	}

	return true;

}

bool ManagerThread::observe()
{

	bool ok = false;

	if (mode_human)
	{
		string nuisance;
		string classname = thr_transformer->get_class();

		nuisance = "TRANSL";
		thr_transformer->set_class(classname + "_" + nuisance);
		ok = observe_human(observe_time_transl, nuisance);


		nuisance = "SCALE";
		thr_transformer->set_class(classname + "_" + nuisance);
		ok = observe_human(observe_time_scaling, nuisance);

		nuisance = "SCALE_TR";
		thr_transformer->set_class(classname + "_" + nuisance);
		ok = observe_human(observe_time_scaling_tr, nuisance);


		nuisance = "2DROT";
		thr_transformer->set_class(classname + "_" + nuisance);
		ok = observe_human(observe_time_2drot, nuisance);

		nuisance = "2DROT_TR";
		thr_transformer->set_class(classname + "_" + nuisance);
		ok = observe_human(observe_time_2drot_tr, nuisance);

		nuisance = "3DROT";
		thr_transformer->set_class(classname + "_" + nuisance);
		ok = observe_human(observe_time_3drot, nuisance);

		thr_transformer->set_class(classname + "_" + nuisance);
		nuisance = "3DROT_TR";
		ok = observe_human(observe_time_3drot_tr, nuisance);
	}
	else
		ok = observe_robot();

	return ok;
}

bool ManagerThread::threadInit()
{

	string name = rf.find("name").asString().c_str();

	observe_time_baseline = rf.check("observe_time_transl", Value(10)).asDouble();;

	observe_time_transl = rf.check("observe_time_transl", Value(observe_time_baseline)).asDouble();
	observe_time_2drot = rf.check("observe_time_2drot", Value(observe_time_baseline/2)).asDouble();
	observe_time_2drot_tr = rf.check("observe_time_2drot_tr", Value(observe_time_baseline)).asDouble();
	observe_time_scaling = rf.check("observe_time_scaling", Value(observe_time_baseline/2)).asDouble();
	observe_time_scaling_tr = rf.check("observe_time_scaling_tr", Value(observe_time_baseline)).asDouble();
	observe_time_3drot = rf.check("observe_time_3drot", Value(observe_time_baseline)).asDouble();
	observe_time_3drot_tr = rf.check("observe_time_3drot_tr", Value(observe_time_baseline)).asDouble();

	single_operator_time = rf.check("single_operator_time",Value(5.0)).asDouble();

	thr_transformer=new TransformerThread(rf);
	thr_transformer->start();

	//rpc
	port_rpc_are_get.open(("/"+name+"/are/get:io").c_str());
	port_rpc_are_cmd.open(("/"+name+"/are/cmd:io").c_str());

	//speech
	port_out_speech.open(("/"+name+"/speech:o").c_str());

	thr_transformer->interruptCoding();

	set_state(STATE_IDLE);
	set_mode(MODE_HUMAN);

	curr_time=Time::now();
	reset_label_time=5.0;

	return true;
}

void ManagerThread::run()
{
	if(Time::now()-curr_time > reset_label_time)
	{
		thr_transformer->set_class("?");
		curr_time = Time::now();
	}

	if(state == STATE_IDLE)
		return;

	mutex.wait();

	if (state == STATE_OBSERVING)
	{
		observe();

		set_state(STATE_IDLE);
	}

	mutex.post();
}

bool ManagerThread::execReq(const Bottle &command, Bottle &reply)
{
	switch(command.get(0).asVocab())
	{
	default:
		return false;
	}
}

bool ManagerThread::execHumanCmd(Bottle &command, Bottle &reply)
{
	switch(command.get(0).asVocab())
	{
	case CMD_IDLE:
	{
		mutex.wait();

		set_state(STATE_IDLE);

		thr_transformer->set_class("?");

		reply.addVocab(ACK);

		mutex.post();

		break;
	}

	case CMD_OBSERVE:
	{
		mutex.wait();

		if(command.size()>1)
		{
			string class_name = command.get(1).asString().c_str();

			thr_transformer->set_class(class_name);

			set_state(STATE_OBSERVING);

			reply.addString(("Storing " + class_name).c_str());
		}
		else
			reply.addString("Error: need to specify a class!");

		mutex.post();

		break;
	}

	case CMD_ROBOT:
	{
		mutex.wait();

		Bottle cmd_are,reply_are;

		cmd_are.addString("idle");
		port_rpc_are_cmd.write(cmd_are,reply_are);

		if(reply_are.size()>0 && reply_are.get(0).asVocab()==ACK)
		{
			reply_are.clear();
			cmd_are.clear();

			cmd_are.addString("home");
			port_rpc_are_cmd.write(cmd_are,reply_are);

			if(reply_are.size()>0 && reply_are.get(0).asVocab()==ACK)
			{
				set_mode(MODE_ROBOT);
				reply.addVocab(ACK);
			}
			else
				reply.addString("Error: cannot give ARE 'home' command.");
		}
		else
			reply.addString("Error: cannot set ARE to 'idle'.");

		mutex.post();
		break;
	}

	case CMD_HUMAN:
	{
		mutex.wait();

		Bottle cmd_are,reply_are;

		cmd_are.addString("idle");
		port_rpc_are_cmd.write(cmd_are,reply_are);

		if(reply_are.size()>0 && reply_are.get(0).asVocab()==ACK)
		{
			set_mode(MODE_HUMAN);
			reply.addVocab(ACK);
		}
		else
			reply.addString("Error: cannot set ARE to 'idle'.");

		mutex.post();
		break;
	}

	}

	return true;
}

void ManagerThread::interrupt()
{
	mutex.wait();

	port_rpc_are_cmd.interrupt();
	port_rpc_are_cmd.interrupt();

	port_out_speech.interrupt();

	thr_transformer->interrupt();

	mutex.post();

}

void ManagerThread::threadRelease()
{
	mutex.wait();

	port_rpc_are_cmd.close();
	port_rpc_are_cmd.close();

	port_out_speech.close();

	thr_transformer->stop();
	delete thr_transformer;

	mutex.post();

}

bool ManagerModule::configure(ResourceFinder &rf)
{
	string name = rf.find("name").asString().c_str();

	Time::turboBoost();

	manager_thr = new ManagerThread(rf);
	manager_thr->start();

	port_rpc_human.open(("/"+name+"/human:io").c_str());

	port_rpc.open(("/"+name+"/rpc").c_str());
	attach(port_rpc);

	return true;
}

bool ManagerModule::interruptModule()
{
	port_rpc_human.interrupt();
	port_rpc.interrupt();

	manager_thr->interrupt();

	return true;
}

bool ManagerModule::close()
{
	manager_thr->stop();
	delete manager_thr;

	port_rpc_human.close();
	port_rpc.close();

	return true;
}

bool ManagerModule::respond(const Bottle &command, Bottle &reply)
{
	if(manager_thr->execReq(command,reply))
		return true;
	else
		return RFModule::respond(command,reply);
}

double ManagerModule::getPeriod()    { return 1.0;  }

bool ManagerModule::updateModule()
{
	Bottle human_cmd,reply;

	port_rpc_human.read(human_cmd,true);
	if(human_cmd.size()>0)
	{
		manager_thr->execHumanCmd(human_cmd,reply);
		port_rpc_human.reply(reply);
	}

	return true;
}

