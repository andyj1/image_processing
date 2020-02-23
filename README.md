### Applied Force Task - Heart Rate Reading

> #### Last updated on February 10, 2020

> #### Function: reads heart rates through two devices for three ROIs whenever the subject applies force onto the plate. This is modified from the previous version to take in multiple ROIs from a single video. HR sensor bar readings taken at initial and final times are not to be used as inputs at this point; once enough videos are made available to verify its use, they can be used to determine which HR device is more reliable.

#### Dependencies

> MATLAB Computer Vision Toolbox for OCR, GUIDE tools

#### Usage

> ### Run `build1.m` in MATLAB.

1.  [optional] Set the initial starting time (absolute) at which the experiment started (to indicate in the output), and adjust maximum rep count (for memory storage purposes)
2.  Set the path for output files in CSV format, Load a video to stream
3.  Select first motion ROI and two HR device ROIs
4.  When the location (Floor/Wall/Ceiling) changes, check off `ROI 2` or `ROI 3` above the video to indicate a different ROI
5.  Wait for frames to run, and verify as necessary. The box will turn red (no motion), green (in motion), blue (video finished).

#### Output

- '{video_name}ROI-[1/2/3].csv' containing ITERATIONS / TIME_START / TIME_END / DURATION / HR_MIN1 (Device 1) / HR_MAX1 (Device 1) / HR_AVG1 (Device 1) / HR_MIN2 (Device 2) / HR_MAX2 (Device 2) / HR_AVG2 (Device 2), for each ROI in a CSV formatted document. At the last row, the macro-average values are appended for each ROI, and the filtered HR readings are printed in the command window, as well as saved as `.mat` files for manual verification purposes

#### Constraints/Limitations

- The heart rate measurement readings are filtered so they fall in the range of (50, 200) to account for incorrect readings (can be adjusted).
- The video skips 3 frames at each time of reading for expedited runthrough (can be adjusted).
- Depending on the size of ROI, more precise tuning for the threshold (for motion changes) may be necessary.
