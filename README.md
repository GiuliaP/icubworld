# icubworld

Demo to collect an annotated dataset of images by recording from the iCub cameras while the robot is focusing on objects shown by a human teacher.

The dataset can be used to train or benchmark visual recognition systems offline on the iCub's visual experience.

## Example setup 

An example acquisition setup is the following:

1.	a (human) teacher stands in front of the robot, helding the object that he wants to acquire
2.	the teacher says the name of the object (or type it) and starts showing it to the robot
3.	the robot start focusing on the object and keeps on tracking it for a fixed arbitrary time period, during which the stream of frames coming from the left and right cameras is recorded (together with the detected ROI around the object for each frame) and associated with the object label specified by the operator
4.	the procedure can be repeated for as many objects as desired

This setup can be customized in different ways, explained in the following.

## Tracking 

The tracking cue that keeps the iCub fixating the object can be either the motion of the object, if the operator moves it continuously, or depth. The latter can be useful because it allows the human to keep the object almost still or move it slowly, in a very natural way, because it exploits the assumption that, in this setting, the object of interest is almost surely the closest to the robot in the visual field. 

To use the motion cue, you can use the `icubworld_motion.xml` application.
To use the disparity cue, you can use the `icubworld_depth.xml application.

## Trade-off between resolution of acquired images and real-time tracking

Tracking the object by exploiting motion or disparity cues is a task for which we don't need fine details in the frames, but rather real-time performance, in order to obtain a stable fixation. On the other hand, we prefer recording better resolved images for the object recognition dataset. To this end, we perform the tracking by lowering the resolution of the frames to 320x240, while acquiring at the same time full-res 640x480 frames. This is done using the `cameras_calib_bayer_640_480_and_320_240.xml`application file provided.

## Acquiring different modalities

We provide also for convenience the possibility of acquiring more videos for the same object one after the other. This can be useful for instance to record videos of the object in different conditions or undergoing different transformations. In this case, the operator provides the label of the object once at the beginning and then starts the acquisitions for that object, looking at the visual output of the demo to know when the subsequent video recordings are starting/stopping. The labels for the different modalities are customizable as well as the time and delays for the different video recordings.




