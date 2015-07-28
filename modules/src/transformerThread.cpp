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

#include <transformerThread.h>

using namespace std;
using namespace yarp;
using namespace yarp::os;
using namespace yarp::sig;
using namespace yarp::math;

bool TransformerThread::threadInit()
{
	string name=rf.find("name").asString().c_str();

	radius_crop_robot = rf.check("radius_crop_robot",Value(128)).asInt();
	radius_crop_human = rf.check("radius_crop_human",Value(128)).asInt();

	acquire_disp_roi = rf.check("acquire_disp_roi");
	acquire_also_right = rf.check("acquire_also_right");

	radius_crop = radius_crop_human;

	//input
	port_in_img.open(("/"+name+"/img:i").c_str());
	port_in_blobs.open(("/"+name+"/blobs:i").c_str());
	port_in_roi.open(("/"+name+"/roi:i").c_str());

	port_in_img_right.open(("/"+name+"/img/right:i").c_str());
	port_in_blobs_right.open(("/"+name+"/blobs/right:i").c_str());
	port_in_roi_right.open(("/"+name+"/roi/right:i").c_str());

	//output
	port_out_show.open(("/"+name+"/show:o").c_str());
	port_out_show_right.open(("/"+name+"/show/right:o").c_str());

	port_out_crop.open(("/"+name+"/crop:o").c_str());

	port_out_img.open(("/"+name+"/img:o").c_str());
	port_out_imginfo.open(("/"+name+"/imginfo:o").c_str());

	port_out_img_right.open(("/"+name+"/img/right:o").c_str());
	port_out_imginfo_right.open(("/"+name+"/imginfo/right:o").c_str());


	// rpc
	port_rpc_are_get_hand.open(("/"+name+"/are/hand:io").c_str());

	class_name = "?";

	coding_interrupted=true;

	blink_init_time = Time::now();
	blink_visible_time = 0.5;
	blink_invisible_time = 0.0;

	return true;
}

void TransformerThread::run()
{
	mutex.wait();

	Image *img, *img_right;
	Stamp stamp, stamp_right;

	Stamp stamp_b, stamp_b_right;
	Stamp stamp_roi, stamp_roi_right;

	img = port_in_img.read(false);
	if(img == NULL)
	{
		mutex.post();
		return;
	}
	port_in_img.getEnvelope(stamp);

	if (acquire_also_right)
	{
		img_right = port_in_img_right.read(false);
		if(img_right == NULL)
		{
			mutex.post();
			return;
		}
		port_in_img_right.getEnvelope(stamp_right);
	}

	bool found = false, found_right = false;
	int x, y, x_right, y_right;
	int pixelCount = 0;
	int tlx, tly, brx, bry, tlx_right, tly_right, brx_right, bry_right;
	cv::Rect imgRoi, imgRoi_right;

	if (mode == MODE_HUMAN)
	{
		Bottle *blobs, *blobs_right;

		blobs = port_in_blobs.read(false);
		port_in_blobs.getEnvelope(stamp_b);
		if (blobs != NULL)
		{
			Bottle *window = blobs->get(0).asList();
			x = window->get(0).asInt();
			y = window->get(1).asInt();
			pixelCount = window->get(2).asInt();

			if (img->width()==640)
			{
				x *= 2;
				y *= 2;
				pixelCount *= 4;
			}

			radius_crop = radius_crop_human;

			found = true;
		}

		if (acquire_also_right)
		{
			blobs_right = port_in_blobs_right.read(false);
			port_in_blobs_right.getEnvelope(stamp_b_right);
			if (blobs_right != NULL)
			{
				Bottle *window = blobs_right->get(0).asList();
				x_right = window->get(0).asInt();
				y_right = window->get(1).asInt();

				if (img_right->width()==640)
				{
					x_right *= 2;
					y_right *= 2;
				}

				found_right = true;
			}
		}

		if (acquire_disp_roi)
		{
			Bottle *roi, *roi_right;

			roi = port_in_roi.read(false);
			port_in_roi.getEnvelope(stamp_roi);
			if (roi!=NULL)
			{
				Bottle *window = roi->get(0).asList();
				tlx = window->get(0).asInt();
				tly = window->get(1).asInt();
				brx = window->get(2).asInt();
				bry = window->get(3).asInt();

				if (img->width()==640)
				{
					tlx *= 2;
					tly *= 2;
					brx *= 2;
					bry *= 2;
				}

				imgRoi = cv::Rect (cv::Point( tlx, tly ), cv::Point( brx, bry ));
			}

			if (acquire_also_right)
			{
				roi_right = port_in_roi_right.read(false);
				port_in_roi_right.getEnvelope(stamp_roi_right);
				if (roi_right!=NULL)
				{
					Bottle *window = roi_right->get(0).asList();
					tlx_right = window->get(0).asInt();
					tly_right = window->get(1).asInt();
					brx_right = window->get(2).asInt();
					bry_right = window->get(3).asInt();

					if (img_right->width()==640)
					{
						tlx_right *= 2;
						tly_right *= 2;
						brx_right *= 2;
						bry_right *= 2;
					}

					imgRoi_right = cv::Rect (cv::Point( tlx_right, tly_right ), cv::Point( brx_right, bry_right ));
				}
			}
		} else
		{
			int radius = std::min(radius_crop,x);
			radius = std::min(radius,y);
			radius = std::min(radius,img->width()-x-1);
			radius = std::min(radius,img->height()-y-1);

			if(radius>10)
			{
				int radius2 = radius<<1;

				tlx = x-radius;
				tly = y-radius;
				imgRoi = cv::Rect (tlx, tly, radius2, radius2);
			}

			if (acquire_also_right)
			{
				int radius_right = std::min(radius_crop,x_right);
				radius_right = std::min(radius_right,y_right);
				radius_right = std::min(radius_right,img_right->width()-x_right-1);
				radius_right = std::min(radius_right,img_right->height()-y_right-1);

				if(radius_right>10)
				{

					int radius2_right = radius_right<<1;

					tlx_right = x_right-radius_right;
					tly_right = y_right-radius_right;
					imgRoi_right = cv::Rect (tlx_right, tly_right, radius2_right, radius2_right);
				}
			}

		}
	}

	if (mode == MODE_ROBOT)
	{
		Bottle cmd_are_hand, reply_are_hand;

		cmd_are_hand.addString("get");
		cmd_are_hand.addString("hand");
		cmd_are_hand.addString("image");
		port_rpc_are_get_hand.write(cmd_are_hand,reply_are_hand);

		if(reply_are_hand.size()>0 && reply_are_hand.get(0).asVocab()!=NACK)
		{
			x = reply_are_hand.get(2).asInt();
			y = reply_are_hand.get(3).asInt();

			if (img->width()==640)
			{
				x *= 2;
				y *= 2;
			}

			pixelCount = -1;

			radius_crop = radius_crop_robot;

			if (0<x && x<img->width() && 0<y && y<img->height())
			{
				found = true;

				int radius = std::min(radius_crop,x);
				radius = std::min(radius,y);
				radius = std::min(radius,img->width()-x-1);
				radius = std::min(radius,img->height()-y-1);

				if(radius>10)
				{

					int radius2 = radius<<1;

					tlx = x-radius;
					tly = y-radius;
					imgRoi = cv::Rect (tlx, tly, radius2, radius2);

				}
			}
		}
	}

	if(!coding_interrupted)
	{
		if (found)
		{
			if (port_out_crop.getOutputCount()>0)
			{
				img_crop.resize(imgRoi.width,imgRoi.height);
				cv::Mat imgMat = cv::Mat( (IplImage*)img->getIplImage() );
				imgMat(imgRoi).copyTo( cv::Mat( (IplImage*)img_crop.getIplImage() ) );

				port_out_crop.setEnvelope(stamp);
				port_out_crop.write(img_crop);
			}

			if (port_out_img.getOutputCount()>0)
			{
				port_out_img.setEnvelope(stamp);
				port_out_img.write(*img);
			}

			if (port_out_imginfo.getOutputCount()>0)
			{
				Bottle imginfo;
				imginfo.addInt(x);
				imginfo.addInt(y);
				imginfo.addInt(pixelCount);
				if (mode==MODE_HUMAN)
				{
					imginfo.addDouble(stamp_b.getTime());
					if (acquire_disp_roi)
					{
						imginfo.addInt(imgRoi.x);
						imginfo.addInt(imgRoi.y);
						imginfo.addInt(imgRoi.width);
						imginfo.addInt(imgRoi.height);
						imginfo.addDouble(stamp_roi.getTime());
					}
				}
				imginfo.addString(class_name.c_str());

				port_out_imginfo.setEnvelope(stamp);
				port_out_imginfo.write(imginfo);
			}
		}

		if (mode==MODE_HUMAN && acquire_also_right && found_right)
		{
			if (port_out_img_right.getOutputCount()>0)
			{
				port_out_img_right.setEnvelope(stamp_right);
				port_out_img_right.write(*img_right);
			}

			if (port_out_imginfo_right.getOutputCount()>0)
			{
				Bottle imginfo;
				imginfo.addInt(x_right);
				imginfo.addInt(y_right);
				imginfo.addDouble(stamp_b_right.getTime());
				imginfo.addInt(imgRoi_right.x);
				imginfo.addInt(imgRoi_right.y);
				imginfo.addInt(imgRoi_right.width);
				imginfo.addInt(imgRoi_right.height);
				imginfo.addDouble(stamp_roi_right.getTime());
				imginfo.addString(class_name.c_str());

				port_out_imginfo_right.setEnvelope(stamp_right);
				port_out_imginfo_right.write(imginfo);
			}
		}
	}

	cv::Scalar text_color = cv::Scalar(0,0,255);
	string text_string = class_name;

	if (state == STATE_OBSERVING)
	{
		text_color = cv::Scalar(255,0,0);
		text_string = "look: " + class_name;
	}

	if (found && port_out_show.getOutputCount()>0)
	{
		int y_text = imgRoi.tl().y - 10;
		if (y_text<5)
			y_text = imgRoi.br().y + 2;

		cv::Mat imgMat = cv::Mat( (IplImage*)img->getIplImage() );
		cv::rectangle (imgMat, imgRoi, text_color, 2);
		cv::circle(imgMat, cv::Point(x,y), 8,  text_color, -1, 8, 0 );

		cv::putText(imgMat,text_string.c_str(), cv::Point(imgRoi.tl().x,y_text), cv::FONT_HERSHEY_SIMPLEX, 0.8, text_color, 3.0);
		port_out_show.write(*img);
	}

	if (found_right && port_out_show_right.getOutputCount()>0)
	{
		int y_text = imgRoi_right.tl().y - 10;
		if (y_text<5)
			y_text = imgRoi_right.br().y + 2;

		cv::Mat imgMat_right = cv::Mat( (IplImage*)img_right->getIplImage() );
		cv::rectangle (imgMat_right, imgRoi_right, text_color, 2);
		cv::circle(imgMat_right, cv::Point(x_right,y_right), 8,  text_color, -1, 8, 0 );

		cv::putText(imgMat_right,text_string.c_str(), cv::Point(imgRoi_right.tl().x,y_text), cv::FONT_HERSHEY_SIMPLEX, 0.8, text_color, 3.0);
		port_out_show_right.write(*img_right);
	}

	mutex.post();
}

void TransformerThread::set_class(string _class)
{
	class_name = _class;
}

void TransformerThread::set_mode(int _mode)
{
	mutex.wait();
	mode=_mode;
	mutex.post();
}

void TransformerThread::set_state(int _state)
{
	mutex.wait();
	state=_state;
	mutex.post();
}

string TransformerThread::get_class()
{
	return class_name;
}

bool TransformerThread::execReq(const Bottle &command, Bottle &reply)
{
	switch(command.get(0).asVocab())
	{
	default:
		return false;
	}
}

void TransformerThread::interrupt()
{
	mutex.wait();

	port_in_img.interrupt();
	port_in_blobs.interrupt();
	port_in_roi.interrupt();

	port_in_img_right.interrupt();
	port_in_blobs_right.interrupt();
	port_in_roi_right.interrupt();

	port_out_show.interrupt();
	port_out_show_right.interrupt();

	port_out_crop.interrupt();

	port_out_img.interrupt();
	port_out_imginfo.interrupt();

	port_out_img_right.interrupt();
	port_out_imginfo_right.interrupt();

	port_rpc_are_get_hand.interrupt();

	mutex.post();
}

void TransformerThread::threadRelease()
{
	mutex.wait();

	port_in_img.close();
	port_in_blobs.close();
	port_in_roi.close();

	port_in_img_right.close();
	port_in_blobs_right.close();
	port_in_roi_right.close();

	port_out_show.close();
	port_out_show_right.close();

	port_out_crop.close();

	port_out_img.close();
	port_out_imginfo.close();

	port_out_img_right.close();
	port_out_imginfo_right.close();

	port_rpc_are_get_hand.close();

	mutex.post();
}

void TransformerThread::interruptCoding()
{
	coding_interrupted = true;
}

void TransformerThread::resumeCoding()
{
	coding_interrupted = false;
}
